---
description: UI Polish & Data Cleanup Tasks
---

# CrescentGate UI Fixes & Data Reset - v2.4

## 🎯 PRIORITY FIXES (Based on Screenshots)

### 1. Resident Home Screen
- [ ] **Welcome Header**: Change "Welcome Home 🏠" to "Welcome Home, [User Name]"
- [ ] **Fetch User Name**: Get current user's name from Firestore and display it
- [ ] **Remove Pending Badge**: The "No pending approvals" screen shows correctly, keep it clean

### 2. Admin Dashboard
- [ ] **Wings Display**: Change wings display from dynamic list to hardcoded "A & B"
- [ ] **Reset Analytics**: Clear all analytics data or set to zero
- [ ] **User Management Button**: Keep as-is (working correctly)

### 3. User Management Screen  
- [ ] **Delete All Users**: Remove all users EXCEPT:
  - Admin account (keep existing admin)
  - Watchmen/Guards (keep existing guards)
  - Test User: Name="Test Resident", Flat="A-101", Role="resident"
- [ ] **Fix Search**: Ensure search works properly
- [ ] **Fix Edit Dialog**: Ensure edit functionality works without errors

### 4. Guard Dashboard - Visitor Log
- [ ] **Today's Log Only**: Show ONLY today's visitor entries by default
- [ ] **Remove Calendar Emoji**: Change "📅 Today's Log" to "Today's Log" (remove emoji)
- [ ] **Hide Old Logs**: Keep historical logs in database but hide from default view
- [ ] **Add "View All" Button**: Optional button to show full history if needed

### 5. Guard Dashboard - General
- [ ] **Remove Emojis**: Strip emojis from all guard dashboard headers/titles
- [ ] **Clean UI**: Ensure consistent dark theme

### 6. Complaints Screen
- [ ] **Loading State**: The infinite loading spinner needs to be fixed
- [ ] **Empty State**: Show proper "No complaints" message when empty

### 7. Gate Pass Screen  
- [ ] **Working Correctly**: "No pending approvals" state is good, keep it

---

## 📋 IMPLEMENTATION CHECKLIST

### Phase 1: Resident Home (15 min)
1. Modify `resident_home.dart`
2. Fetch user data using `ref.watch(authServiceProvider).currentUser`
3. Query Firestore for user name
4. Update header to "Welcome Home, [Name]"

### Phase 2: Admin Dashboard (10 min)
1. Modify `admin_dashboard.dart`
2. Hardcode wings to "A & B" instead of dynamic fetch
3. Reset stats to show clean numbers

### Phase 3: Data Cleanup (20 min)
1. Create a Firestore cleanup script/function
2. Delete users where role != 'admin' AND role != 'guard'
3. Create test user: A-101
4. Verify admin and guards remain

### Phase 4: Guard Dashboard (20 min)
1. Modify `visitor_status.dart`
2. Filter visitors by `createdAt >= today 00:00:00`
3. Remove calendar emoji from title
4. Add optional "View All History" button

### Phase 5: Complaints Fix (10 min)
1. Check `complaint_list.dart`
2. Fix StreamBuilder loading state
3. Add proper empty state UI

---

## 🔧 TECHNICAL NOTES

**Resident Name Fetch:**
```dart
final user = ref.watch(authServiceProvider).currentUser;
final userData = await ref.read(firestoreServiceProvider).getUser(user!.uid);
final userName = userData?.name ?? 'Resident';
```

**Today's Filter (Guard Log):**
```dart
final today = DateTime.now();
final startOfDay = DateTime(today.year, today.month, today.day);
.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
```

**Hardcoded Wings:**
```dart
// Replace dynamic wings fetch with:
final wingsText = 'A & B';
```

---

## ⚠️ CRITICAL
- Backup Firestore data before deleting users
- Test on emulator first
- Keep admin credentials safe
- Verify guard accounts remain intact

---

## 🎯 SUCCESS CRITERIA
✅ Resident sees their name on home screen
✅ Admin dashboard shows "A & B" for wings
✅ Only test user A-101 + admin + guards exist
✅ Guard log shows ONLY today's entries
✅ No emojis in guard dashboard headers
✅ Complaints screen loads properly
