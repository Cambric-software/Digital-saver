# Digital Saver - Complete Development Guide

> **Document Version:** 1.0.0  
> **Last Updated:** July 2026  
> **Project:** Digital Saver Health Monitoring System  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## Table of Contents

1. [Development Environment](#1-development-environment)
2. [Project Setup](#2-project-setup)
3. [Code Standards](#3-code-standards)
4. [Testing](#4-testing)
5. [Debugging](#5-debugging)
6. [Performance](#6-performance)
7. [Security Best Practices](#7-security-best-practices)
8. [Deployment](#8-deployment)
9. [Maintenance](#9-maintenance)
10. [Contributing](#10-contributing)

---

## 1. Development Environment

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.24.0+ | Mobile development |
| Dart | 3.5.0+ | Language |
| Android Studio | Latest | Android development |
| Xcode | 15.0+ | iOS development (macOS only) |
| VS Code | Latest | Code editor |
| Git | Latest | Version control |
| Supabase CLI | Latest | Local development |

### Platform-Specific Requirements

#### Android Development
- Android SDK 21+ (API 21)
- Java Development Kit (JDK) 11+
- Android device or emulator for testing

#### iOS Development (macOS Only)
- Xcode 15.0+
- iOS Simulator or physical device
- Apple Developer account (for device deployment)

#### Web Development
- Chrome browser (for debugging)
- Web server for production

### Environment Variables

Create a `.env` file in the project root:

```env
# Supabase Configuration
SUPABASE_URL=https://dafgzzkerytjuvxzymnq.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_DEBUG_MODE=false

# API Keys (if needed)
GOOGLE_MAPS_API_KEY=your-maps-key
```

---

## 2. Project Setup

### Clone the Repository

```bash
# Clone the repository
git clone https://github.com/Cambric-software/Digital-saver.git
cd Digital-saver

# Install dependencies
cd app
flutter pub get
```

### Project Structure

```
Digital-saver/
├── app/                          # Flutter application
│   ├── lib/
│   │   ├── main.dart            # Entry point
│   │   ├── models/              # Data models
│   │   ├── screens/             # UI screens
│   │   ├── services/            # Business logic
│   │   └── theme/               # Theming
│   ├── android/                 # Android configuration
│   ├── ios/                     # iOS configuration
│   └── pubspec.yaml             # Dependencies
├── firmware/                     # Watch firmware
│   └── esp32/                   # ESP32 code
├── supabase/                     # Database migrations
│   └── migrations/              # SQL migrations
├── docs/                        # Documentation
└── README.md                    # Project readme
```

### Running the App

```bash
# Navigate to app directory
cd app

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode (requires signing)
flutter run --release
```

### Building for Different Platforms

```bash
# Android
flutter build apk --debug
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --debug
flutter build ios --release

# Web
flutter build web

# Windows (Windows only)
flutter build windows --release
```

---

## 3. Code Standards

### Dart Style Guide

#### File Naming
- Use `snake_case` for file names: `health_service.dart`
- Use `PascalCase` for class names: `HealthService`
- Use `camelCase` for variables and functions

#### Code Formatting
```dart
// Good
void fetchHealthData() async {
  final data = await supabase
      .from('digital_saver_health_logs')
      .select()
      .eq('user_id', userId)
      .order('recorded_at', ascending: false);
}

// Bad
void fetchHealthData() async {
  var data = await supabase.from('digital_saver_health_logs').select().eq('user_id', userId).order('recorded_at', ascending: false);
}
```

#### Widget Construction
```dart
// Use const constructors when possible
class HealthCard extends StatelessWidget {
  const HealthCard({
    super.key,
    required this.title,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title),
            Text(value),
          ],
        ),
      ),
    );
  }
}
```

### State Management with Provider

```dart
// State class
class HealthState {
  final bool isLoading;
  final HealthData? data;
  final String? error;
  
  HealthState({
    this.isLoading = false,
    this.data,
    this.error,
  });
  
  HealthState copyWith({
    bool? isLoading,
    HealthData? data,
    String? error,
  }) {
    return HealthState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

// Provider
class HealthProvider extends ChangeNotifier {
  HealthState _state = HealthState();
  
  HealthState get state => _state;
  
  Future<void> fetchData() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    try {
      final data = await _fetchDataFromServer();
      _state = HealthState(data: data);
    } catch (e) {
      _state = HealthState(error: e.toString());
    }
    
    notifyListeners();
  }
}
```

### Error Handling

```dart
// Use Result type for error handling
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

// Usage
Future<Result<HealthData>> fetchHealthData() async {
  try {
    final data = await api.getHealthData();
    return Success(data);
  } catch (e) {
    return Failure('Failed to fetch data: $e');
  }
}
```

---

## 4. Testing

### Unit Tests

```dart
// test/health_analysis_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_saver/services/health_analysis_service.dart';

void main() {
  group('HealthAnalysisService', () {
    test('calculates health score correctly', () {
      final service = HealthAnalysisService();
      final data = HealthData(
        heartRate: 72,
        spO2: 98,
        systolicBp: 120,
        diastolicBp: 80,
      );
      
      final score = service.calculateHealthScore(data);
      
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
    
    test('classifies blood pressure correctly', () {
      final service = HealthAnalysisService();
      
      expect(
        service.classifyBloodPressure(115, 75),
        equals('Normal'),
      );
      expect(
        service.classifyBloodPressure(140, 90),
        equals('High Stage 2'),
      );
    });
  });
}
```

### Widget Tests

```dart
// test/health_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_saver/widgets/health_card.dart';

void main() {
  testWidgets('HealthCard displays title and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HealthCard(
          title: 'Heart Rate',
          value: '72 BPM',
        ),
      ),
    );
    
    expect(find.text('Heart Rate'), findsOneWidget);
    expect(find.text('72 BPM'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// test/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('complete auth flow', (tester) async {
    // Launch app
    await tester.pumpWidget(const DigitalSaverApp());
    
    // Enter credentials
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    
    // Tap sign in
    await tester.tap(find.byKey(const Key('sign_in_button')));
    
    // Wait for navigation
    await tester.pumpAndSettle();
    
    // Verify we're on the dashboard
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/health_analysis_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

---

## 5. Debugging

### Debugging with VS Code

Create a `.vscode/launch.json` file:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Debug)",
      "type": "dart",
      "request": "launch",
      "program": "app/lib/main.dart",
      "cwd": "app"
    },
    {
      "name": "Flutter (Profile)",
      "type": "dart",
      "request": "launch",
      "program": "app/lib/main.dart",
      "cwd": "app",
      "flutterMode": "profile"
    }
  ]
}
```

### Logging

```dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }
}
```

### Common Debug Tasks

```bash
# View Flutter doctor output
flutter doctor -v

# Check for issues
flutter analyze

# Fix automatically
flutter analyze --fix

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 6. Performance

### Performance Tips

1. **Use const widgets** where possible
2. **Avoid rebuilding entire widget trees** with `Selector`
3. **Cache expensive computations**
4. **Lazy load data** when possible
5. **Use `RepaintBoundary`** around complex widgets

### Performance Example

```dart
// Bad: Rebuilds on any change to ble
Consumer<BleService>(
  builder: (context, ble, child) {
    return Text('${ble.healthData.heartRate}');
  },
);

// Good: Only rebuilds when heartRate changes
Selector<BleService, int>(
  selector: (_, ble) => ble.healthData.heartRate,
  builder: (context, hr, child) {
    return Text('$hr BPM');
  },
);
```

### Performance Monitoring

```dart
// Use Performance overlay
// Run with: flutter run --profile

// Or programmatically
import 'package:flutter/perf.dart';

void monitorPerformance() {
  final FlutterTimeline timeline = FlutterTimeline.now();
  // Take snapshot and analyze
}
```

---

## 7. Security Best Practices

### Secure Storage

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

### Input Validation

```dart
class InputValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }
  
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>]'), '')
        .trim();
  }
}
```

### API Security

```dart
class ApiSecurity {
  // Never log sensitive data
  static void logRequest(String endpoint, Map<String, dynamic> data) {
    // Remove sensitive fields before logging
    final safeData = Map<String, dynamic>.from(data);
    safeData.remove('password');
    safeData.remove('token');
    safeData.remove('apiKey');
    
    AppLogger.debug('API Request: $endpoint - $safeData');
  }
  
  // Validate all user input
  static bool validateInput(String input, String type) {
    switch (type) {
      case 'email':
        return InputValidator.isValidEmail(input);
      case 'phone':
        return InputValidator.isValidPhone(input);
      default:
        return input.isNotEmpty;
    }
  }
}
```

---

## 8. Deployment

### Android Deployment

1. **Configure signing**
```bash
# Generate signing key
keytool -genkey -v -keystore digital_saver_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias digital_saver

# Configure in android/app/build.gradle
android {
  signingConfigs {
    release {
      keyAlias 'digital_saver'
      keyPassword 'your-key-password'
      storeFile file('digital_saver_key.jks')
      storePassword 'your-store-password'
    }
  }
}
```

2. **Build release APK**
```bash
flutter build apk --release
```

3. **Upload to Play Store**
```bash
# Create app bundle
flutter build appbundle --release

# Upload using Play Console or CLI
# (Requires google-services.json from Firebase)
```

### Web Deployment

```bash
# Build for production
flutter build web

# Deploy to GitHub Pages
# Copy build/web/ contents to gh-pages branch
```

### GitHub Actions Workflow

```yaml
# .github/workflows/release.yml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: cd app && flutter pub get
      - run: cd app && flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: app/build/app/outputs/flutter-apk/app-release.apk
```

---

## 9. Maintenance

### Regular Maintenance Tasks

1. **Update dependencies**
```bash
flutter pub upgrade
flutter pub outdated
```

2. **Run analysis**
```bash
flutter analyze
dart analyze
```

3. **Update documentation**
- Keep README.md updated
- Document breaking changes
- Update migration guides

4. **Monitor errors**
- Use crash reporting (e.g., Sentry)
- Review error logs regularly
- Fix critical issues promptly

### Version Management

```bash
# Update version in pubspec.yaml
# Format: major.minor.patch+build

# Android version code (auto-incremented)
# iOS version (manually updated)

# Create release tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Database Migrations

```sql
-- supabase/migrations/005_new_feature.sql

-- Add new column
ALTER TABLE digital_saver_health_logs 
ADD COLUMN IF NOT EXISTS new_metric REAL;

-- Create index
CREATE INDEX IF NOT EXISTS idx_new_metric 
ON digital_saver_health_logs(new_metric);

-- Add RLS policy
DROP POLICY IF EXISTS "Users can view new_metric" 
ON digital_saver_health_logs;
CREATE POLICY "Users can view new_metric" 
ON digital_saver_health_logs
FOR SELECT USING (auth.uid() = user_id);
```

---

## 10. Contributing

### Branch Strategy

```
main          - Production-ready code
├── develop   - Development integration
│   ├── feature/xyz  - Feature development
│   ├── fix/abc     - Bug fixes
│   └── refactor/pqr - Code refactoring
└── hotfix/   - Emergency production fixes
```

### Commit Messages

```
feat: add blood pressure tracking
fix: resolve auth loading issue
docs: update API documentation
style: format code with dartfmt
refactor: simplify health score calculation
test: add unit tests for HRV analysis
chore: update dependencies
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request
7. Wait for code review
8. Address feedback
9. Merge when approved

### Code Review Checklist

- [ ] Code follows style guide
- [ ] Tests pass
- [ ] No new warnings
- [ ] Documentation updated
- [ ] No security issues
- [ ] Performance is acceptable
- [ ] Edge cases handled

---

## Appendix A: Useful Commands

```bash
# Development
flutter run
flutter run -d <device>
flutter analyze
flutter test

# Build
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
flutter build web

# Maintenance
flutter pub get
flutter pub upgrade
flutter clean
dart pub outdated

# Git
git status
git branch
git checkout -b feature/xyz
git add .
git commit -m "feat: add feature xyz"
git push origin feature/xyz
```

---

## Appendix B: Resources

| Resource | URL |
|----------|-----|
| Flutter Docs | https://flutter.dev/docs |
| Dart Docs | https://dart.dev/guides |
| Supabase Docs | https://supabase.com/docs |
| Provider Package | https://pub.dev/packages/provider |
| flutter_blue_plus | https://pub.dev/packages/flutter_blue_plus |

---

**Document Version:** 1.0.0  
**Last Updated:** July 2026  
**Author:** Cambric Engineering Team  
**Copyright © 2026 Cambric. All Rights Reserved.**
