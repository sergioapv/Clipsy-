/// Outcome of checking a PIN.
sealed class PinCheckResult {
  const PinCheckResult();
}

final class PinAccepted extends PinCheckResult {
  const PinAccepted();
}

final class PinRejected extends PinCheckResult {
  const PinRejected({required this.attemptsBeforeLockout});

  /// 0 means the next wrong PIN (or this one) starts a lockout.
  final int attemptsBeforeLockout;
}

final class PinLockedOut extends PinCheckResult {
  const PinLockedOut({required this.until});

  final DateTime until;
}
