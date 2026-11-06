/// Delivery of alarms, reminders and medication times through the phone.
///
/// The schedule itself is computed by [SchedulePlanner]; this file only talks to
/// the platform. Three rules shape it:
///
///  * **Never crash the app for a notification.** A plugin that is missing, a
///    permission that was refused or a platform without support must leave the
///    app running and the schedule intact, with the reason available to the
///    screen.
///  * **Cancel only what this app created.** The previous ids are stored, so a
///    resync does not wipe a reminder that is already showing in the tray.
///  * **Say when timing is approximate.** Android 12 and later restrict exact
///    alarms; the app asks for inexact delivery rather than the restricted
///    exact-alarm permission, so a reminder can arrive a few minutes late. The
///    screens say that rather than implying clock precision.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import 'schedule_planner.dart';
import 'storage_service.dart';

/// What one sync did, for the screen to report honestly.
class NotificationSyncResult {
  /// Create a result.
  const NotificationSyncResult({
    required this.supported,
    required this.scheduled,
    required this.cancelled,
    this.error,
    this.busy = false,
  });

  /// Whether this platform can show scheduled notifications.
  final bool supported;

  /// How many alerts are now scheduled.
  final int scheduled;

  /// How many previous alerts were cancelled first.
  final int cancelled;

  /// First failure, when something could not be scheduled.
  final String? error;

  /// Whether another sync was already running.
  final bool busy;
}

/// The app's single notification channel and scheduler.
class NotificationService {
  NotificationService._();

  /// Shared instance. Screens and startup use the same one so two syncs cannot
  /// schedule the same alert twice.
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = false;
  bool _syncing = false;
  String? _lastError;
  DateTime? _lastSyncAt;

  /// Whether the current platform has a notification implementation in the
  /// plugin this app ships.
  ///
  /// Windows, Linux and web are not supported by `flutter_local_notifications`
  /// 18, so the app says so instead of pretending a schedule will fire.
  static bool get platformSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Whether initialisation succeeded on this device.
  bool get available => _available;

  /// The last initialisation or scheduling error, if any.
  String? get lastError => _lastError;

  /// When the schedule was last written, if it has been.
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Prepare the plugin. Safe to call more than once.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!platformSupported) return;
    try {
      tz_data.initializeTimeZones();
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      // Permission is requested from the screen with an explanation, not the
      // instant the app starts.
      const DarwinInitializationSettings apple = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      );
      const InitializationSettings settings = InitializationSettings(
        android: android,
        iOS: apple,
        macOS: apple,
      );
      _available = await _plugin.initialize(settings) ?? false;
    } catch (error) {
      _lastError = '$error';
      _available = false;
    }
  }

  /// Ask the platform for permission to post notifications.
  ///
  /// Returns false when the platform has no implementation, when the person
  /// refused, or when the request itself failed.
  Future<bool> requestPermissions() async {
    await initialize();
    if (!_available) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IOSFlutterLocalNotificationsPlugin? ios =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              sound: true,
              badge: true,
            ) ??
            false;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final MacOSFlutterLocalNotificationsPlugin? macos =
            _plugin.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        return await macos?.requestPermissions(
              alert: true,
              sound: true,
              badge: true,
            ) ??
            false;
      }
    } catch (error) {
      _lastError = '$error';
    }
    return false;
  }

  /// Whether notifications are currently allowed, or null when the platform
  /// cannot answer.
  Future<bool?> notificationsEnabled() async {
    await initialize();
    if (!_available) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IOSFlutterLocalNotificationsPlugin? ios =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final NotificationsEnabledOptions? options =
            await ios?.checkPermissions();
        return options?.isEnabled;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final MacOSFlutterLocalNotificationsPlugin? macos =
            _plugin.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        final NotificationsEnabledOptions? options =
            await macos?.checkPermissions();
        return options?.isEnabled;
      }
    } catch (error) {
      _lastError = '$error';
    }
    return null;
  }

  /// Rebuild the platform schedule from stored reminders and medications.
  ///
  /// Cancels the ids this app scheduled last time, then schedules the current
  /// plan. Calling it twice in a row replaces rather than duplicates.
  Future<NotificationSyncResult> syncFromStorage({DateTime? now}) async {
    if (_syncing) {
      return const NotificationSyncResult(
        supported: true,
        scheduled: 0,
        cancelled: 0,
        busy: true,
      );
    }
    _syncing = true;
    try {
      await initialize();
      if (!_available) {
        return NotificationSyncResult(
          supported: platformSupported,
          scheduled: 0,
          cancelled: 0,
          error: _lastError ??
              (platformSupported
                  ? 'Notifications could not be started on this device.'
                  : 'This platform has no system notification support.'),
        );
      }

      final List<int> previous =
          await StorageService.scheduledNotificationIds();
      for (final int id in previous) {
        try {
          await _plugin.cancel(id);
        } catch (_) {
          // A cancel that fails is not fatal: the id is replaced below, and a
          // stale notification is better than a sync that stops halfway.
        }
      }

      final List<Reminder> reminders = await StorageService.reminders();
      final List<Medication> medications = await StorageService.medications();
      final List<ScheduledAlert> alerts = SchedulePlanner.build(
        reminders: reminders,
        medications: medications,
        from: now ?? DateTime.now(),
      );

      final List<int> scheduledIds = <int>[];
      String? firstError;
      for (final ScheduledAlert alert in alerts) {
        try {
          await _schedule(alert);
          scheduledIds.add(alert.id);
        } catch (error) {
          firstError ??= '$error';
        }
      }
      await StorageService.setScheduledNotificationIds(scheduledIds);
      _lastSyncAt = DateTime.now();
      return NotificationSyncResult(
        supported: true,
        scheduled: scheduledIds.length,
        cancelled: previous.length,
        error: firstError,
      );
    } finally {
      _syncing = false;
    }
  }

  /// Sync only when the last write is older than [maxAge].
  ///
  /// Called when the app returns to the foreground. A launch already syncs, so
  /// this exists for a process that stays alive for days.
  Future<NotificationSyncResult?> syncIfStale({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final DateTime? last = _lastSyncAt;
    if (last != null && DateTime.now().difference(last) < maxAge) return null;
    return syncFromStorage();
  }

  /// Post one notification now, so the person can check that delivery works.
  Future<bool> showPreview() async {
    await initialize();
    if (!_available) return false;
    try {
      await _plugin.show(
        1,
        'Digital Saver',
        'Notifications are working on this phone.',
        _details(vibrate: true),
      );
      return true;
    } catch (error) {
      _lastError = '$error';
      return false;
    }
  }

  Future<void> _schedule(ScheduledAlert alert) async {
    // The alert time is already a local wall-clock instant. Converting with
    // `TZDateTime.from` preserves the instant even when the timezone database
    // has not been given the device's zone name; the plugin schedules by epoch.
    final tz.TZDateTime when = tz.TZDateTime.from(alert.at, tz.local);
    await _plugin.zonedSchedule(
      alert.id,
      alert.title,
      alert.body,
      when,
      _details(vibrate: alert.vibrate),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: alert.payload,
    );
  }

  NotificationDetails _details({required bool vibrate}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'digital_saver_reminders',
        'Alarms and reminders',
        channelDescription:
            'Alarms, reminders and medication times you set in Digital Saver.',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: vibrate,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );
  }
}
