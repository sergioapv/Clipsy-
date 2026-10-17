import 'dart:convert';

import '../../../core/storage/secure_store.dart';
import '../domain/pin.dart';
import '../domain/pin_check_result.dart';
import '../domain/pin_lockout.dart';

/// Stores the parent PIN hash and the failed-attempt counter in the platform
/// keystore. The PIN is per device, not per account.
class PinRepository {
  PinRepository({
    required this._store,
    this._hasher = const PinHasher(),
    this._policy = const PinLockoutPolicy(),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  static const hashKey = 'pin.hash';
  static const failuresKey = 'pin.failures';

  final SecureStore _store;
  final PinHasher _hasher;
  final PinLockoutPolicy _policy;
  final DateTime Function() _now;

  Future<bool> hasPin() async => await _store.read(hashKey) != null;

  Future<void> setPin(String pin) async {
    if (!Pin.isValid(pin)) {
      throw ArgumentError.value(pin, 'pin', 'must be ${Pin.length} digits');
    }
    await _store.write(hashKey, await _hasher.hash(pin));
    await _store.delete(failuresKey);
  }

  /// Checks [pin], recording failures and enforcing lockouts.
  Future<PinCheckResult> verify(String pin) async {
    final stored = await _store.read(hashKey);
    if (stored == null) throw StateError('No PIN has been set');

    final failures = await _readFailures();
    final lockedUntil = _policy.lockedUntil(
      failedAttempts: failures.count,
      lastFailureAt: failures.lastAt,
      now: _now(),
    );
    // While locked, don't even evaluate the guess.
    if (lockedUntil != null) return PinLockedOut(until: lockedUntil);

    if (await _hasher.verify(pin, stored)) {
      await _store.delete(failuresKey);
      return const PinAccepted();
    }

    final count = failures.count + 1;
    final now = _now();
    await _store.write(
      failuresKey,
      jsonEncode({'count': count, 'lastAt': now.toUtc().toIso8601String()}),
    );
    final lockout = _policy.lockoutFor(count);
    if (lockout > Duration.zero) return PinLockedOut(until: now.add(lockout));
    return PinRejected(
      attemptsBeforeLockout: _policy.attemptsBeforeLockout(count),
    );
  }

  /// Current lockout end, if any (for showing a countdown before typing).
  Future<DateTime?> lockedUntil() async {
    final failures = await _readFailures();
    return _policy.lockedUntil(
      failedAttempts: failures.count,
      lastFailureAt: failures.lastAt,
      now: _now(),
    );
  }

  /// Removes the PIN, e.g. on sign-out or PIN reset after re-authentication.
  Future<void> clear() async {
    await _store.delete(hashKey);
    await _store.delete(failuresKey);
  }

  Future<({int count, DateTime? lastAt})> _readFailures() async {
    final raw = await _store.read(failuresKey);
    if (raw == null) return (count: 0, lastAt: null);
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      return (
        count: (map['count'] as num?)?.toInt() ?? 0,
        lastAt: DateTime.tryParse(map['lastAt'] as String? ?? ''),
      );
    } on FormatException {
      // Corrupt counter: treat as a fresh failure state rather than unlocking
      // forever or locking forever.
      return (count: 0, lastAt: null);
    }
  }
}
