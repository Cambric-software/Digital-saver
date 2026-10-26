/// The clock-based half of the old "dynamic theme" idea, and nothing else.
///
/// This file used to call itself a dynamic theme engine: it owned a
/// [WeatherCondition] enum, fetched nothing, and then invented the weather from
/// the month (`_inferWeatherFromTime`) so that a "rainy" palette could be
/// applied on a sunny day. It also held eight full colour palettes, a
/// one-minute timer and a greeting. Nothing imported it.
///
/// Weather is gone, along with the HTTP imports and the invented inference.
/// What remains is the one part that was true: the local hour. [LightChoice]
/// says whether a person is in daylight or after dark, and [ThemeService] uses
/// that answer only when the person has switched on "Dim after dark".
library;

/// The two lighting choices the local clock can produce.
enum LightChoice {
  /// Daytime. The theme the person picked is used unchanged.
  light('Light'),

  /// Night-time. The dark theme is used if "Dim after dark" is on.
  dim('Dim');

  const LightChoice(this.label);

  /// A word for the Settings screen.
  final String label;
}

/// Maps a local hour to a light or dim choice.
///
/// The boundaries are deliberately simple and public so a test can state them:
/// after dark starts at 20:00 and daylight returns at 07:00. This is not a
/// sunrise calculation and does not pretend to know the weather or the season.
class DynamicThemeService {
  /// Create the service, optionally with a clock for tests.
  DynamicThemeService({DateTime Function()? clock}) : _clock = clock;

  final DateTime Function()? _clock;

  /// The hour at which dimming begins.
  static const int dimStartHour = 20;

  /// The hour at which dimming ends.
  static const int dimEndHour = 7;

  /// The choice for a local [hour], 0 to 23.
  static LightChoice choiceForHour(int hour) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be between 0 and 23');
    }
    return hour >= dimStartHour || hour < dimEndHour
        ? LightChoice.dim
        : LightChoice.light;
  }

  /// The local time this service is using.
  ///
  /// Exposed so a caller can schedule a wake-up at the next boundary using the
  /// same clock the choice was computed from.
  DateTime get now => (_clock ?? DateTime.now)();

  /// The next local time the choice changes after [time].
  ///
  /// Before 07:00 that is this morning's boundary; between 07:00 and 20:00 it
  /// is this evening's; after 20:00 it is tomorrow morning's.
  DateTime nextChangeAfter(DateTime time) {
    final DateTime morning =
        DateTime(time.year, time.month, time.day, dimEndHour);
    final DateTime evening =
        DateTime(time.year, time.month, time.day, dimStartHour);
    if (time.isBefore(morning)) return morning;
    if (time.isBefore(evening)) return evening;
    return DateTime(time.year, time.month, time.day + 1, dimEndHour);
  }

  /// The choice for the local time now.
  LightChoice get currentChoice => choiceForHour(now.hour);

  /// Whether the local clock currently asks for dimming.
  bool get isAfterDark => currentChoice == LightChoice.dim;
}
