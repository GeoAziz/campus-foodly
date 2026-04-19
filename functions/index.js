const express = require('express');
const admin = require('firebase-admin');
const { onRequest } = require('firebase-functions/v2/https');

admin.initializeApp();

const app = express();
app.use(express.json());

const mpesaEnv = process.env.MPESA_ENV === 'production' ? 'production' : 'sandbox';
const mpesaBaseUrl =
  mpesaEnv === 'production'
    ? 'https://api.safaricom.co.ke'
    : 'https://sandbox.safaricom.co.ke';

function getRequiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function formatTimestamp(date = new Date()) {
  const pad = (value) => value.toString().padStart(2, '0');
  return [
    date.getFullYear(),
    pad(date.getMonth() + 1),
    pad(date.getDate()),
    pad(date.getHours()),
    pad(date.getMinutes()),
    pad(date.getSeconds()),
  ].join('');
}

async function getMpesaAccessToken() {
  const consumerKey = getRequiredEnv('MPESA_CONSUMER_KEY');
  const consumerSecret = getRequiredEnv('MPESA_CONSUMER_SECRET');

  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');
  const response = await fetch(
    `${mpesaBaseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    {
      method: 'GET',
      headers: {
        Authorization: `Basic ${auth}`,
      },
    },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to fetch M-Pesa access token: ${response.status} ${text}`);
  }

  const json = await response.json();
  return json.access_token;
}

app.post('/mpesa/stkpush', async (req, res) => {
  try {
    const { paymentId, orderId, userId, phoneNumber, amount } = req.body || {};
    if (!paymentId || !orderId || !userId || !phoneNumber || !amount) {
      return res.status(400).json({ ok: false, error: 'Missing required payment fields' });
    }

    const shortcode = getRequiredEnv('MPESA_SHORTCODE');
    const passkey = getRequiredEnv('MPESA_PASSKEY');
    const callbackUrl =
      process.env.MPESA_CALLBACK_URL ||
      `${req.protocol}://${req.get('host')}/mpesa/callback`;
    const timestamp = formatTimestamp();
    const password = Buffer.from(`${shortcode}${passkey}${timestamp}`).toString('base64');

    const accessToken = await getMpesaAccessToken();

    const stkResponse = await fetch(`${mpesaBaseUrl}/mpesa/stkpush/v1/processrequest`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        BusinessShortCode: shortcode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: 'CustomerPayBillOnline',
        Amount: Math.round(Number(amount)),
        PartyA: phoneNumber,
        PartyB: shortcode,
        PhoneNumber: phoneNumber,
        CallBackURL: callbackUrl,
        AccountReference: orderId,
        TransactionDesc: `Order ${orderId}`,
      }),
    });

    const stkData = await stkResponse.json();
    if (!stkResponse.ok || stkData.errorCode) {
      return res.status(502).json({
        ok: false,
        error: 'STK push request failed',
        details: stkData,
      });
    }

    const checkoutRequestId = stkData.CheckoutRequestID || paymentId;
    await admin.firestore().collection('payments').doc(paymentId).set(
      {
        paymentId,
        orderId,
        userId,
        phoneNumber,
        amount: Number(amount),
        provider: 'mpesa',
        checkoutRequestId,
        merchantRequestId: stkData.MerchantRequestID || null,
        status: 'pending',
        handledByServer: true,
        stkPushResponse: stkData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return res.json({
      ok: true,
      paymentId,
      checkoutRequestId,
      status: 'pending',
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: error.message || String(error) });
  }
});

app.post('/mpesa/callback', async (req, res) => {
  const body = req.body || {};
  const checkoutRequestId = body?.Body?.stkCallback?.CheckoutRequestID;
  const resultCode = body?.Body?.stkCallback?.ResultCode;
  const callbackMetadata = body?.Body?.stkCallback?.CallbackMetadata || {};
  const callbackItems = Array.isArray(callbackMetadata?.Item)
    ? callbackMetadata.Item
    : [];
  const callbackValues = Object.fromEntries(
    callbackItems
      .filter((item) => item && item.Name)
      .map((item) => [item.Name, item.Value ?? null]),
  );

  if (!checkoutRequestId) {
    return res.status(400).json({ ok: false, error: 'Missing CheckoutRequestID' });
  }

  const paymentDoc = await admin
    .firestore()
    .collection('payments')
    .where('checkoutRequestId', '==', checkoutRequestId)
    .limit(1)
    .get();

  if (paymentDoc.empty) {
    return res.status(404).json({ ok: false, error: 'Payment not found' });
  }

  const status = Number(resultCode) === 0 ? 'succeeded' : 'failed';
  const paymentRef = paymentDoc.docs[0].ref;
  const paymentData = paymentDoc.docs[0].data() || {};
  await paymentRef.set(
    {
      status,
      callbackPayload: body,
      callbackMetadata,
      callbackValues,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  if (paymentData.orderId) {
    await admin
      .firestore()
      .collection('orders')
      .doc(paymentData.orderId)
      .set(
        {
          paymentStatus: status,
          paymentId: paymentData.paymentId || paymentRef.id,
          status: status === 'succeeded' ? 'paid' : 'payment_failed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  }

  if (status === 'succeeded' && paymentData.userId) {
    try {
      const tokensSnapshot = await admin
        .firestore()
        .collection('users')
        .doc(paymentData.userId)
        .collection('fcmTokens')
        .get();

      const tokens = tokensSnapshot.docs
        .map((doc) => doc.id)
        .filter((token) => typeof token === 'string' && token.length > 0);

      if (tokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: 'Payment received',
            body: `Order ${paymentData.orderId || ''} payment confirmed.`,
          },
          data: {
            paymentId: paymentData.paymentId || '',
            orderId: paymentData.orderId || '',
            status,
          },
        });
      }
    } catch (error) {
      console.error('Unable to send payment notification:', error);
    }
  }

  return res.json({ ok: true });
});

exports.api = onRequest(app);
