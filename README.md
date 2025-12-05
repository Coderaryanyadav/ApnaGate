# CrescentGate 🏘️

A modern, feature-rich society management application built with Flutter and Firebase.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Android-brightgreen.svg)

## 📱 Overview

CrescentGate is a comprehensive society management solution designed for residential communities. It streamlines visitor management, enhances security, and improves communication between residents, guards, and management.

## ✨ Features

### 🔐 Security & Access Control
- **Visitor Management** - Capture photos, approve/reject entries
- **QR Pass System** - Generate time-bound guest passes
- **Real-time Tracking** - Monitor all visitor activities
- **Biometric Authentication** - Fingerprint and face unlock support

### 📢 Communication
- **Notice Board** - Post and view community announcements
- **Complaint Management** - Track and resolve resident issues
- **Service Directory** - Quick access to verified service providers
- **SOS Alerts** - Emergency notifications

### 👥 User Roles
- **Admin** - Full system control and analytics
- **Guards** - Visitor entry and staff management
- **Residents** - Visitor approval and community access

### 🎨 User Experience
- **Dark Mode** - System-aware theme switching
- **Search & Filter** - Quick data access
- **Pull-to-Refresh** - Latest updates
- **Photo Zoom** - Detailed visitor photos
- **Haptic Feedback** - Enhanced interactions

### 📊 Analytics
- **Dashboard** - Visitor trends and statistics
- **Reports** - Exportable data insights
- **Real-time Charts** - Visual data representation

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10 or higher)
- Android Studio / VS Code
- Firebase account
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Coderaryanyadav/CrescentGate.git
cd CrescentGate
```

2. **Install dependencies**
```bash
cd app
flutter pub get
```

3. **Firebase Setup**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

4. **Run the app**
```bash
flutter run
```

## 🏗️ Architecture

### Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Auth, Messaging, Crashlytics)
- **State Management:** Riverpod
- **Local Database:** Shared Preferences
- **Charts:** FL Chart
- **Notifications:** Firebase Cloud Messaging

### Project Structure
```
CrescentGate/
├── app/                    # Flutter application
│   ├── lib/
│   │   ├── models/        # Data models
│   │   ├── screens/       # UI screens
│   │   ├── services/      # Business logic
│   │   ├── widgets/       # Reusable components
│   │   └── main.dart      # Entry point
│   ├── android/           # Android configuration
│   └── pubspec.yaml       # Dependencies
├── functions/             # Cloud Functions (optional)
└── firestore.rules        # Security rules
```

## 📦 Build Release APK

```bash
cd app
flutter build apk --release
```

Output: `app/build/app/outputs/flutter-apk/app-release.apk`

## 🔒 Security

### Firestore Rules
- Role-based access control
- Input validation
- Field-level restrictions
- Regex pattern matching

### Best Practices
- Biometric authentication
- Secure token management
- Error logging with Crashlytics
- HTTPS-only communication

## 🛠️ Configuration

### 1. Firebase Project
- Enable Authentication (Email/Password)
- Enable Firestore Database
- Enable Cloud Messaging
- Enable Crashlytics

### 2. Create Admin User
```javascript
// Via Firebase Console
{
  "email": "admin@example.com",
  "name": "Admin Name",
  "role": "admin",
  "flatNumber": "ADMIN"
}
```

### 3. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

## 📱 Screenshots

[Add screenshots here showcasing key features]

## 🧪 Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter drive --target=test_driver/app.dart
```

## 📚 Documentation

- [User Guide](docs/USER_GUIDE.md)
- [Admin Manual](docs/ADMIN_MANUAL.md)
- [API Reference](docs/API.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Bug Reports

Found a bug? Please open an issue with:
- Description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)

## 💡 Feature Requests

Have an idea? We'd love to hear it! Open an issue with the `enhancement` label.

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/Coderaryanyadav/CrescentGate/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Coderaryanyadav/CrescentGate/discussions)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- Open source community for valuable packages

## 📈 Roadmap

- [ ] iOS Support
- [ ] Web Admin Panel
- [ ] Multi-language Support (Hindi, Regional)
- [ ] Visitor Analytics Dashboard
- [ ] Integration with Smart Home Devices
- [ ] WhatsApp Notifications

## 🔧 Troubleshooting

### Common Issues

**1. Build fails with Gradle error**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**2. Firebase not initialized**
- Run `flutterfire configure`
- Ensure `google-services.json` exists

**3. App crashes on startup**
- Check Crashlytics dashboard
- Verify Firebase configuration

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/Coderaryanyadav/CrescentGate)
![GitHub forks](https://img.shields.io/github/forks/Coderaryanyadav/CrescentGate)
![GitHub issues](https://img.shields.io/github/issues/Coderaryanyadav/CrescentGate)
![GitHub pull requests](https://img.shields.io/github/issues-pr/Coderaryanyadav/CrescentGate)

---

**Built with ❤️ for modern communities**
