/// Deterministic 31-bit identifiers for scheduled notifications.
///
/// Android and iOS identify a scheduled notification by an integer. The app
/// stores its own string ids, so they have to be reduced to an integer in a way
/// that is the same on every run: if the number changed between launches, a
/// cancelled reminder would stay scheduled because the app would be cancelling
/// a different id.
///
/// FNV-1a is used because it is short, stable across platforms and does not
/// depend on Dart's per-run string hash seed. The result is masked to 31 bits
/// and kept away from zero, both of which the platform APIs accept.
library;

/// A stable 31-bit identifier for [key].
int stableNotificationId(String key) {
  int hash = 0x811c9dc5;
  for (final int unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final int id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}
