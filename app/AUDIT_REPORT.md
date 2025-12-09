# Brutal Code Audit Report
**Date**: December 10, 2025
**Auditor**: Antigravity Agent

## 🚨 Critical Issues (High Priority)

### 1. Security: Missing Role Verification on Admin Dashboard
- **File**: `lib/screens/admin/admin_dashboard.dart`
- **Issue**: The `AdminDashboard` widget does not perform a check to ensure the current user has the `admin` role.
- **Risk**: A resident or guest who navigates to the `/admin` route (via deep link or routing bug) would have full access to manage users, settings, and view SOS alerts.
- **Recommendation**: Add a check in `initState` or `build` to redirect unauthorized users immediately.

### 2. Functional: Household Member Visibility Incomplete
- **File**: `lib/screens/resident/household_screen.dart`
- **Issue**: The screen currently lists members **only from the `household_registry` table**, ignoring family members who registered independently (and exist in `profiles` but not `registry`).
- **Effect**: Users report "cannot see all members" or "only manager seen".
- **Status**: A fix was started (`getResidentsStream` added to service) but UI integration is pending.
- **Recommendation**: Merge `profiles` (Active) and `registry` (Pending) streams in the UI.

### 3. Performance: Inefficient Dashboard Re-rendering
- **File**: `lib/screens/admin/admin_dashboard.dart`
- **Issue**: A `Timer.periodic` triggers `setState` every 10 seconds. Inside `build`, a `FutureBuilder` calls `getUserStats()` (a database query).
- **Effect**: The app executes specific database reads every 10 seconds per active admin, increasing costs and network usage unnecessarily.
- **Recommendation**: Replace `FutureBuilder` with a Stream or Riverpod Provider, or increase the interval/cache the result.

### 4. Database Integrity: FK Violation (23503) Risk
- **File**: `lib/services/firestore_service.dart` / `staff_entry.dart`
- **Issue**: While `updateProviderStatus` now accepts `ownerId` to fix FK errors, logic relies on `actorId` (Guard ID) as a fallback. If a Guard account is deleted or not synced to `profiles`, 23503 will recur.
- **Recommendation**: Ensure `owner_id` is nullable in the database for "General" entries, or strictly validate Guard profiles.

## ⚠️ Maintenance & Code Quality (Medium Priority)

### 5. Config Hardcoding & Duplication
- **File**: `lib/screens/admin/admin_dashboard.dart`
- **Issue**: Notification Channel IDs (`crescent_bg_service`, `crescent_gate_alarm_v2`) are hardcoded strings. Private widget classes (`_ModernStatCard`) are defined in the file, potentially duplicating similar widgets in `admin_extras.dart`.
- **Recommendation**: Move constants to `AppConstants`. Centralize shared widgets.

### 6. Debugging Artifacts
- **Files**: `main.dart`, `firestore_service.dart`
- **Issue**: `print` and `debugPrint` statements are scattered. `audioplayers` import is commented out but dependency logic remains in `OneSignal` listener (commented).
- **Recommendation**: Use a structured `Logger` service. Remove dead code.

## ✅ Recent Fixes Verified
1.  **Society Settings Error (23505)**: Fixed via `upsert(..., onConflict: 'key')`.
2.  **Staff Entry Notifications**: Implemented logic to notify specific residents.
3.  **App Build**: Build pipeline restored (`flutter/foundation` import fix).

## Immediate Action Plan
1.  **Fix #2 (Household Visibility)**: Complete the UI merge logic.
2.  **Fix #1 (Admin Security)**: Add role check.
3.  **Fix #3 (Performance)**: Remove polling timer or optimize fetching.
