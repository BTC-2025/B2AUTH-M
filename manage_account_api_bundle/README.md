# Manage Account Module Bundle

Complete, portable, and production-ready **"Manage Account"** Flutter module with full backend API integration, multi-account session management, 7-tab account management screen, and top-bar account switcher menu card.

---

## 📂 Bundle Contents

```
manage_account_api_bundle/
├── screens/
│   └── manage_account_screen.dart   # Complete 7-tab Manage Account screen
├── widgets/
│   └── account_menu_card.dart       # Profile dropdown card with account switching & sign-out
├── core/
│   ├── network/
│   │   ├── api_client.dart          # HTTP client with auto 401 refresh & uniform error handling
│   │   ├── api_exception.dart       # Typed API error model
│   │   └── token_service.dart       # Cross-platform persistent token and session store
│   ├── theme/
│   │   ├── colors.dart              # Theme palette constants (light & dark)
│   │   └── neumorphic.dart          # Neumorphic card decoration helpers
│   └── widgets/
│       └── avatar_widget.dart       # Dynamic photo & initial avatar with fallback
├── data/
│   ├── providers/
│   │   ├── account_provider.dart    # Riverpod state: active account, switch account, sign out
│   │   └── settings_provider.dart   # Riverpod state: user settings, 2FA, signatures
│   └── repositories/
│       ├── auth_repository.dart     # Auth, login, logout, multi-account sessions
│       ├── user_repository.dart     # Profile sync, sub-IDs, connected emails, devices
│       ├── settings_repository.dart # Settings GET/PATCH, 2FA setup/verify, signatures
│       ├── storage_repository.dart  # Storage quota & mailbox usage
│       └── subscription_repository.dart # Plans, active subscriptions, billing
├── models/
│   ├── account_model.dart
│   ├── user_model.dart
│   ├── user_settings_model.dart
│   ├── two_factor_model.dart
│   ├── signature_model.dart
│   └── blocked_contact_model.dart
├── API_INTEGRATION_GUIDE.md         # Full endpoint-by-endpoint reference
└── PROMPT_FOR_OTHER_PROJECT.txt     # AI prompt to auto-integrate this bundle in another project
```

---

## 🚀 Quick Setup in Target Project

### 1. Add Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  http: ^1.2.2
  file_picker: ^11.0.3 # or ^8.0.0+
  http_parser: any
```

### 2. Wrap App with `ProviderScope` (`main.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 3. Open the Manage Account Screen
```dart
import 'package:flutter/material.dart';
import 'manage_account_api_bundle/screens/manage_account_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ManageAccountScreen(initialTab: 0),
  ),
);
```

### 4. Open the Account Menu Card
```dart
import 'package:flutter/material.dart';
import 'manage_account_api_bundle/widgets/account_menu_card.dart';

AccountMenuCard(
  onClose: () => Navigator.pop(context),
  onAddAccount: () => Navigator.pushNamed(context, '/login'),
  onSignOut: () => Navigator.pushReplacementNamed(context, '/login'),
)
```

---

## ✅ Quality & Compatibility
- **Static Analysis**: Verified with `dart analyze` — **0 issues found across all 21 files**.
- **Cross-Platform**: Fully works on macOS, Windows, Linux, Android, iOS, and Web.
- **Self-Contained**: No external dependency on non-standard project folders or unmaintained packages.
