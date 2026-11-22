# ApnaGate 🚪🏢
### Smart Society Gatekeeper & Resident Security Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![OneSignal](https://img.shields.io/badge/OneSignal-Push_Notifications-E54B4D?logo=onesignal&logoColor=white)](https://onesignal.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**ApnaGate** is a smart building and gated community visitor management platform built with **Flutter**, **Supabase**, and **OneSignal**. It replaces slow, error-prone manual visitor registers with real-time digital pass verification, instant one-tap visitor approval notifications, daily staff entry/exit tracking, and high-priority emergency SOS broadcast alerts.

---

## 🌟 Key Features

### 🛡️ Guard Gatekeeper Mode
- **Quick Visitor Entry:** Enter visitor details (name, phone, wing, flat number, purpose) and send instant push notifications directly to residents.
- **QR Guest Pass Scanning:** High-speed camera scanner using `mobile_scanner` to validate digital invitation passes instantly.
- **Daily Staff Attendance:** Log entries and exits for domestic help (maids, cooks, drivers) with live timestamp tracking.
- **Security Patrol Logging:** Checkpoint verification logged directly into offline local storage (Hive) for audit compliance.
- **Real-Time Approval Status:** Live status monitoring (Pending / Approved / Denied / Completed) powered by Supabase Realtime.

### 👤 Resident Management Mode
- **Instant Visitor Approvals:** Receive high-priority push notifications and approve or deny visitors in one tap.
- **Digital Guest Passes:** Generate 6-digit codes and dynamic QR invitation passes for family, friends, and delivery personnel.
- **Household & Staff Directory:** Manage family members and track daily help attendance.
- **Emergency SOS Broadcast:** Trigger immediate high-decibel audible sirens to on-duty security guard devices with flat coordinates.
- **Maintenance & Complaints:** File maintenance issues and track status updates directly with building administrators.
- **Society Notices:** View official announcements and notices posted by committee administrators.

### 👑 Admin Operations Hub
- **User & Flat Management:** Full CRUD management over resident, guard, and administrator profiles.
- **Notice Publishing:** Broadcast society-wide notices and urgent announcements.
- **Complaint Resolution:** Triage and update maintenance tickets submitted by residents.
- **Service Provider Directory:** Maintain society directory for emergency technicians (plumbers, electricians, carpenters).
- **Patrol & Audit Reports:** Review guard patrol checkpoint history and visitor volume analytics.

---

## 🏗️ Clean Project Directory Tree

```
ApnaGate/
├── README.md                           # Main project documentation & setup guide
├── LICENSE                             # MIT License
├── package.json                        # Monorepo command runner & scripts
│
├── app/                                # Flutter cross-platform mobile/desktop application
│   ├── README.md                       # Mobile app build & release guide
│   ├── pubspec.yaml                    # Flutter package dependencies
│   ├── analysis_options.yaml           # Strict Dart analyzer linting rules
│   ├── l10n.yaml                       # Localization configuration
│   ├── assets/
│   │   ├── logo.png                    # App brand icon
│   │   └── sounds/
│   │       └── alarm.mp3               # High-decibel SOS alarm audio
│   ├── lib/
│   │   ├── main.dart                   # App entrypoint & service initialization
│   │   ├── app.dart                    # MaterialApp & route mapping
│   │   ├── auth_wrapper.dart           # Role-based route guard & auth listener
│   │   ├── supabase_config.dart        # Supabase and OneSignal configuration
│   │   ├── models/                     # Data models with JSON serialization
│   │   │   ├── user.dart               # AppUser profile model
│   │   │   ├── visitor.dart            # Visitor entry model
│   │   │   ├── guest_pass.dart         # Digital guest pass model
│   │   │   ├── daily_help.dart         # Staff & househelp model
│   │   │   ├── notice.dart             # Society notice model
│   │   │   ├── complaint.dart          # Maintenance complaint model
│   │   │   ├── sos_alert.dart          # Emergency SOS model
│   │   │   └── service_provider.dart   # Service directory model
│   │   ├── services/                   # Business logic & cloud integrations
│   │   │   ├── auth_service.dart       # Supabase authentication service
│   │   │   ├── firestore_service.dart  # Data layer with Hive offline cache
│   │   │   ├── onesignal_manager.dart  # OneSignal user & subscription sync
│   │   │   ├── ads_service.dart        # Google Mobile Ads integration
│   │   │   └── background_service.dart # Background service for continuous monitoring
│   │   ├── utils/                      # Styling & constants
│   │   │   ├── app_constants.dart      # Application constants
│   │   │   ├── app_routes.dart         # Route identifier definitions
│   │   │   └── app_theme.dart          # Cyberpunk dark & light theme specs
│   │   ├── widgets/                    # Reusable components
│   │   │   └── error_boundary.dart     # Global crash shield error boundary
│   │   └── screens/                    # User interface screens
│   │       ├── splash_screen.dart      # Animated startup splash screen
│   │       ├── auth/login_screen.dart  # User authentication screen
│   │       ├── guard/                  # Security guard features
│   │       ├── resident/               # Resident features
│   │       └── admin/                  # Society administrator dashboard
│   ├── test/                           # Automated unit & widget tests
│   │   ├── models_test.dart            # Model serialization tests
│   │   ├── theme_test.dart             # Theme configuration tests
│   │   ├── routes_test.dart            # Route registry uniqueness tests
│   │   ├── error_boundary_test.dart    # Error boundary widget tests
│   │   └── widget_test.dart            # App smoke tests
│   └── scripts/
│       └── build_optimized.sh          # Production release build script
│
├── database/                           # Database schemas & security rules
│   ├── README.md                       # Database setup guide
│   ├── MASTER_SETUP.sql                # Complete PostgreSQL schema & RLS policies
│   ├── add_onesignal_column.sql        # Migration for OneSignal subscription ID
│   ├── firestore.rules                 # Security rules for Firestore mode
│   └── firestore.indexes.json          # Firestore query indexes
│
├── docs/                               # System documentation
│   ├── ARCHITECTURE.md                 # System architecture & sequence diagrams
│   ├── COST_ANALYSIS.md                # Infrastructure cost & scaling analysis
│   ├── QUICK_REFERENCE.md              # Operations manual & notification testing
│   ├── screenshots/                    # Application UI captures
│   └── SecureGate_Smart_Building_Visitor_Notification_System.docx # Original specification
│
├── functions/                          # Firebase Cloud Functions (optional fallback)
│   ├── index.js                        # Push notification cloud functions
│   └── package.json
│
├── supabase/                           # Supabase configuration & Edge Functions
│   ├── config.toml                     # Supabase local development configuration
│   └── functions/
│       ├── deno.json                   # Deno compiler configuration
│       └── send-notification/
│           └── index.ts                # TypeScript Edge Function for push delivery
│
├── scripts/                            # Diagnostic & testing utilities
│   ├── README.md                       # Diagnostic scripts documentation
│   ├── audit_system.dart               # Full database & push delivery audit
│   ├── check_schema.dart               # Column & RLS schema checker
│   ├── test_full_flow.dart             # Full arrival push simulation
│   └── test_onesignal.dart             # OneSignal API credential test
│
└── web/                                # Web display tools
    └── tv_checkpoint.html              # Lobby TV dynamic QR scanner display
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.10` or higher)
- [Dart SDK](https://dart.dev/get-dart) (`v3.0` or higher)
- [Supabase](https://supabase.com) account & project
- [OneSignal](https://onesignal.com) App ID

### 2. Clone Repository
```bash
git clone https://github.com/Coderaryanyadav/ApnaGate.git
cd ApnaGate
```

### 3. Database Initialization
1. Open the [Supabase Dashboard](https://supabase.com/dashboard) -> **SQL Editor**.
2. Run the script [`database/MASTER_SETUP.sql`](database/MASTER_SETUP.sql).
3. This creates all tables, Row Level Security (RLS) policies, security definer helper functions, and default seed users.

### 4. Configure Application Credentials
Verify credentials in [`app/lib/supabase_config.dart`](app/lib/supabase_config.dart):
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
}
```

### 5. Install Dependencies & Run Tests
```bash
cd app
flutter pub get
flutter analyze
flutter test
```

### 6. Run the App
```bash
# Run on connected device or simulator
flutter run
```

---

## 🧪 Testing & Verification

The project includes an automated test suite verifying data serialization, theme consistency, route registration, and error boundaries:

```bash
# Run all unit and widget tests
npm run test
# OR inside app/
cd app && flutter test
```

To run the offline static analysis with strict lints:
```bash
npm run analyze
# OR inside app/
cd app && flutter analyze
```

---

## 🔒 Security Architecture

- **Row Level Security (RLS):** Every PostgreSQL table enforces strict multi-tenant isolation with `WITH CHECK` clauses preventing unauthorized reads and modifications.
- **No Client Secrets:** Sensitive credentials like the OneSignal REST API key are kept off the client and handled securely via Supabase Edge Functions.
- **Fail-Safe Offline Mode:** Local database caching via Hive guarantees smooth operation even during temporary network interruptions.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
