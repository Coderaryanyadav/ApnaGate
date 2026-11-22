# 🛡️ Security Policy

## 🔒 Supported Versions

We provide security patches and updates for the following versions:

| Version | Supported |
| :--- | :---: |
| `v1.1.x` | ✅ Yes |
| `v1.0.x` | ❌ No |

---

## 🚨 Reporting a Vulnerability

If you discover a security vulnerability within **ApnaGate**, please **do not** disclose it publicly via GitHub issues.

Please send a vulnerability report directly to:
📧 **coderaryanyadav@gmail.com**

### Please include:
1. Type of issue (e.g., Row Level Security bypass, broken authentication, sensitive key leakage).
2. Step-by-step instructions or proof-of-concept to reproduce the vulnerability.
3. Affected components (`app/lib`, `database/MASTER_SETUP.sql`, `supabase/functions`, etc.).
4. Potential impact on residents or gate operations.

### Our Commitment:
- We acknowledge receipt within **24 hours**.
- We provide an estimated timeline for the fix.
- We release a coordinated security patch before public disclosure.

---

## 🛡️ Built-in Security Measures

- **Database Row Level Security (RLS):** All tables strictly isolate resident data using `auth.uid() = resident_id` and security definer functions (`is_guard()`, `is_admin()`).
- **Secret Key Isolation:** High-privilege API keys (OneSignal REST API key, Supabase service role keys) are executed exclusively within Supabase Edge Functions or backend services.
- **Fail-Safe Offline Mode:** Encrypted Hive boxes cache credentials and checkpoint logs securely on device.
