# 🌙 Crescent Gate App - User Manual

## 📲 1. Installation
1.  **Download the APK**: `app-release.apk`
2.  **Install on Android**:
    *   Tap the file -> Install.
    *   If prompted, allow "Install from Unknown Sources".
3.  **Open the App**: You will see the "Crescent Gate" Splash Screen.

---

## 🔑 2. Setting Up the First Admin
Since the app starts with **NO users**, you must create the **First Admin** manually.

### **Method A: Direct Signup (Easiest)**
1.  Open the App -> Click **"Don't have an account? Register"**.
2.  Fill in details:
    *   **Name**: `Admin User`
    *   **Email**: `admin@crescentgate.com` (or any email)
    *   **Password**: `admin123`
    *   **Phone**: `9876543210`
    *   **Wing**: `A`
    *   **Flat**: `101` (Doesn't matter for initial setup)
    *   **Role**: Select **"Admin"** (if available in dropdown).
    *   *Note: If "Admin" is NOT in the dropdown, select "Resident" first, then use Firestore Console to change `role` to `admin`.*

### **Method B: Firestore Console (If Role Dropdown is Hidden)**
1.  Register as a normal user.
2.  Go to **Firebase Console** -> **Firestore Database**.
3.  Find the `users` collection.
4.  Find your user ID document.
5.  Change the `role` field from `'resident'` to `'admin'`.
6.  Restart the App. You will see the **Admin Dashboard**.

---

## 👥 3. Adding Other Users (Guards & Residents)
**Only Admins** can add verified users officially.

1.  **Login as Admin**.
2.  Go to **"User Management"** (👥 icon).
3.  Tap the **Floating (+) Button**.
4.  **Create Guard**:
    *   Name: `Ramesh Guard`
    *   Email: `guard1@gate.com`
    *   Password: `guard123`
    *   Role: `Guard`
    *   Wing/Flat: `Security` / `0`
5.  **Create Resident**:
    *   Name: `Aryan Yadav`
    *   Email: `aryan@home.com`
    *   Password: `aryan123`
    *   Role: `Resident`
    *   Wing: `A`, Flat: `101`

**Share the Email & Password with the user so they can login.**

---

## 🛡️ 4. Feature Guide

### **For Residents 🏠**
*   **Gate Pass**: Tap "Gate Pass" -> "Generate New Pass". Share the QR Code screenshot with your guest.
*   **Approvals**: When a visitor arrives, you get a Popup. Click **APPROVE** or **REJECT**.
*   **Complaints**: Report issues (e.g., "Water Leakage"). Admins see this immediately.
*   **SOS 🚨**: Tap the RED SOS button in emergencies. Alerts ALL Guards instantly.

### **For Guards 👮**
*   **Visitor Entry**: Tap "Add Visitor" -> Enter details -> Take Photo.
*   **Scan Pass**: Tap "Scan Pass" -> Scan a guest's QR code for instant entry.
*   **SOS Alert**: If an alarm rings, check the Dashboard. It shows EXACT Flat Number.

### **For Admins 👑**
*   **Manage Users**: Add/Delete residents and guards.
*   **Notices**: Post announcements (e.g., "Lift Maintenance"). Sent to all residents.
*   **Complaints**: View and resolve resident complaints.
*   **Reset Data**: Use the "Broom" icon in User Management to clear test data.

---

## ⚠️ Troubleshooting
*   **"Index Error"**: If you see a red screen about "Index", contact developer (Fixed in v3.0).
*   **Notifications not arriving**: Ensure App Battery Optimization is OFF.
*   **SOS Sound**: Works best when app is open or in background.

---
 
