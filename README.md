# ApnaGate 🚪🏢

**ApnaGate** is a smart society and building visitor management system built with Flutter, Supabase, and OneSignal. It streamlines security and resident communication with instant visitor alerts, digital passes, househelp attendance, and SOS emergency protocols.

---

## 🌟 Key Features

- 🔔 **Multi-Layer Push Notifications:** Instant alerts for visitor arrivals, guest passes, and daily staff entries powered by OneSignal and Supabase Realtime.
- 🚨 **Emergency SOS System:** High-priority instant alerts to guards and residents with automated audio alarm triggers.
- 🛡️ **Guard Gatekeeper Mode:** Quick visitor check-in, pass scanning, and patrol logs.
- 👥 **Resident Management:** Approve/reject entries, manage household members, and track daily help attendance.
- 🗄️ **Offline Caching:** Hive local storage for smooth operation during intermittent network connectivity.
- 🌐 **Localization & Multilingual:** Built-in localization support for multi-language resident communities.

---

## 🏗️ Architecture & Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Cross-platform for Android, iOS & macOS)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Backend / Database:** [Supabase](https://supabase.com/) (PostgreSQL with Row Level Security & Realtime)
- **Push Notifications:** [OneSignal](https://onesignal.com/) & `flutter_local_notifications`
- **Local Storage:** [Hive](https://pub.dev/packages/hive_flutter)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.x or higher)
- Dart SDK
- Supabase account with schema set up (see [`MASTER_SETUP.sql`](MASTER_SETUP.sql))
- OneSignal App ID

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Coderaryanyadav/ApnaGate.git
   cd ApnaGate
   ```

2. **Configure Database & Credentials:**
   - Execute [`MASTER_SETUP.sql`](MASTER_SETUP.sql) in your Supabase SQL editor.
   - Configure your keys in [`app/lib/supabase_config.dart`](app/lib/supabase_config.dart) or via environment variables.

3. **Install Dependencies:**
   ```bash
   cd app
   flutter pub get
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
