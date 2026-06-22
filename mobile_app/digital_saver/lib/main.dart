import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/services/ble_service.dart';
import 'package:digital_saver/services/emergency_service.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/screens/home_screen.dart';
import 'package:digital_saver/screens/settings_screen.dart';
import 'package:digital_saver/screens/history_screen.dart';
import 'package:digital_saver/screens/emergency_contacts_screen.dart';
import 'package:digital_saver/i18n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();
  
  final bleService = BleService();
  final emergencyService = EmergencyService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => storageService),
        ChangeNotifierProvider(create: (_) => bleService),
        ChangeNotifierProvider(create: (_) => emergencyService),
      ],
      child: const DigitalSaverApp(),
    ),
  );
}

class DigitalSaverApp extends StatelessWidget {
  const DigitalSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<StorageService>().locale;
    
    return MaterialApp(
      title: 'Digital Saver',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/history': (_) => const HistoryScreen(),
        '/contacts': (_) => const EmergencyContactsScreen(),
      },
    );
  }
}
