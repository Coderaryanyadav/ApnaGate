# 🧪 Diagnostic & Testing Scripts

This directory contains standalone Dart diagnostic utilities to verify backend database connectivity, schema integrity, and OneSignal push notification delivery.

---

## 📜 Available Scripts

### 1. `audit_system.dart`
Performs an end-to-end audit:
- Database connectivity check against `society_config`.
- Resident profile verification (Wing A, Flat 1101).
- Checks whether `onesignal_player_id` is registered for the device.
- Dispatches a test visitor arrival push notification via OneSignal REST API.
- Dispatches a test SOS alert filtered to guards.

**Usage:**
```bash
export ONESIGNAL_REST_API_KEY="your-rest-api-key"
dart run scripts/audit_system.dart
```

---

### 2. `check_schema.dart`
Quick sanity check that queries the Supabase REST API to confirm that the `onesignal_player_id` column exists and is readable under Row Level Security.

**Usage:**
```bash
dart run scripts/check_schema.dart
```

---

### 3. `test_full_flow.dart`
Simulates a full visitor arrival workflow:
- Queries Supabase for resident profile.
- Validates player subscription ID.
- Sends high-priority OneSignal push to the specific device.

**Usage:**
```bash
export ONESIGNAL_REST_API_KEY="your-rest-api-key"
dart run scripts/test_full_flow.dart
```

---

### 4. `test_onesignal.dart`
Lightweight diagnostic script testing basic OneSignal REST API credentials and app ID connectivity.

**Usage:**
```bash
dart run scripts/test_onesignal.dart
```
