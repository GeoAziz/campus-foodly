import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'logger_service.dart';
import 'connectivity_service.dart';
import 'idempotency_service.dart';

// TODO: Import flutter_dotenv when available
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class MpesaService {
  static final MpesaService _instance = MpesaService._internal();

  factory MpesaService() {
    return _instance;
  }

  MpesaService._internal();

  final _logger = LoggerService();
  final _connectivity = ConnectivityService();
  final _idempotency = IdempotencyService();

  String? _cachedToken;
  DateTime? _tokenExpiryTime;
  bool _configLoaded = false;
  bool _configValid = false;

  // Configuration from .env
  late final String _consumerKey;
  late final String _consumerSecret;
  late final String _shortCode;
  late final String _passKey;
  late final String _baseUrl;
  late final String _callbackUrl;

  /// Load and validate configuration from environment
  void _loadConfig() {
    if (_configLoaded) return;

    _consumerKey = const String.fromEnvironment(
      'MPESA_CONSUMER_KEY',
      defaultValue: 'PLACEHOLDER_MPESA_CONSUMER_KEY',
    );
    _consumerSecret = const String.fromEnvironment(
      'MPESA_CONSUMER_SECRET',
      defaultValue: 'PLACEHOLDER_MPESA_CONSUMER_SECRET',
    );
    _shortCode = const String.fromEnvironment(
      'MPESA_SHORTCODE',
      defaultValue: '174379',
    );
    _passKey = const String.fromEnvironment(
      'MPESA_PASSKEY',
      defaultValue: 'PLACEHOLDER_MPESA_PASSKEY',
    );
    _baseUrl = const String.fromEnvironment(
      'MPESA_SANDBOX_URL',
      defaultValue: 'https://sandbox.safaricom.co.ke',
    );
    _callbackUrl = const String.fromEnvironment(
      'MPESA_CALLBACK_URL',
      defaultValue: 'https://your-backend.com/mpesa/callback',
    );

    _configLoaded = true;
    _validateConfig();
  }

  /// Validate that credentials are not placeholders
  void _validateConfig() {
    const placeholders = [
      'PLACEHOLDER_MPESA_CONSUMER_KEY',
      'PLACEHOLDER_MPESA_CONSUMER_SECRET',
      'PLACEHOLDER_MPESA_PASSKEY',
    ];

    final hasPlaceholders = placeholders.any((placeholder) =>
        _consumerKey == placeholder ||
        _consumerSecret == placeholder ||
        _passKey == placeholder);

    if (hasPlaceholders) {
      _logger.e(
        'M-Pesa credentials contain PLACEHOLDER values. '
        'Please set actual credentials in .env.development',
      );
      _configValid = false;
    } else {
      _configValid = true;
      _logger.i('M-Pesa configuration validated successfully');
    }
  }

  /// Check if service is properly configured
  bool get isConfigured => _configValid;

  /// Get OAuth access token from Daraja API
  Future<String> _getAccessToken() async {
    try {
      _loadConfig();

      if (!_configValid) {
        throw MpesaException(
          'M-Pesa service not properly configured. '
          'Please set credentials in .env.development',
        );
      }

      if (!_connectivity.isOnline) {
        throw MpesaException('Device is offline. Cannot fetch M-Pesa token.');
      }

      // Check if we have a valid cached token
      if (_cachedToken != null &&
          _tokenExpiryTime != null &&
          DateTime.now().isBefore(_tokenExpiryTime!)) {
        _logger.d('Using cached M-Pesa token');
        return _cachedToken!;
      }

      final credentials = base64Encode(
        utf8.encode('$_consumerKey:$_consumerSecret'),
      );

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/oauth/v1/generate?grant_type=client_credentials',
        ),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedToken = data['access_token'] as String;
        final expiresIn = int.parse(data['expires_in'] as String? ?? '3599');
        _tokenExpiryTime = DateTime.now().add(Duration(seconds: expiresIn - 60));
        _logger.i('M-Pesa token generated successfully');
        return _cachedToken!;
      } else {
        _logger.e(
          'Failed to get M-Pesa token: ${response.statusCode} ${response.body}',
        );
        throw MpesaException('Failed to generate M-Pesa token: ${response.body}');
      }
    } on MpesaException {
      rethrow;
    } catch (e) {
      _logger.e('Error getting M-Pesa token: $e');
      throw MpesaException('Unexpected error fetching M-Pesa token: $e');
    }
  }

  /// Initiate STK Push for payment with idempotency protection
  Future<String> initiateStkPush({
    required String phone,
    required int amount,
    required String orderId,
    String? accountReference,
    String? description,
    String? idempotencyKey,
  }) async {
    try {
      _loadConfig();

      if (!_connectivity.isOnline) {
        throw MpesaException('Device is offline. Cannot initiate payment.');
      }

      // Generate or use provided idempotency key
      String key = idempotencyKey ?? _idempotency.generateKey();

      // Check if this request has already been processed
      if (_idempotency.isKeyValid(key)) {
        throw MpesaException(
          'This payment request was already processed. '
          'Please try again with a new request.',
        );
      }

      final token = await _getAccessToken();
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final password = base64Encode(
        utf8.encode('$_shortCode$_passKey$timestamp'),
      );

      final body = {
        'BusinessShortCode': _shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount,
        'PartyA': phone,
        'PartyB': _shortCode,
        'PhoneNumber': phone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference ?? 'Order-$orderId',
        'TransactionDesc': description ?? 'Campus Foodly Order',
      };

      _logger.i(
        'Initiating STK Push for order: $orderId, amount: $amount, key: $key',
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutRequestId = data['CheckoutRequestID'] as String?;

        if (checkoutRequestId != null) {
          // Store idempotency key for this request
          await _idempotency.storeKey(key);
          _logger.i('STK Push initiated: $checkoutRequestId');
          return checkoutRequestId;
        } else {
          _logger.e('No CheckoutRequestID in response: ${response.body}');
          throw MpesaException('No CheckoutRequestID received from M-Pesa');
        }
      } else {
        _logger.e(
          'STK Push initiation failed: ${response.statusCode} ${response.body}',
        );
        throw MpesaException(
          'STK Push initiation failed: ${response.statusCode}',
        );
      }
    } on MpesaException {
      rethrow;
    } catch (e) {
      _logger.e('Error initiating STK Push: $e');
      throw MpesaException('Unexpected error initiating payment: $e');
    }
  }

  /// Query payment status
  Future<MpesaPaymentStatus> queryPaymentStatus({
    required String checkoutRequestId,
  }) async {
    try {
      _loadConfig();

      if (!_connectivity.isOnline) {
        throw MpesaException('Device is offline. Cannot query payment status.');
      }

      final token = await _getAccessToken();
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final password = base64Encode(
        utf8.encode('$_shortCode$_passKey$timestamp'),
      );

      final body = {
        'BusinessShortCode': _shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseCode = data['ResponseCode'] as String?;

        // 0 = Success, 1032 = Request timeout
        if (responseCode == '0') {
          return MpesaPaymentStatus(
            isSuccessful: true,
            checkoutRequestId: checkoutRequestId,
            responseCode: responseCode,
            responseMessage: data['ResponseDescription'] as String?,
          );
        } else if (responseCode == '1032') {
          return MpesaPaymentStatus(
            isSuccessful: false,
            checkoutRequestId: checkoutRequestId,
            responseCode: responseCode,
            responseMessage: 'Payment processing...',
            isPending: true,
          );
        } else {
          return MpesaPaymentStatus(
            isSuccessful: false,
            checkoutRequestId: checkoutRequestId,
            responseCode: responseCode,
            responseMessage: data['ResponseDescription'] as String?,
          );
        }
      } else {
        _logger.e('Payment query failed: ${response.statusCode} ${response.body}');
        throw MpesaException(
          'Payment query failed: ${response.statusCode}',
        );
      }
    } on MpesaException {
      rethrow;
    } catch (e) {
      _logger.e('Error querying payment status: $e');
      throw MpesaException('Unexpected error querying payment: $e');
    }
  }

  /// Poll for payment status with timeout
  /// Returns status or throws MpesaException on persistent errors
  Future<MpesaPaymentStatus> pollPaymentStatus({
    required String checkoutRequestId,
    int pollingIntervalSeconds = 3,
    int maxAttempts = 10,
    void Function(int attemptNumber, int maxAttempts)? onAttempt,
    void Function(String error)? onError,
  }) async {
    int attempts = 0;
    String lastError = '';

    while (attempts < maxAttempts) {
      try {
        onAttempt?.call(attempts + 1, maxAttempts);

        final status = await queryPaymentStatus(
          checkoutRequestId: checkoutRequestId,
        );

        if (status.isSuccessful || !status.isPending) {
          return status;
        }

        attempts++;
        if (attempts < maxAttempts) {
          _logger.d(
            'Payment still processing... ($attempts/$maxAttempts) '
            'Retrying in $pollingIntervalSeconds s',
          );
          await Future.delayed(Duration(seconds: pollingIntervalSeconds));
        }
      } catch (e) {
        lastError = e.toString();
        _logger.e('Error in polling attempt $attempts: $e');
        onError?.call(lastError);

        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: pollingIntervalSeconds));
        } else {
          // Max attempts reached with errors
          throw MpesaException(
            'Failed to confirm payment after $maxAttempts attempts. '
            'Last error: $lastError',
          );
        }
      }
    }

    // Timeout - return pending status so UI can handle appropriately
    return MpesaPaymentStatus(
      isSuccessful: false,
      checkoutRequestId: checkoutRequestId,
      responseCode: '1032',
      responseMessage: 'Payment confirmation timeout. Please verify with support.',
      isTimeout: true,
    );
  }
}

/// M-Pesa payment status
class MpesaPaymentStatus {
  const MpesaPaymentStatus({
    required this.isSuccessful,
    required this.checkoutRequestId,
    this.responseCode,
    this.responseMessage,
    this.isPending = false,
    this.isTimeout = false,
  });

  final bool isSuccessful;
  final String checkoutRequestId;
  final String? responseCode;
  final String? responseMessage;
  final bool isPending;
  final bool isTimeout;

  @override
  String toString() =>
      'MpesaPaymentStatus(successful: $isSuccessful, code: $responseCode, message: $responseMessage)';
}

/// Exception for M-Pesa operations
class MpesaException implements Exception {
  MpesaException(this.message);
  final String message;

  @override
  String toString() => message;
}
