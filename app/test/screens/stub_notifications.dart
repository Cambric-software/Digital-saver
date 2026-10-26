// A stub for the notifications plugin.
//
// Settings schedules a notification, which reaches flutter_local_notifications'
// platform interface. That interface throws LateInitializationError when it has
// not been set, so the screen could not be rendered in a test at all - and the
// failure said nothing about settings, which is exactly the sort of thing that
// sends the next person looking in the wrong place.
//
// Signatures follow the plugin's own v18 API exactly; several changed between
// major versions and a mismatched override is itself a compile error worth
// having.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

/// Installs the stub for the duration of the test file.
void useStubNotifications() {
  FlutterLocalNotificationsPlatform.instance = _StubNotifications();
}

class _StubNotifications extends FlutterLocalNotificationsPlatform {
  /// Recorded so a test can assert on what the app tried to schedule.
  final List<int> scheduled = <int>[];

  // No @override on initialize: this plugin version does not declare it on the
  // platform interface, so the plugin handles initialisation itself and calling
  // here would never happen.

  Future<bool?> initialize(
    InitializationSettings settings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async =>
      true;

  // Not marked @override for the same reason as show() above.
  Future<void> zonedSchedule(
    int id,
    String title,
    String body,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTime? scheduledDate,
    required Object timezoneDetails,
    UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation =
        UILocalNotificationDateInterpretation.absoluteTime,
    String? repeatInterval,
  }) async {
    scheduled.add(id);
  }

  // Not marked @override: this plugin version declares show() on the concrete
  // platform classes rather than on this interface, so the analyzer does not
  // see it here. Settings only schedules, so this is defensive.
  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
  }) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      <PendingNotificationRequest>[];

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async =>
      null;
}