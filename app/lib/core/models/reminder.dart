/// An alarm or reminder the person set on their own phone.
///
/// The app previously had no alarm or reminder model at all: the watch firmware
/// mentions an alarm characteristic, but nothing in the phone app ever set one,
/// and the medication list was explicitly documented as having no schedule and
/// no reminder. This model is the missing piece. It stores only what the person
/// entered â€” a time, the days it repeats, and an optional note â€” and computes
/// the next real occurrence from the device clock.
///
/// The occurrence maths lives here rather than in a screen so it can be tested
/// without a widget tree, a platform plugin or a clock. [nextOccurrences] is
/// pure: give it a moment and it returns the same instants every time.
library;

/// What the reminder is for. The kind changes the icon and wording only; every
/// kind is delivered the same way.
enum ReminderKind {
  /// A wake-up or one-off alarm.
  alarm('Alarm'),

  /// A general reminder such as a stretch break or a call.
  reminder('Reminder'),

  /// A prompt to drink water.
  hydration('Water');

  const ReminderKind(this.label);

  /// Wording shown in the app.
  final String label;

  /// Parse a stored kind, falling back to [ReminderKind.reminder].
  static ReminderKind fromName(Object? value) {
    for (final ReminderKind kind in ReminderKind.values) {
      if (kind.name == value) return kind;
    }
    return ReminderKind.reminder;
  }
}

/// One alarm or reminder.
class Reminder {
  /// Create a reminder.
  const Reminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.days = const <int>[],
    this.date = '',
    this.kind = ReminderKind.reminder,
    this.body = '',
    this.enabled = true,
    this.vibrate = true,
  });

  /// Stable identifier used to cancel and replace scheduled notifications.
  final String id;

  /// Short label, e.g. `Wake up`.
  final String title;

  /// Hour in 24-hour local time, 0 to 23.
  final int hour;

  /// Minute, 0 to 59.
  final int minute;

  /// Weekdays it repeats on, 1 (Monday) to 7 (Sunday). Empty means a one-off
  /// reminder on [date].
  final List<int> days;

  /// For a one-off reminder, the local day as `yyyy-mm-dd`. Empty when the
  /// reminder repeats weekly.
  final String date;

  /// What it is for.
  final ReminderKind kind;

  /// Optional longer text shown in the notification.
  final String body;

  /// Whether it is currently scheduled.
  final bool enabled;

  /// Whether the notification should vibrate.
  final bool vibrate;

  /// Whether this repeats on at least one weekday.
  bool get repeats => days.isNotEmpty;

  /// The local time of day this reminder is set for.
  DateTime timeOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  /// The one-off date, or null when it is not a valid stored date.
  DateTime? get onceDate {
    if (repeats || date.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// The next occurrence strictly after [from].
  ///
  /// Returns an empty list when the reminder is disabled, when a one-off date
  /// has passed, or when [limit] is zero. Weekly reminders are searched for
  /// [horizonDays] days, which is enough for every day selection to occur at
  /// least once.
  List<DateTime> nextOccurrences(
    DateTime from, {
    int horizonDays = 30,
    int limit = 30,
  }) {
    if (!enabled || limit <= 0 || horizonDays < 0) return <DateTime>[];
    if (days.isEmpty) {
      final DateTime? once = onceDate;
      if (once == null) return <DateTime>[];
      final DateTime at = timeOn(once);
      return at.isAfter(from) ? <DateTime>[at] : <DateTime>[];
    }
    final List<DateTime> found = <DateTime>[];
    for (int offset = 0;
        offset <= horizonDays && found.length < limit;
        offset++) {
      final DateTime day = DateTime(from.year, from.month, from.day + offset);
      if (!days.contains(day.weekday)) continue;
      final DateTime at = timeOn(day);
      if (at.isAfter(from)) found.add(at);
    }
    return found;
  }

  /// The first occurrence after [from], or null when there is none.
  DateTime? nextOccurrence(DateTime from, {int horizonDays = 30}) {
    final List<DateTime> found =
        nextOccurrences(from, horizonDays: horizonDays, limit: 1);
    return found.isEmpty ? null : found.first;
  }

  /// A short sentence describing the repeat pattern.
  String get repeatLabel {
    if (days.isEmpty) {
      final DateTime? once = onceDate;
      if (once == null) return 'Once';
      return 'Once on ${formatDay(once)}';
    }
    if (days.length == 7) return 'Every day';
    final Set<int> set = days.toSet();
    if (set.length == 5 && set.containsAll(const <int>[1, 2, 3, 4, 5])) {
      return 'Weekdays';
    }
    if (set.length == 2 && set.containsAll(const <int>[6, 7])) {
      return 'Weekends';
    }
    final List<int> sorted = days.toList()..sort();
    return sorted.map(shortDayName).join(', ');
  }

  /// `08:05` for the stored time.
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Copy with selected fields replaced.
  Reminder copyWith({
    String? id,
    String? title,
    int? hour,
    int? minute,
    List<int>? days,
    String? date,
    ReminderKind? kind,
    String? body,
    bool? enabled,
    bool? vibrate,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      enabled: enabled ?? this.enabled,
      vibrate: vibrate ?? this.vibrate,
    );
  }

  /// Read from stored JSON, or null when the object is not a usable reminder.
  static Reminder? fromJson(Object? value) {
    if (value is! Map) return null;
    final Object? id = value['id'];
    final Object? title = value['title'];
    final Object? hour = value['hour'];
    final Object? minute = value['minute'];
    if (id is! String || id.trim().isEmpty) return null;
    if (title is! String || title.trim().isEmpty) return null;
    if (hour is! int || hour < 0 || hour > 23) return null;
    if (minute is! int || minute < 0 || minute > 59) return null;

    final List<int> days = <int>[];
    final Object? rawDays = value['days'];
    if (rawDays is List) {
      for (final Object? day in rawDays) {
        if (day is int && day >= 1 && day <= 7 && !days.contains(day)) {
          days.add(day);
        }
      }
      days.sort();
    }

    final Object? rawDate = value['date'];
    final String date = rawDate is String ? rawDate.trim() : '';
    if (days.isEmpty && DateTime.tryParse(date) == null) return null;

    final Object? rawBody = value['body'];
    final Object? rawEnabled = value['enabled'];
    final Object? rawVibrate = value['vibrate'];

    return Reminder(
      id: id.trim(),
      title: title.trim(),
      hour: hour,
      minute: minute,
      days: days,
      date: days.isEmpty ? date : '',
      kind: ReminderKind.fromName(value['kind']),
      body: rawBody is String ? rawBody.trim() : '',
      enabled: rawEnabled is bool ? rawEnabled : true,
      vibrate: rawVibrate is bool ? rawVibrate : true,
    );
  }

  /// Write as stored JSON.
  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'days': days,
        'date': repeats ? '' : date,
        'kind': kind.name,
        'body': body,
        'enabled': enabled,
        'vibrate': vibrate,
      };

  /// A new identifier that does not repeat within the same microsecond.
  static String newId([DateTime? now]) {
    final int stamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
    return 'r${stamp.toRadixString(36)}';
  }
}

/// `Mon` â€¦ `Sun` for a weekday number.
String shortDayName(int weekday) {
  const List<String> names = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  if (weekday < 1 || weekday > 7) return '';
  return names[weekday - 1];
}

/// `Mon 3 Nov` for a date, without pulling in locale data.
String formatDay(DateTime value) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${shortDayName(value.weekday)} ${value.day} ${months[value.month - 1]}';
}
