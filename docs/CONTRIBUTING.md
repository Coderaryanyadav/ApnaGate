# 🤝 Contributing to ApnaGate

Thank you for your interest in contributing to **ApnaGate**! We welcome community contributions to make smart community security faster, safer, and more accessible.

---

## 📋 Code of Conduct

Please be respectful, collaborative, and constructive when opening issues, submitting pull requests, and communicating with other contributors.

---

## 🛠️ Development Workflow

### 1. Fork & Clone
```bash
git clone https://github.com/<your-username>/ApnaGate.git
cd ApnaGate
```

### 2. Install Dependencies
```bash
cd app
flutter pub get
```

### 3. Branch Naming Conventions
- `feat/<feature-name>` for new features
- `fix/<bug-name>` for bug fixes
- `docs/<doc-update>` for documentation changes
- `refactor/<refactor-scope>` for code cleanup

### 4. Running Code Analysis & Tests
Before opening a pull request, ensure static analysis and all automated tests pass:

```bash
# Run Dart analyzer with strict lints
cd app
flutter analyze

# Run full automated test suite
flutter test
```

### 5. Commit Guidelines
Follow conventional commit specifications:
- `feat: add biometric pass verification`
- `fix: resolve notification race condition in background service`
- `docs: update Supabase RLS documentation`
- `test: add guest pass expiration unit tests`

---

## 🧪 Submitting a Pull Request

1. Ensure `flutter analyze` reports **0 issues**.
2. Ensure `flutter test` reports **all tests passing**.
3. Push your branch to GitHub and open a Pull Request against `main`.
4. Provide a clear description of the problem solved, changes made, and test validation steps.
