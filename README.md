# Crescent Gate

**Crescent Gate** is a modern, comprehensive **Society Management System** built with **Flutter** and **Supabase**. It streamlines communication between residents, guards, and administration, ensuring a secure and efficient living environment.

![Crescent Gate App](https://via.placeholder.com/800x400?text=Crescent+Gate+Preview)

## ✨ Key Features

### 👤 For Residents
- **Visitor Management:** Receive instant notifications (Push + Realtime) for visitors. Approve/Reject entry with one tap.
- **Visitor History:** Track all entries and exits with a synced calendar view for the entire flat.
- **Daily Help:** Manage maids, cooks, and drivers. View their daily attendance.
- **Household Management:** Add family members. Everyone in the flat stays synced.
- **Complaints:** Raise issues (plumbing, electrical) and track status with admin chat.
- **Gate Pass:** Generate digital passes for guests.
- **SOS Alert:** Emergency button that instantly notifies all guards and admins.
- **Notices:** Digital notice board for society announcements.

### 🛡️ For Guards
- **Fast Visitor Entry:** Add visitors quickly with photo capture.
- **Realtime Approvals:** See resident approval status instantly.
- **Staff Attendance:** Mark entry/exit for daily help staff.
- **Verify Passes:** Scan guest passes.

### 🔧 For Admins
- **Dashboard:** Overview of society stats (Residents, Visitors, Complaints).
- **User Management:** Add/Remove residents and guards.
- **Broadcast Notices:** Send alerts to all residents.
- **Resolve Complaints:** Manage and resolve resident issues.

---

## 🛠️ Technology Stack

- **Frontend:** Flutter (Mobile App for iOS & Android)
- **Backend:** Supabase (PostgreSQL, Auth, Realtime, Storage)
- **State Management:** Flutter Riverpod
- **Notifications:** OneSignal + Supabase Realtime (Dual Delivery System)

---

## 🚀 Deployment Guide

Follow these steps to set up the project from scratch.

### 1️⃣ Database Setup (Supabase)

The entire database schema, security policies (RLS), and initial seed data are contained in a single file: **`DEPLOYMENT_MASTER.sql`**.

1.  Create a new project in [Supabase](https://supabase.com).
2.  Navigate to the **SQL Editor** in the dashboard.
3.  Open the `DEPLOYMENT_MASTER.sql` file from this repository.
4.  Copy and paste the content into the SQL Editor.
5.  **Run** the script.

> **Note:** The script includes default users (Admin, Resident, Guard) with the password `123456`.

### 2️⃣ App Configuration

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/crescent-gate.git
    cd crescent-gate/app
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Environment:**
    Open `lib/supabase_config.dart` and update it with your Supabase credentials and OneSignal keys:
    ```dart
    class SupabaseConfig {
      static const String url = 'YOUR_SUPABASE_URL';
      static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
      static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
      static const String oneSignalRestApiKey = 'YOUR_ONESIGNAL_REST_KEY';
    }
    ```

4.  **Run the App:**
    ```bash
    flutter run --release
    ```

---

## 🔐 Default Credentials

Use these credentials to test the different roles:

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `crescentlandmark@gmail.com` | `123456` |
| **Resident** (A-1101) | `aryanjyadav@gmail.com` | `123456` |
| **Guard** (Wing A) | `guardawing@gmail.com` | `123456` |

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
