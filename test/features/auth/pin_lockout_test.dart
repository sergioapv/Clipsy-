import 'package:clipsy/features/auth/domain/pin_lockout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = PinLockoutPolicy();

  test('first five failures are free', () {
    for (var i = 0; i < 5; i++) {
      expect(policy.lockoutFor(i), Duration.zero);
    }
  });

  test('lockout doubles from 30 s and caps at 15 min', () {
    expect(policy.lockoutFor(5), const Duration(seconds: 30));
    expect(policy.lockoutFor(6), const Duration(minutes: 1));
    expect(policy.lockoutFor(7), const Duration(minutes: 2));
    expect(policy.lockoutFor(10), const Duration(minutes: 15));
    expect(policy.lockoutFor(1000), const Duration(minutes: 15));
  });

  test('lockedUntil is null once the lockout has passed', () {
    final last = DateTime(2026, 1, 1, 12);
    expect(
      policy.lockedUntil(
        failedAttempts: 5,
        lastFailureAt: last,
        now: last.add(const Duration(seconds: 10)),
      ),
      last.add(const Duration(seconds: 30)),
    );
    expect(
      policy.lockedUntil(
        failedAttempts: 5,
        lastFailureAt: last,
        now: last.add(const Duration(seconds: 31)),
      ),
      isNull,
    );
    expect(
      policy.lockedUntil(failedAttempts: 9, lastFailureAt: null, now: last),
      isNull,
    );
  });

  test('attemptsBeforeLockout counts down to zero', () {
    expect(policy.attemptsBeforeLockout(0), 5);
    expect(policy.attemptsBeforeLockout(4), 1);
    expect(policy.attemptsBeforeLockout(5), 0);
    expect(policy.attemptsBeforeLockout(9), 0);
  });
}
