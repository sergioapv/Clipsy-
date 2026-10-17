/// Throttles PIN guesses so a child can't brute-force the 10,000 combinations.
///
/// The first [freeAttempts] failures are free. After that, each further
/// failure locks entry for [baseLockout], doubling every time, capped at
/// [maxLockout]. A correct PIN resets the counter.
class PinLockoutPolicy {
  const PinLockoutPolicy({
    this.freeAttempts = 5,
    this.baseLockout = const Duration(seconds: 30),
    this.maxLockout = const Duration(minutes: 15),
  });

  final int freeAttempts;
  final Duration baseLockout;
  final Duration maxLockout;

  /// How long entry is locked after [failedAttempts] consecutive failures.
  Duration lockoutFor(int failedAttempts) {
    if (failedAttempts < freeAttempts) return Duration.zero;
    final exponent = failedAttempts - freeAttempts;
    // Clamp the exponent before shifting so the multiplier can't overflow.
    final multiplier = 1 << exponent.clamp(0, 20);
    final lockout = baseLockout * multiplier;
    return lockout > maxLockout ? maxLockout : lockout;
  }

  /// When entry unlocks again, or `null` if it isn't locked at [now].
  DateTime? lockedUntil({
    required int failedAttempts,
    required DateTime? lastFailureAt,
    required DateTime now,
  }) {
    if (lastFailureAt == null) return null;
    final lockout = lockoutFor(failedAttempts);
    if (lockout == Duration.zero) return null;
    final until = lastFailureAt.add(lockout);
    return until.isAfter(now) ? until : null;
  }

  /// Attempts left before the next lockout kicks in (0 once past the free ones).
  int attemptsBeforeLockout(int failedAttempts) =>
      (freeAttempts - failedAttempts).clamp(0, freeAttempts);
}
