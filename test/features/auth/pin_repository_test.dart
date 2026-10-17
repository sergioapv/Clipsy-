import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/features/auth/data/pin_repository.dart';
import 'package:clipsy/features/auth/domain/pin.dart';
import 'package:clipsy/features/auth/domain/pin_check_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySecureStore store;
  late DateTime now;
  late PinRepository repo;

  setUp(() {
    store = InMemorySecureStore();
    now = DateTime.utc(2026, 10, 17, 9);
    repo = PinRepository(
      store: store,
      hasher: const PinHasher(iterations: 5, useIsolate: false),
      clock: () => now,
    );
  });

  test('stores only a hash', () async {
    expect(await repo.hasPin(), isFalse);
    await repo.setPin('2468');
    expect(await repo.hasPin(), isTrue);
    expect(store.values[PinRepository.hashKey], isNot(contains('2468')));
  });

  test('rejects invalid PINs on set', () {
    expect(() => repo.setPin('12'), throwsArgumentError);
  });

  test('verify throws when no PIN is set', () {
    expect(() => repo.verify('1234'), throwsStateError);
  });

  test('accepts the right PIN', () async {
    await repo.setPin('2468');
    expect(await repo.verify('2468'), isA<PinAccepted>());
  });

  test('counts down, locks out, and unlocks after the wait', () async {
    await repo.setPin('2468');
    for (var left = 4; left >= 1; left--) {
      final r = await repo.verify('0000');
      expect((r as PinRejected).attemptsBeforeLockout, left);
    }
    final fifth = await repo.verify('0000');
    expect(fifth, isA<PinLockedOut>());
    expect((fifth as PinLockedOut).until, now.add(const Duration(seconds: 30)));

    // Even the right PIN is refused while locked.
    now = now.add(const Duration(seconds: 10));
    expect(await repo.verify('2468'), isA<PinLockedOut>());
    expect(await repo.lockedUntil(), isNotNull);

    now = now.add(const Duration(seconds: 21));
    expect(await repo.lockedUntil(), isNull);
    expect(await repo.verify('2468'), isA<PinAccepted>());

    // Success resets the counter.
    final r = await repo.verify('0000');
    expect((r as PinRejected).attemptsBeforeLockout, 4);
  });

  test('a further failure after a lockout doubles the wait', () async {
    await repo.setPin('2468');
    for (var i = 0; i < 5; i++) {
      await repo.verify('0000');
    }
    now = now.add(const Duration(seconds: 31));
    final r = await repo.verify('0000');
    expect((r as PinLockedOut).until, now.add(const Duration(minutes: 1)));
  });

  test('setting a new PIN resets failures; clear removes everything', () async {
    await repo.setPin('2468');
    await repo.verify('0000');
    await repo.setPin('1357');
    expect(store.values.containsKey(PinRepository.failuresKey), isFalse);
    expect(await repo.verify('1357'), isA<PinAccepted>());

    await repo.clear();
    expect(await repo.hasPin(), isFalse);
    expect(store.values, isEmpty);
  });

  test('a corrupt failure counter does not lock forever', () async {
    await repo.setPin('2468');
    store.values[PinRepository.failuresKey] = '{not json';
    expect(await repo.verify('2468'), isA<PinAccepted>());
  });
}
