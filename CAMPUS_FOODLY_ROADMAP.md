# 🍔 Campus Foodly — Product Roadmap & Reference Guide
> **Version:** 1.0 | **Last Updated:** April 2026  
> **Product:** Campus Food Delivery App — Thika Road Corridor, Nairobi  
> **Base Repo:** [abuanwar072/foodly_ui](https://github.com/abuanwar072/foodly_ui) (Flutter UI Kit)  
> **Stack:** Flutter · Firebase (Spark Plan) · Daraja API (M-Pesa) · Africa's Talking · Claude AI  

---

## 📋 Table of Contents

1. [Product Vision](#1-product-vision)
2. [Target Market](#2-target-market)
3. [Campus Expansion Strategy](#3-campus-expansion-strategy)
4. [Base Repository Audit](#4-base-repository-audit)
5. [Technical Architecture](#5-technical-architecture)
6. [Firebase Spark Plan — Capabilities & Limits](#6-firebase-spark-plan--capabilities--limits)
7. [Flutter Dependencies & Packages](#7-flutter-dependencies--packages)
8. [Project Folder Structure](#8-project-folder-structure)
9. [Supabase → Firebase Migration Map](#9-firebase-data-schema)
10. [Feature Buildout — Screen by Screen](#10-feature-buildout--screen-by-screen)
11. [M-Pesa Payment Integration](#11-m-pesa-payment-integration)
12. [Automation & AI Layer](#12-automation--ai-layer)
13. [WhatsApp Rider Bot](#13-whatsapp-rider-bot)
14. [Vendor Dashboard](#14-vendor-dashboard)
15. [Build Timeline — 8 Weeks to Launch](#15-build-timeline--8-weeks-to-launch)
16. [Monetization Model](#16-monetization-model)
17. [MVP Launch Checklist](#17-mvp-launch-checklist)

---

## 1. Product Vision

**Mission:** Build the fastest, most reliable food delivery experience for university students along Nairobi's Thika Road corridor — powered by automation, running lean with a solo founder + AI operations team.

**Core Differentiator:**
- Every competitor uses human ops teams. We use AI agents and automation to run what normally takes 5 people.
- Campus-first focus: hyper-local, short delivery radius (< 1km), 10–15 minute delivery times.
- M-Pesa first, app-native, WhatsApp-integrated.

**Target Launch:** KCA University (Phase 1, Week 8)

---

## 2. Target Market

### Primary Customer
- University students aged 18–26
- Located on or near campuses along Thika Road
- App-native, M-Pesa users, WhatsApp-first communication
- Order frequency: 1–3 times/day (breakfast, lunch, dinner)
- Average order value: KES 200–500

### Primary Vendor
- Food kiosks, mama mbogas, and small restaurants within 500m of campus gates
- No digital presence currently
- Need simple dashboard — WhatsApp preferred for notifications

---

## 3. Campus Expansion Strategy

### Phase 1 — Prove the Model (Month 1–2)
**Target: KCA University**
- Closest to CBD, tech-savvy student base
- Compact campus = fast delivery times achievable
- Long operating hours (students until 8:30 PM)
- Goal: 5 vendors, 50 orders/day, consistent < 15 min delivery

### Phase 2 — Scale the Corridor (Month 3–4)
**Target: USIU-Africa + PAC University**
- USIU students have higher disposable income
- PAC University is adjacent — shared vendor network
- Qwetu Student Residences (Ruaraka) serves both — late-night orders
- Goal: 10 vendors, 200 orders/day across 3 campuses

### Phase 3 — Volume Play (Month 5–6)
**Target: Kenyatta University Main Campus**
- 60,000+ students — this is where startup becomes business
- Requires brand recognition from Phase 1 & 2
- May require hiring 1 part-time ops coordinator
- Goal: 20+ vendors, 500+ orders/day

### Future Campuses (Thika Road Belt)
- Compaq College (Githurai)
- Gretsa University (Thika Town)
- Mount Kenya University Thika Campus

---

## 4. Base Repository Audit

### What the Foodly UI Kit Provides ✅
| Screen | Status | Notes |
|--------|--------|-------|
| Onboarding (3 screens) | ✅ UI Only | Needs campus selector added |
| Sign In | ✅ UI Only | Needs Firebase Auth wired |
| Sign Up | ✅ UI Only | Needs phone OTP flow |
| Home Feed | ✅ UI Only | Hardcoded mock data |
| Category Browse | ✅ UI Only | Mock categories |
| Restaurant/Vendor Detail | ✅ UI Only | Mock menu items |
| Food Item Detail | ✅ UI Only | Mock data |
| Cart Screen | ✅ UI Only | No state, no logic |
| Checkout Screen | ✅ UI Only | No payment integration |
| Order Tracking | ✅ UI Only | Static — not real-time |
| Profile Screen | ✅ UI Only | No user data |
| Skeleton Loading | ✅ Built-in | Reuse as-is |
| Android/iOS Native Split | ✅ Built-in | Reuse as-is |

### What Is Missing ❌
| Screen / Feature | Priority |
|-----------------|----------|
| Campus selector (onboarding) | 🔴 Critical |
| Phone OTP verification screen | 🔴 Critical |
| Active orders screen (real-time) | 🔴 Critical |
| M-Pesa STK Push payment screen | 🔴 Critical |
| Delivery address / map pin drop | 🔴 Critical |
| Order history screen | 🟡 High |
| Referral / invite screen | 🟡 High |
| Loyalty / rewards screen | 🟡 High |
| Help / dispute screen | 🟡 High |
| Vendor closed state | 🟡 High |
| Notifications screen | 🟠 Medium |
| Rating & review screen | 🟠 Medium |

### Technical Gaps ❌
| Gap | Impact |
|-----|--------|
| No state management | App is completely stateless |
| No routing | No navigation logic exists |
| No backend integration | All data is hardcoded |
| No authentication | No user identity |
| No payment layer | Cannot process orders |
| No real-time updates | Order tracking is fake |
| No push notifications | No way to alert users |
| No image handling | Vendor photos not possible |

---

## 5. Technical Architecture

```
┌─────────────────────────────────────────────────────┐
│                  CUSTOMER APP                        │
│              Flutter (Foodly UI Base)                │
│         Riverpod (State) · go_router (Nav)           │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│               FIREBASE (SPARK PLAN)                  │
│  Authentication │ Firestore │ Storage │ Functions*   │
│  Realtime DB    │ FCM Push  │ Hosting │ Analytics    │
└──┬──────────────┬───────────────────┬───────────────┘
   │              │                   │
┌──▼───┐    ┌────▼────┐        ┌──────▼──────┐
│Daraja│    │Africa's │        │  Claude AI  │
│ API  │    │Talking  │        │  (Support   │
│M-Pesa│    │WhatsApp │        │   Bot)      │
└──────┘    └─────────┘        └─────────────┘

* Firebase Functions requires Blaze plan upgrade for outbound HTTP calls
  (Daraja API, WhatsApp, Claude) — upgrade when revenue starts
```

### Firebase Spark Plan — What Works Free
- Firestore: 1 GiB storage, 50K reads/day, 20K writes/day, 20K deletes/day
- Authentication: Unlimited (phone OTP, Google Sign-In)
- Firebase Storage: 5 GB storage, 1 GB/day download
- FCM (Push Notifications): Unlimited — completely free
- Realtime Database: 1 GB storage, 10 GB/month transfer
- Firebase Hosting: 10 GB storage, 360 MB/day transfer
- Analytics: Unlimited

### Spark Plan Limitations to Plan Around
- **Cloud Functions: NO outbound HTTP** — cannot call Daraja API, WhatsApp, or Claude from Functions on Spark
- **Workaround:** Call Daraja API directly from Flutter app (client-side STK Push initiation)
- **WhatsApp bot:** Use Africa's Talking free tier separately, triggered by Firestore writes via a small free server (Railway, Render free tier)
- **Upgrade trigger:** When revenue exceeds KES 5,000/month → upgrade to Blaze (pay-as-you-go)

---

## 6. Firebase Spark Plan — Capabilities & Limits

### Daily Limits Table
| Service | Free Limit | Notes |
|---------|-----------|-------|
| Firestore reads | 50,000/day | ~1,667 orders with 30 reads/order |
| Firestore writes | 20,000/day | ~2,000 orders with 10 writes/order |
| Firestore storage | 1 GiB | Enough for months of order data |
| Firebase Storage | 5 GB total | Vendor food images |
| Storage downloads | 1 GB/day | ~500 menu views with 2MB images |
| FCM notifications | Unlimited | Free forever |
| Auth users | Unlimited | Free forever |
| Realtime DB | 1 GB / 10 GB transfer | For live order tracking |

### Spark Plan Strategy
- Use **Firestore** for: orders, menus, users, vendors
- Use **Realtime Database** for: live order status only (rider location, status updates)
- Use **Firebase Storage** for: food images (compress to < 200KB each)
- Use **FCM** for: all push notifications — never pay for this
- Avoid Functions for outbound HTTP until Blaze upgrade

---

## 7. Flutter Dependencies & Packages

### pubspec.yaml — Full Dependency List

```yaml
name: campus_foodly
description: Campus food delivery for Nairobi's Thika Road corridor

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # === STATE MANAGEMENT ===
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # === NAVIGATION ===
  go_router: ^13.2.0

  # === FIREBASE ===
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.15.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.0
  firebase_database: ^10.4.0      # Realtime DB for order tracking
  firebase_analytics: ^10.8.0

  # === PAYMENTS — M-PESA ===
  http: ^1.2.0                    # Daraja API calls

  # === MAPS & LOCATION ===
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0
  geocoding: ^3.0.0

  # === NOTIFICATIONS ===
  flutter_local_notifications: ^17.1.0

  # === IMAGES ===
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  flutter_image_compress: ^2.1.0

  # === WHATSAPP / DEEP LINKS ===
  app_links: ^6.1.0
  url_launcher: ^6.2.6

  # === UTILITIES ===
  intl: ^0.19.0                   # Date/currency formatting
  shared_preferences: ^2.2.2      # Local storage
  flutter_dotenv: ^5.1.0          # Environment variables
  connectivity_plus: ^6.0.3       # Network status
  lottie: ^3.1.0                  # Animations
  shimmer: ^3.0.0                 # Skeleton loading (already in repo)
  equatable: ^2.0.5               # Value equality

  # === UI EXTRAS ===
  flutter_svg: ^2.0.9
  pinput: ^5.0.0                  # OTP input field
  modal_bottom_sheet: ^3.0.0
  smooth_page_indicator: ^1.1.0   # Onboarding dots

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  json_serializable: ^6.7.1
```

---

## 8. Project Folder Structure

```
lib/
├── main.dart
├── firebase_options.dart         # Auto-generated by FlutterFire CLI
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Extend Foodly color palette
│   │   ├── app_strings.dart      # All text strings (easy i18n later)
│   │   ├── campus_list.dart      # All supported campuses + geofences
│   │   └── app_config.dart       # Env config, feature flags
│   ├── theme/
│   │   └── app_theme.dart        # Extend existing Foodly theme
│   ├── router/
│   │   └── app_router.dart       # go_router configuration
│   └── utils/
│       ├── currency_formatter.dart  # KES formatting
│       ├── phone_validator.dart     # Kenyan phone number validation
│       ├── geofence_helper.dart     # Campus boundary checking
│       └── date_helpers.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── vendor_model.dart
│   │   ├── menu_item_model.dart
│   │   ├── order_model.dart
│   │   ├── campus_model.dart
│   │   └── rider_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── vendor_repository.dart
│   │   ├── order_repository.dart
│   │   └── user_repository.dart
│   └── services/
│       ├── mpesa_service.dart       # Daraja API integration
│       ├── notification_service.dart
│       ├── analytics_service.dart
│       └── whatsapp_service.dart    # Africa's Talking bridge
│
├── features/
│   ├── onboarding/
│   │   ├── campus_selector_screen.dart   # NEW
│   │   └── onboarding_screen.dart        # FROM REPO — wire up
│   ├── auth/
│   │   ├── sign_in_screen.dart           # FROM REPO — wire up
│   │   ├── sign_up_screen.dart           # FROM REPO — wire up
│   │   └── otp_verification_screen.dart  # NEW
│   ├── home/
│   │   ├── home_screen.dart              # FROM REPO — wire up
│   │   └── widgets/
│   ├── vendors/
│   │   ├── vendor_detail_screen.dart     # FROM REPO — wire up
│   │   └── widgets/
│   ├── cart/
│   │   ├── cart_screen.dart              # FROM REPO — wire up
│   │   └── cart_provider.dart            # Riverpod cart state
│   ├── checkout/
│   │   ├── checkout_screen.dart          # FROM REPO — wire up
│   │   ├── address_picker_screen.dart    # NEW — Google Maps
│   │   └── mpesa_payment_screen.dart     # NEW — STK Push flow
│   ├── orders/
│   │   ├── active_order_screen.dart      # NEW — real-time tracking
│   │   ├── order_history_screen.dart     # NEW
│   │   └── order_tracking_screen.dart    # FROM REPO — make real-time
│   ├── profile/
│   │   ├── profile_screen.dart           # FROM REPO — wire up
│   │   ├── referral_screen.dart          # NEW
│   │   └── loyalty_screen.dart           # NEW
│   └── support/
│       ├── help_screen.dart              # NEW
│       └── dispute_screen.dart           # NEW
│
├── automation/
│   └── triggers/
│       ├── late_order_detector.dart      # Firestore trigger logic
│       └── voucher_generator.dart        # Auto-compensate customer
│
└── shared/
    ├── widgets/
    │   ├── campus_badge.dart
    │   ├── order_status_chip.dart
    │   ├── mpesa_button.dart
    │   └── loading_overlay.dart
    └── providers/
        ├── auth_provider.dart
        ├── campus_provider.dart
        └── cart_provider.dart
```

---

## 9. Firebase Data Schema

### Firestore Collections

```
/users/{userId}
  - uid: string
  - name: string
  - phone: string              # +254XXXXXXXXX format
  - email: string?
  - campus_id: string          # Selected campus
  - default_address: map
  - loyalty_points: number
  - referral_code: string
  - referred_by: string?
  - created_at: timestamp
  - fcm_token: string

/campuses/{campusId}
  - name: string               # "KCA University"
  - short_name: string         # "KCA"
  - latitude: number
  - longitude: number
  - radius_meters: number      # Delivery geofence (e.g. 800)
  - is_active: boolean
  - delivery_fee: number       # KES
  - min_order: number          # KES

/vendors/{vendorId}
  - name: string
  - campus_id: string
  - description: string
  - image_url: string
  - is_open: boolean
  - opens_at: string           # "07:00"
  - closes_at: string          # "21:00"
  - rating: number
  - rating_count: number
  - phone: string              # For WhatsApp notifications
  - commission_rate: number    # 0.15 = 15%
  - location: geopoint
  - categories: array<string>

/vendors/{vendorId}/menu_items/{itemId}
  - name: string
  - description: string
  - price: number              # KES
  - image_url: string
  - category: string
  - is_available: boolean
  - preparation_time: number   # minutes

/orders/{orderId}
  - order_number: string       # "FC-001234"
  - user_id: string
  - vendor_id: string
  - campus_id: string
  - items: array<map>
  - subtotal: number
  - delivery_fee: number
  - total: number
  - status: enum               # pending|confirmed|preparing|ready|picked_up|delivered|cancelled
  - payment_status: enum       # pending|paid|failed|refunded
  - mpesa_checkout_id: string
  - mpesa_receipt: string?
  - delivery_address: map
  - rider_id: string?
  - created_at: timestamp
  - confirmed_at: timestamp?
  - delivered_at: timestamp?
  - estimated_delivery: timestamp
  - notes: string?

/riders/{riderId}
  - name: string
  - phone: string
  - is_available: boolean
  - campus_id: string
  - current_order_id: string?
  - total_deliveries: number
  - rating: number

/vouchers/{voucherId}
  - code: string
  - discount_type: enum        # percentage|fixed
  - discount_value: number
  - min_order: number
  - expires_at: timestamp
  - is_used: boolean
  - user_id: string?           # null = public
  - reason: string             # "late_order_compensation"
```

### Firebase Realtime Database (Live Order Tracking Only)
```
/active_orders/{orderId}
  - status: string
  - rider_lat: number
  - rider_lng: number
  - updated_at: number         # Unix timestamp
  - estimated_minutes: number
```

### Firebase Storage Structure
```
/vendor_images/{vendorId}/logo.jpg
/vendor_images/{vendorId}/banner.jpg
/menu_items/{vendorId}/{itemId}.jpg
/user_avatars/{userId}.jpg
```

---

## 10. Feature Buildout — Screen by Screen

### 10.1 Onboarding — Campus Selector (NEW)
**Purpose:** First-time users pick their campus. Sets the delivery geofence for all future orders.
- Show map with campus pins along Thika Road
- User taps campus → confirmed with radius overlay
- Stored in Firestore `/users/{id}.campus_id`
- Can be changed in Profile later

### 10.2 Authentication — Phone OTP (ENHANCED)
**Purpose:** Replace email auth UI with phone-first flow.
- Input: Kenyan phone (+254 prefix auto-added)
- Firebase Auth `verifyPhoneNumber()` → SMS OTP
- OTP screen uses `pinput` package (6-digit input)
- Google Sign-In as secondary option
- On first login → redirect to campus selector

### 10.3 Home Screen (WIRED UP)
**Changes to Foodly base:**
- Replace hardcoded vendors with Firestore live query filtered by `campus_id`
- Show campus badge in AppBar ("Ordering to: KCA")
- Real vendor open/closed status from `is_open` field
- "Closed" vendors greyed out, sorted to bottom
- Featured section driven by `is_featured` flag on vendor

### 10.4 Cart (WIRED UP + STATE)
**Riverpod CartNotifier:**
```dart
// Cart holds: List<CartItem>, vendorId, campusId
// Rules: only 1 vendor per cart (show dialog on conflict)
// Persisted to SharedPreferences (survives app restart)
```

### 10.5 Checkout + M-Pesa (WIRED UP + NEW)
**Flow:**
1. Review cart items + delivery address
2. Tap "Pay with M-Pesa"
3. App calls Daraja STK Push API
4. Safaricom sends PIN prompt to user's phone
5. App polls Daraja for payment status (every 3 seconds, max 30 seconds)
6. On success → create order in Firestore
7. Redirect to Active Order screen

### 10.6 Active Order Screen (NEW — Real-time)
**Purpose:** The most important screen post-checkout.
- Connects to Firebase Realtime DB `/active_orders/{orderId}`
- Live status stepper: Confirmed → Preparing → Ready → On the Way → Delivered
- Estimated time countdown
- "Call Rider" button (tel: deep link)
- Auto-dismiss on delivery, redirect to Rating screen

### 10.7 Order History (NEW)
- Firestore query: orders where `user_id == currentUser` ordered by `created_at DESC`
- Paginated (10 per page)
- Quick reorder button (adds same items to cart)

### 10.8 Profile (WIRED UP)
- Display Firebase Auth user data
- Edit name, default address
- Campus change option
- Loyalty points display
- Referral code share button

### 10.9 Loyalty & Referral (NEW)
**Loyalty:** 1 point per KES 10 spent. 100 points = KES 50 voucher.
**Referral:** Unique code per user. Referrer gets 50 points when referee completes first order.

---

## 11. M-Pesa Payment Integration

### Daraja API — Client-Side STK Push (Spark Plan Compatible)

Since Firebase Spark doesn't allow outbound HTTP from Cloud Functions, the STK Push is initiated directly from the Flutter app.

```dart
// lib/data/services/mpesa_service.dart

class MpesaService {
  static const _baseUrl = 'https://sandbox.safaricom.co.ke'; // → live for prod
  
  // Step 1: Get OAuth token
  Future<String> getToken() async {
    final credentials = base64Encode(
      utf8.encode('$consumerKey:$consumerSecret')
    );
    final response = await http.get(
      Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
      headers: {'Authorization': 'Basic $credentials'},
    );
    return jsonDecode(response.body)['access_token'];
  }

  // Step 2: Initiate STK Push
  Future<String> initiateStkPush({
    required String phone,       // 254712345678
    required int amount,         // KES amount
    required String orderId,
  }) async {
    final token = await getToken();
    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final password = base64Encode(
      utf8.encode('$shortCode$passKey$timestamp')
    );
    
    final response = await http.post(
      Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'BusinessShortCode': shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount,
        'PartyA': phone,
        'PartyB': shortCode,
        'PhoneNumber': phone,
        'CallBackURL': callbackUrl,  // Your callback endpoint
        'AccountReference': 'Order-$orderId',
        'TransactionDesc': 'Campus Foodly Order',
      }),
    );
    
    return jsonDecode(response.body)['CheckoutRequestID'];
  }
}
```

### Payment Flow State Machine
```
IDLE → INITIATING → WAITING_PIN → POLLING → SUCCESS | FAILED | TIMEOUT
```

### Callback Handling
Since Spark plan can't run Cloud Functions with HTTP, use one of:
- **Free option:** Deploy a lightweight Node.js callback receiver on Railway (free tier)
- **Simpler option:** Poll Daraja's query endpoint from the app every 3s for up to 60s
- **Production:** Upgrade to Blaze and use Firebase Cloud Functions for callbacks

---

## 12. Automation & AI Layer

### 12.1 Late Order Detector
**Trigger:** Firestore rule — if order status is still `preparing` after `estimated_delivery` timestamp

```
Firestore Scheduled Query (via client polling or external cron):
→ Find orders where status != delivered AND estimated_delivery < now - 10 mins
→ Auto-generate voucher (10% off next order)
→ Send FCM push: "Sorry for the wait! Here's a voucher for your next order 🎁"
→ Update order with compensation flag
```

### 12.2 AI Customer Support Bot
**When:** User opens Help screen → Chat interface → Messages handled by Claude API

**Flow:**
1. User types issue → app sends to Claude API with order context
2. Claude resolves 90% of issues (where's my order, refund status, menu questions)
3. Escalation keywords ("speak to human", "urgent") → creates Firestore support ticket
4. You get FCM notification for escalated tickets only

**System prompt context injected per conversation:**
```
- User name, phone
- Current order status (if active)
- Order history (last 3 orders)
- Campus and vendor details
```

### 12.3 Daily Vendor Reports (Automated)
**When:** Every night at 10 PM

**Trigger:** External cron (Railway/Render free tier) reads Firestore and sends WhatsApp:
```
📊 *Daily Report — Mama Njeri's Kitchen*
Date: Wednesday, 8 April 2026

Orders Today: 23
Total Revenue: KES 8,450
Your Earnings (after 15% commission): KES 7,183
Top Item: Beef Stew + Rice (11 orders)

Keep it up! 🔥
```

### 12.4 Auto Vendor Settlement
**When:** Every Monday at 9 AM

**Action:** Calculate weekly earnings per vendor → initiate M-Pesa B2C bulk payout via Daraja API
- Vendor receives M-Pesa credit with breakdown SMS
- Firestore settlement record created for audit trail

---

## 13. WhatsApp Rider Bot

### Why WhatsApp (Not a Rider App)
- Zero app development cost
- Riders already use WhatsApp
- Can onboard a new rider in 2 minutes
- No app store approval needed

### Africa's Talking Integration (Free Tier)
Africa's Talking WhatsApp Business API — free sandbox for testing.

### Rider Flow
```
New order drops in Firestore
    ↓
Cloud Function (or external server) sends WhatsApp to all available riders:

  "🔔 New Order! #FC-0042
   📍 Pickup: Mama Njeri's Kitchen (KCA Gate B)
   📦 Deliver to: Hostel Block C, Room 204
   💰 Earnings: KES 80
   Reply YES to accept"
    ↓
First rider to reply YES
    ↓
Bot replies: "✅ Order confirmed! Pickup code: 7842
              Customer: Jane M. (+254712...)"
    ↓
Firestore order updated: rider_id = {riderId}, status = picked_up
    ↓
Customer gets FCM: "Your rider is on the way! 🛵"
    ↓
Rider delivers → replies DONE
    ↓
Bot: "Great! Payment logged. Today's total: KES 480 💪"
```

### Rider Commands
| Command | Action |
|---------|--------|
| `YES` | Accept current order |
| `DONE` | Mark order as delivered |
| `HELP` | Show available commands |
| `STATUS` | Show today's earnings |
| `OFF` | Set as unavailable |
| `ON` | Set as available |

---

## 14. Vendor Dashboard

### Technology: Next.js (Web, No App Needed)
- Hosted on **Firebase Hosting** (free on Spark plan)
- Vendors access via mobile browser — no app install required
- Responsive design (mobile-first)

### Vendor Features
1. **Menu Management** — add/edit/delete items, toggle availability, upload photos
2. **Orders View** — real-time incoming orders, accept/reject, mark as ready
3. **Analytics** — daily/weekly revenue, top items, order volume
4. **Profile** — update opening hours, description, banner photo

### Vendor Onboarding (Automated)
```
You fill Google Form with vendor details
    ↓
Form submission triggers:
    - Firestore vendor record created
    - Welcome WhatsApp sent with dashboard link + login code
    - Vendor goes live within 30 minutes
    ↓
Zero manual intervention needed
```

---

## 15. Build Timeline — 8 Weeks to Launch

### Week 1 — Foundation
- [ ] Fork foodly_ui repo, rename to campus_foodly
- [ ] Set up Firebase project (Spark plan)
- [ ] Run FlutterFire CLI → generate `firebase_options.dart`
- [ ] Implement folder structure from Section 8
- [ ] Add all dependencies from Section 7
- [ ] Set up go_router with all route definitions
- [ ] Set up Riverpod providers skeleton
- [ ] Set up `.env` with API keys

### Week 2 — Auth & Data
- [ ] Firebase Phone Auth — OTP flow
- [ ] Google Sign-In
- [ ] Campus selector screen (new)
- [ ] Firestore: seed 5 KCA vendors with menus
- [ ] Home screen wired to live Firestore data
- [ ] Vendor detail screen wired to live menu

### Week 3 — Cart & Payments
- [ ] Cart Riverpod state (with SharedPreferences persistence)
- [ ] Cart screen fully wired
- [ ] Checkout screen wired
- [ ] Address picker screen (Google Maps)
- [ ] Daraja API integration (sandbox)
- [ ] M-Pesa STK Push screen + polling flow

### Week 4 — Orders & Realtime
- [ ] Order creation in Firestore on payment success
- [ ] Active order screen (Firebase Realtime DB)
- [ ] Order status real-time updates
- [ ] FCM push notifications setup
- [ ] Order history screen

### Week 5 — Missing Screens
- [ ] OTP verification screen (pinput)
- [ ] Campus selector screen (polished)
- [ ] Profile screen wired up
- [ ] Loyalty points display
- [ ] Referral screen
- [ ] Vendor closed state UI

### Week 6 — Automation
- [ ] WhatsApp rider bot (Africa's Talking sandbox)
- [ ] Late order detector (polling logic)
- [ ] Auto-voucher generation
- [ ] Daily vendor report cron (Railway)
- [ ] AI customer support bot (Claude API)

### Week 7 — Vendor Dashboard
- [ ] Next.js vendor dashboard scaffolded
- [ ] Menu management (CRUD)
- [ ] Real-time order management
- [ ] Deployed to Firebase Hosting
- [ ] Vendor onboarding Google Form → automation

### Week 8 — QA & Launch at KCA
- [ ] Switch Daraja from sandbox → production
- [ ] End-to-end order flow test
- [ ] Sign up 5 KCA vendors manually
- [ ] Recruit 2 campus riders via WhatsApp
- [ ] Soft launch — 20 beta users from KCA
- [ ] Monitor errors (Firebase Crashlytics)
- [ ] Go live! 🚀

---

## 16. Monetization Model

### Revenue Streams

| Stream | Rate | Notes |
|--------|------|-------|
| Vendor commission | 15% per order | Primary revenue |
| Delivery fee | KES 30–50 | Paid by customer |
| Premium placement | KES 2,000/month | Featured vendor spot |
| Bulk SMS ads | KES 500/blast | Campus promotions for vendors |

### Unit Economics at KCA (Target Month 2)
```
50 orders/day × KES 350 avg order = KES 17,500 GMV/day
Commission (15%):                    KES 2,625/day
Delivery fees (50 × KES 40):        KES 2,000/day
Daily Revenue:                       KES 4,625/day
Monthly Revenue:                     KES 138,750/month

Monthly Costs:
- Rider payouts:                     KES 80,000 (50 riders × KES 80 × 20 days)
- Rider management (WhatsApp bot):   KES 0 (automated)
- Infrastructure (Firebase Spark):   KES 0 (free tier)
- Africa's Talking:                  KES ~2,000
- Domain + misc:                     KES 2,000
Total Costs:                         KES 84,000

Net Profit (Month 2, KCA only):     KES 54,750/month
```

### Upgrade Trigger
When monthly revenue exceeds **KES 50,000** → upgrade Firebase to Blaze plan → unlock Cloud Functions for cleaner automation architecture.

---

## 17. MVP Launch Checklist

### ✅ Technical Readiness
- [ ] Firebase project created and configured
- [ ] FlutterFire CLI initialized
- [ ] All dependencies installed and resolving
- [ ] `.env` file configured with all API keys
- [ ] Firebase Auth: Phone OTP working end-to-end
- [ ] Firebase Auth: Google Sign-In working
- [ ] Firestore security rules deployed (not open!)
- [ ] Firebase Storage rules deployed
- [ ] FCM push notifications working on Android
- [ ] FCM push notifications working on iOS
- [ ] M-Pesa STK Push: sandbox working
- [ ] M-Pesa STK Push: production credentials active
- [ ] M-Pesa payment polling working
- [ ] Daraja callback receiver deployed (Railway)
- [ ] Google Maps API key configured for Android + iOS
- [ ] Campus geofencing logic tested

### ✅ App Screens
- [ ] Onboarding screens display correctly
- [ ] Campus selector screen works
- [ ] Phone OTP screen works end-to-end
- [ ] Google Sign-In works end-to-end
- [ ] Home screen loads real vendor data
- [ ] Home screen shows open/closed status correctly
- [ ] Vendor detail screen loads live menu
- [ ] Cart: add/remove items works
- [ ] Cart: single vendor rule enforced
- [ ] Cart: persists on app restart
- [ ] Checkout: address picker works
- [ ] Checkout: M-Pesa payment flow complete
- [ ] Active order: real-time status updates
- [ ] Active order: call rider button works
- [ ] Order history loads correctly
- [ ] Profile screen displays user data
- [ ] Referral code sharing works
- [ ] Loyalty points display correctly
- [ ] Help screen / support bot responds

### ✅ Automation
- [ ] WhatsApp rider bot sends new order notification
- [ ] Rider YES/DONE commands handled correctly
- [ ] Customer gets FCM when rider accepts
- [ ] Late order detector triggers after 10 min delay
- [ ] Voucher auto-generated and sent on late order
- [ ] Daily vendor report sent at 10 PM
- [ ] Vendor onboarding Google Form → auto-creates Firestore record

### ✅ Vendor Dashboard
- [ ] Dashboard accessible on mobile browser
- [ ] Vendor can log in with their code
- [ ] Menu items can be created / edited / deleted
- [ ] Item availability toggle works
- [ ] Food images upload to Firebase Storage
- [ ] Incoming orders display in real-time
- [ ] Vendor can mark order as "Ready"

### ✅ Business Readiness — KCA Launch
- [ ] 5 vendors signed up and menus loaded
- [ ] At least 2 riders recruited and WhatsApp bot tested with them
- [ ] M-Pesa paybill/till number active
- [ ] Daraja production credentials verified
- [ ] 20 beta users recruited from KCA campus
- [ ] Feedback collection mechanism in place (Google Form)
- [ ] You can personally monitor the Firebase console daily

### ✅ Performance & Quality
- [ ] App loads in < 3 seconds on 4G
- [ ] Images compressed (< 200KB each)
- [ ] Firebase Crashlytics integrated
- [ ] Firestore reads optimized (no N+1 queries)
- [ ] App tested on Android (min SDK 21)
- [ ] App tested on iOS (min iOS 12)
- [ ] No hardcoded API keys in codebase
- [ ] ProGuard/R8 enabled for Android release build
- [ ] App icons and splash screen set (not Foodly defaults)
- [ ] App name changed from "foodly" to your product name

---

## 📌 Quick Reference — Key API Credentials Needed

| Service | Where to Get | Free Tier |
|---------|-------------|-----------|
| Firebase | console.firebase.google.com | Yes (Spark) |
| Google Maps API | console.cloud.google.com | $200 credit/month |
| Daraja (M-Pesa) | developer.safaricom.co.ke | Sandbox free |
| Africa's Talking | africastalking.com | Sandbox free |
| Claude API | console.anthropic.com | Pay per use |
| Railway (cron/callback) | railway.app | $5 credit/month free |

---

## 📌 Key Contacts — Thika Road Campus Belt

| Campus | Location | Est. Students | Priority |
|--------|----------|--------------|----------|
| KCA University | Thika Rd, Muthaiga | ~8,000 | 🔴 Phase 1 |
| USIU-Africa | Exit 7, Off Thika Rd | ~6,500 | 🟡 Phase 2 |
| PAC University | Lumumba Dr, Mirema | ~3,000 | 🟡 Phase 2 |
| Compaq College | Githurai | ~2,000 | 🟠 Phase 3 |
| Kenyatta University | Thika Rd, Kahawa | ~60,000 | 🟢 Phase 3 |

---

*This document is a living reference. Update it as the product evolves.*  
*Built with: Flutter · Firebase · M-Pesa · Africa's Talking · Claude AI*  
*Founder: Solo + AI Team | Location: Nairobi, Kenya*
