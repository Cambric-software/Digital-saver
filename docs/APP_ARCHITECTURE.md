# Digital Saver - Complete Application Architecture

> **Document Version:** 1.0.0  
> **Last Updated:** July 2026  
> **Project:** Digital Saver Health Monitoring System  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Layers](#2-architecture-layers)
3. [App Module Structure](#3-app-module-structure)
4. [Service Architecture](#4-service-architecture)
5. [Data Flow](#5-data-flow)
6. [State Management](#6-state-management)
7. [Screen Architecture](#7-screen-architecture)
8. [Widget Components](#8-widget-components)
9. [Theme & Styling](#9-theme--styling)
10. [Navigation](#10-navigation)
11. [Error Handling](#11-error-handling)
12. [Performance Optimization](#12-performance-optimization)

---

## 1. System Overview

Digital Saver is a smartwatch-based health monitoring system consisting of three main components:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DIGITAL SAVER ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌─────────────────┐    BLE    ┌─────────────────────────────┐    │
│   │  ONYX WATCH      │◄────────►│  FLUTTER MOBILE APP        │    │
│   │                  │           │                             │    │
│   │  ESP32 MCU       │           │  Android / iOS / Web        │    │
│   │  MAX30102 PPG    │           │                             │    │
│   │  MPU6050 Accel  │           │  Supabase Backend           │    │
│   │  OLED Display    │           │  (dafgzzkerytjuvxzymnq)    │    │
│   └─────────────────┘           └─────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Mobile Framework** | Flutter | 3.24.0+ | Cross-platform development |
| **Language** | Dart | 3.5.0+ | Type-safe mobile development |
| **State Management** | Provider | 6.1.2+ | Reactive state management |
| **Backend** | Supabase | 2.x | Auth, Database, Realtime |
| **Bluetooth** | flutter_blue_plus | 1.31.15+ | BLE device communication |
| **Charts** | fl_chart | 0.69.0+ | Data visualization |
| **Local Storage** | shared_preferences | 2.3.2+ | Device data persistence |
| **HTTP** | dio / http | Latest | API communication |

---

## 2. Architecture Layers

### Layer Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Screens (Material Design 3)                      │   │
│  │ • DashboardScreen  • HeartScreen                 │   │
│  │ • BpScreen        • ActivityScreen               │   │
│  │ • SleepScreen     • SettingsScreen               │   │
│  │ • AuthScreen                                    │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Widgets                                          │   │
│  │ • Health Cards  • Charts  • Buttons               │   │
│  │ • Dialogs       • Lists   • Custom Components    │   │
│  └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                    BUSINESS LOGIC LAYER                  │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Providers (ChangeNotifier)                       │   │
│  │ • AuthProvider  • BleService                     │   │
│  │ • HealthProvider  • SettingsProvider            │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Services                                          │   │
│  │ • CambricAuth  • HealthAnalysisService            │   │
│  │ • EmergencyService  • StorageService             │   │
│  └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                      DATA LAYER                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Repositories                                     │   │
│  │ • AuthRepository  • HealthRepository             │   │
│  │ • UserProfileRepository                         │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Data Sources                                     │   │
│  │ • Supabase (Remote)                             │   │
│  │ • SharedPreferences (Local)                     │   │
│  │ • BLE Device (Hardware)                         │   │
│  └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                   PLATFORM LAYER                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Platform Integration                             │   │
│  │ • Bluetooth Low Energy                         │   │
│  │ • SMS / Phone Calls                             │   │
│  │ • Location Services                             │   │
│  │ • Notifications                                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 3. App Module Structure

### Directory Structure

```
app/
├── lib/
│   ├── main.dart                      # Entry point, app bootstrap
│   │
│   ├── models/
│   │   └── health_models.dart         # Health data models
│   │
│   ├── screens/
│   │   ├── auth_screen.dart           # Login/Register
│   │   ├── dashboard_screen.dart      # Main dashboard
│   │   ├── heart_screen.dart          # Heart rate & HRV
│   │   ├── bp_screen.dart            # Blood pressure
│   │   ├── activity_screen.dart       # Steps & activity
│   │   ├── sleep_screen.dart          # Sleep tracking
│   │   └── settings_screen.dart       # App settings
│   │
│   ├── services/
│   │   ├── cambric_auth_service_v2.dart  # Auth provider
│   │   ├── ble_service.dart              # Bluetooth service
│   │   ├── emergency_service.dart        # SOS handling
│   │   ├── health_analysis_service.dart # Health algorithms
│   │   ├── health_analysis_service_v2.dart
│   │   ├── smart_data_service.dart       # Data management
│   │   ├── storage_service.dart          # Local persistence
│   │   └── user_profile_service.dart     # Profile CRUD
│   │
│   └── theme/
│       └── app_theme.dart              # Material 3 theming
│
├── pubspec.yaml                       # Dependencies
└── android/                          # Android configuration
```

### Key Files Description

| File | Purpose | Key Classes |
|------|---------|-------------|
| `main.dart` | App bootstrap, Supabase init | `DigitalSaverApp`, `SplashScreen`, `MainNav` |
| `auth_screen.dart` | User authentication | `AuthScreen` |
| `dashboard_screen.dart` | Health overview | `DashboardScreen` |
| `health_models.dart` | Data models | `HealthData`, `UserProfile`, `EmergencyContact` |
| `ble_service.dart` | BLE communication | `BleService`, `BleState` |
| `cambric_auth_service_v2.dart` | Auth management | `AuthProvider`, `CambricAuth` |

---

## 4. Service Architecture

### Service Dependency Graph

```
                    ┌─────────────────┐
                    │   AuthProvider   │
                    │ (cambric_auth)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Main App      │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
┌────────▼────────┐  ┌────────▼────────┐  ┌───────▼───────┐
│   BleService   │  │ StorageService │  │EmergencyService│
│                │  │               │  │               │
│ • scan()       │  │ • load()      │  │ • sendSOS()   │
│ • connect()    │  │ • save()      │  │ • call()      │
│ • readData()   │  │ • clear()     │  │ • smsAlert()  │
└────────┬────────┘  └───────┬───────┘  └───────────────┘
         │                    │
         │              ┌─────▼─────┐
         │              │ Supabase  │
         │              │ (Remote)  │
         │              └───────────┘
         │
┌────────▼────────┐
│  Onyx Watch    │
│  (BLE Device)  │
└────────────────┘
```

### Core Services

#### CambricAuthService (Auth)

```dart
class CambricAuth {
  // Singleton Supabase client
  static SupabaseClient get client => CambricAuth.client;
  
  // Auth state
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static Stream<AuthState> get authState => client.auth.onAuthStateChange;
}

class AuthProvider extends ChangeNotifier {
  // State
  User? user;
  CambricUserProfile? profile;
  bool loading = false;
  String? error;
  
  // Methods
  Future<bool> signIn({email, password});
  Future<bool> signUp({email, password, displayName});
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<bool> updateProfile({displayName, additionalData});
}
```

#### BleService (Bluetooth)

```dart
enum BleState { disconnected, scanning, connecting, connected }

class BleService extends ChangeNotifier {
  BleState state = BleState.disconnected;
  
  // Methods
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Stream<HealthData> get healthStream;
}
```

#### HealthAnalysisService

```dart
class HealthAnalysisService {
  // Health score calculation
  int calculateHealthScore(HealthData data);
  
  // HRV analysis
  Map<String, double> analyzeHRV(List<int> rrIntervals);
  
  // Blood pressure classification
  String classifyBloodPressure(int systolic, int diastolic);
  
  // AFib detection
  bool detectAFib(List<int> rrIntervals);
}
```

---

## 5. Data Flow

### Health Data Flow

```
┌──────────┐     BLE      ┌──────────┐    Parse    ┌──────────────┐
│ Onyx     │────────────►│ BleService│────────────►│ HealthData   │
│ Watch    │   1Hz JSON  │           │             │ Model        │
└──────────┘             └──────────┘             └──────┬───────┘
                                                          │
                         ┌────────────────────────────────┤
                         │                                │
                  ┌──────▼───────┐              ┌────────▼────────┐
                  │ HealthAnalysis│              │  StorageService │
                  │   Service     │              │                 │
                  │               │              │ (SharedPrefs)   │
                  │ • Score calc │              │                 │
                  │ • HRV anal   │              └────────┬────────┘
                  │ • Alert prep │                       │
                  └──────┬───────┘                       │
                         │                               │
                         └───────────┬───────────────────┘
                                     │
                             ┌───────▼───────┐
                             │   Supabase    │
                             │   (Cloud)     │
                             │               │
                             │ digital_saver_│
                             │ _health_logs │
                             └───────────────┘
```

### Authentication Flow

```
┌─────────┐     Sign In      ┌─────────┐    OAuth    ┌─────────────┐
│ User    │────────────────►│ AuthScreen│──────────►│ Supabase    │
│         │   email/pass    │           │            │ Auth        │
└─────────┘                 └─────────┘            └──────┬──────┘
                                                            │
                         ┌──────────────────────────────────┘
                         │
                  ┌──────▼───────┐
                  │ AuthProvider │
                  │               │
                  │ • Session     │
                  │ • Profile     │
                  │ • Listeners  │
                  └──────┬───────┘
                         │
              ┌──────────┴──────────┐
              │                     │
       ┌──────▼──────┐      ┌───────▼───────┐
       │ MainNav     │      │ digital_saver_│
       │ (Dashboard) │      │ _user_profiles│
       └─────────────┘      └───────────────┘
```

---

## 6. State Management

### Provider Architecture

```dart
// main.dart
MultiProvider(
  providers: [
    // BLE service - manages watch connection
    ChangeNotifierProvider(create: (_) => BleService()),
    
    // Auth provider - manages user session
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: DigitalSaverApp(),
)
```

### State Flow

```
┌─────────────────────────────────────────────────────────┐
│                     STATE MANAGEMENT                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐         ┌──────────────────────────┐ │
│  │ AuthProvider │         │ BleService                │ │
│  ├──────────────┤         ├──────────────────────────┤ │
│  │ _user       │         │ _state                   │ │
│  │ _profile    │         │ _device                  │ │
│  │ _loading    │         │ _healthData             │ │
│  │ _error      │         │ _connection              │ │
│  └──────┬──────┘         └───────────┬──────────────┘ │
│         │                             │                  │
│         │              ┌──────────────┴──────────────┐ │
│         │              │                             │ │
│         │        ┌─────▼─────────┐            ┌──────▼──────┐
│         │        │ HealthData    │            │ Emergency    │
│         │        │ Provider     │            │ Service      │
│         │        └──────────────┘            └─────────────┘
│         │
│  ┌─────▼──────────────────────────────────────────────┐ │
│  │               UI SCREENS                           │ │
│  │                                                       │ │
│  │  DashboardScreen  ← watches → BleService             │ │
│  │  HeartScreen     ← watches → AuthProvider           │ │
│  │  SettingsScreen ← watches → AuthProvider           │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 7. Screen Architecture

### Screen Hierarchy

```
App
├── SplashScreen (initial loading)
│   └── AuthScreen (if not authenticated)
│       └── MainNav (if authenticated)
│           ├── DashboardScreen (index 0)
│           ├── HeartScreen (index 1)
│           ├── BpScreen (index 2)
│           ├── ActivityScreen (index 3)
│           ├── SleepScreen (index 4)
│           └── SettingsScreen (index 5)
```

### Screen Specifications

#### DashboardScreen
- **Purpose:** Health overview and watch status
- **Key Widgets:** Health score ring, vitals grid, battery indicator
- **State:** Watches `BleService` for live data

#### HeartScreen  
- **Purpose:** Detailed heart rate and HRV analysis
- **Key Widgets:** BPM hero display, HRV metrics, zone indicator
- **Data:** Heart rate, RMSSD, SDNN, pNN50, stress index

#### BpScreen
- **Purpose:** Blood pressure monitoring
- **Key Widgets:** BP gauge, MAP display, AHA classification
- **Data:** Systolic, diastolic, MAP, pulse pressure

#### ActivityScreen
- **Purpose:** Daily activity tracking
- **Key Widgets:** Step counter, calorie burn, distance
- **Goals:** 10,000 steps daily

#### SleepScreen
- **Purpose:** Sleep quality analysis
- **Key Widgets:** Sleep duration, stage breakdown (donut chart)
- **Stages:** Deep, light, REM, awake

#### SettingsScreen
- **Purpose:** App configuration and profile
- **Sections:** Account, profile, device, emergency contacts, downloads

---

## 8. Widget Components

### Common Widgets

| Widget | File | Purpose |
|--------|------|---------|
| `HealthScoreRing` | dashboard_screen.dart | Circular progress for health score |
| `VitalCard` | dashboard_screen.dart | Card for displaying vital metrics |
| `BpmDisplay` | heart_screen.dart | Large BPM number with animation |
| `HrvPanel` | heart_screen.dart | HRV metrics display |
| `BpGauge` | bp_screen.dart | Blood pressure gauge visualization |
| `StepProgress` | activity_screen.dart | Step progress ring |
| `SleepChart` | sleep_screen.dart | Sleep stage donut chart |

### Widget Structure Example

```dart
class HealthScoreRing extends StatelessWidget {
  final int score;
  final double size;
  
  const HealthScoreRing({
    super.key,
    required this.score,
    this.size = 150,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 12,
            backgroundColor: Colors.grey[200],
          ),
          // Score ring
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 12,
            color: _getScoreColor(score),
          ),
          // Score text
          Text(
            '$score',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
```

---

## 9. Theme & Styling

### Theme Configuration

```dart
// app_theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      fontFamily: 'Inter',
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
    );
  }
}
```

### Color Palette

| Name | Light Mode | Dark Mode | Usage |
|------|------------|-----------|-------|
| Primary | #2563EB | #3B82F6 | Buttons, links |
| Secondary | #7C3AED | #8B5CF6 | Accents |
| Success | #22C55E | #4ADE80 | Positive states |
| Warning | #F59E0B | #FBBF24 | Caution states |
| Error | #DC2626 | #F87171 | Error states |
| Background | #FFFFFF | #121212 | Screen bg |
| Surface | #F8FAFC | #1E1E1E | Cards |

---

## 10. Navigation

### Navigation Implementation

```dart
class MainNav extends StatefulWidget {
  const MainNav({super.key});
  
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  
  static const _screens = [
    DashboardScreen(),
    HeartScreen(),
    BpScreen(),
    ActivityScreen(),
    SleepScreen(),
    SettingsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Heart',
          ),
          // ... more destinations
        ],
      ),
    );
  }
}
```

---

## 11. Error Handling

### Error Types

| Error Type | Handling | User Message |
|------------|----------|--------------|
| `AuthException` | Show error in UI | "Invalid email or password" |
| `BluetoothException` | Retry connection | "Watch disconnected" |
| `NetworkException` | Show offline mode | "No internet connection" |
| `StorageException` | Fallback to memory | "Couldn't save data locally" |

### Error Handler Pattern

```dart
try {
  await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
} on AuthException catch (e) {
  _error = _mapAuthError(e.message);
} on TimeoutException {
  _error = 'Connection timed out';
} catch (e) {
  _error = 'An unexpected error occurred';
}
```

---

## 12. Performance Optimization

### Best Practices

1. **State Management**
   - Use `const` widgets where possible
   - Minimize rebuilds with `Selector` or `Consumer`

2. **Bluetooth Data**
   - Process BLE data off main thread
   - Batch database writes

3. **Charts**
   - Use `RepaintBoundary` around chart widgets
   - Limit data points displayed (last 24 hours)

4. **Images**
   - Use `cached_network_image` for avatars
   - Lazy load images in lists

### Optimization Example

```dart
// Instead of watching entire provider
Widget build(BuildContext context) {
  return Consumer<BleService>(
    builder: (context, ble, child) {
      return Text('${ble.healthData.heartRate}');
    },
  );
}

// Use Selector for specific properties
Widget build(BuildContext context) {
  return Selector<BleService, int>(
    selector: (_, ble) => ble.healthData.heartRate,
    builder: (context, hr, _) => Text('$hr BPM'),
  );
}
```

---

## Appendix A: Import Dependencies

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
```

---

**Document Version:** 1.0.0  
**Last Updated:** July 2026  
**Author:** Cambric Engineering Team  
**Copyright © 2026 Cambric. All Rights Reserved.**
