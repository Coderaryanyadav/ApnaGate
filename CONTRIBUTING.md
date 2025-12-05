# Contributing to CrescentGate

Thank you for your interest in contributing to CrescentGate! This document provides guidelines and instructions for contributing.

## 🤝 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the community
- Show empathy towards others

## 🚀 Getting Started

### 1. Fork & Clone
```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/CrescentGate.git
cd CrescentGate
```

### 2. Set Up Development Environment
```bash
cd app
flutter pub get
flutter run
```

### 3. Create a Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

## 📝 Pull Request Process

### Before Submitting
- [ ] Code follows project style guidelines
- [ ] All tests pass (`flutter test`)
- [ ] No lint errors (`flutter analyze`)
- [ ] Documentation updated (if needed)
- [ ] Commits are clear and descriptive

### PR Guidelines
1. **Title:** Clear, descriptive (e.g., "Add dark mode toggle to settings")
2. **Description:** Explain what, why, and how
3. **Screenshots:** Include for UI changes
4. **Issue Link:** Reference related issues

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Steps to test the changes

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Tests pass
- [ ] No lint errors
- [ ] Documentation updated
```

## 🎨 Code Style

### Dart/Flutter
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter format .` before committing
- Max line length: 80 characters
- Use meaningful variable names

### Example
```dart
// ✅ Good
final String userName = getUserName();
if (userName.isNotEmpty) {
  displayWelcomeMessage(userName);
}

// ❌ Bad
var n = getName();
if(n != '') { show(n); }
```

### File Naming
- **Screens:** `user_profile_screen.dart`
- **Widgets:** `custom_button.dart`
- **Models:** `user_model.dart`
- **Services:** `auth_service.dart`

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/models/user_test.dart

# With coverage
flutter test --coverage
```

### Writing Tests
```dart
test('should return user when login is successful', () {
  // Arrange
  final email = 'test@example.com';
  final password = 'password123';
  
  // Act
  final result = authService.login(email, password);
  
  // Assert
  expect(result, isA<User>());
});
```

## 📦 Commit Messages

### Format
```
type(scope): subject

body (optional)

footer (optional)
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### Examples
```bash
feat(auth): add biometric authentication

fix(visitor): resolve photo upload crash on Android 11

docs(readme): update installation instructions

refactor(models): simplify user model structure
```

## 🐛 Bug Reports

### Before Reporting
1. Check existing issues
2. Update to latest version
3. Try to reproduce consistently

### Issue Template
```markdown
**Description**
Clear description of the bug

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Screenshots**
If applicable

**Environment**
- Device: [e.g., Pixel 5]
- Android Version: [e.g., 12]
- App Version: [e.g., 2.0]
```

## 💡 Feature Requests

### Proposal Template
```markdown
**Problem Statement**
What problem does this solve?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other options you thought about

**Additional Context**
Mockups, examples, references
```

## 🏗️ Project Structure

```
lib/
├── models/          # Data models
├── screens/         # UI screens
│   ├── admin/      # Admin screens
│   ├── guard/      # Guard screens
│   └── resident/   # Resident screens
├── services/        # Business logic
├── widgets/         # Reusable widgets
└── main.dart        # Entry point
```

## 🔧 Development Tips

### Hot Reload
```bash
# In terminal running app
r    # Hot reload
R    # Hot restart
q    # Quit
```

### Debug Tools
```dart
// Print debug info
debugPrint('User: $user');

// Performance timeline
Timeline.startSync('expensive_operation');
// ... code ...
Timeline.finishSync();
```

### Common Commands
```bash
# Clean build
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Generate coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📱 Platform-Specific Notes

### Android
- Min SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Permissions in `AndroidManifest.xml`

### iOS (Future)
- Min iOS: 12.0
- Permissions in `Info.plist`

## 🎯 Areas Needing Help

- [ ] iOS support
- [ ] Localization (Hindi, regional languages)
- [ ] Accessibility improvements
- [ ] Performance optimization
- [ ] Unit test coverage
- [ ] Documentation

## 📚 Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Firebase Flutter](https://firebase.flutter.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## ❓ Questions?

- Open a [Discussion](https://github.com/Coderaryanyadav/CrescentGate/discussions)
- Comment on relevant issue
- Review existing PRs for examples

## 🙏 Recognition

Contributors will be:
- Listed in README
- Mentioned in release notes
- Given credit in commits

Thank you for contributing to CrescentGate! 🎉
