/// Android/iOS local notification ids are signed 32-bit integers.
const int kLocalNotificationIdMax = 0x7fffffff;

/// Maps a backend notification id to a stable local-plugin integer id.
///
/// Same [notificationId] always yields the same positive 31-bit id. Wall-clock
/// time is never used. Empty ids fall back to [fallbackSeed] (still
/// deterministic).
int localNotificationIdFor({
  required String notificationId,
  String fallbackSeed = '',
}) {
  final seed = notificationId.trim().isNotEmpty
      ? notificationId.trim()
      : fallbackSeed;
  if (seed.isEmpty) {
    return 1;
  }
  final hashed = _fnv1a32(seed) & kLocalNotificationIdMax;
  return hashed == 0 ? 1 : hashed;
}

int _fnv1a32(String input) {
  const fnvOffset = 0x811c9dc5;
  const fnvPrime = 0x01000193;
  var hash = fnvOffset;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash;
}
