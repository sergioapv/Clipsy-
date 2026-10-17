import 'dart:convert';
import 'dart:typed_data';

import 'package:clipsy/features/auth/domain/pin.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('Pin.isValid', () {
    test('accepts exactly four digits', () {
      expect(Pin.isValid('0000'), isTrue);
      expect(Pin.isValid('1234'), isTrue);
    });

    test('rejects anything else', () {
      for (final bad in ['', '123', '12345', '12a4', ' 1234', '１２３４']) {
        expect(Pin.isValid(bad), isFalse, reason: bad);
      }
    });
  });

  group('pbkdf2Sha256', () {
    // RFC 7914 §11 test vector for PBKDF2-HMAC-SHA256.
    test('matches the RFC 7914 vector', () {
      final out = pbkdf2Sha256(
        utf8.encode('passwd'),
        utf8.encode('salt'),
        1,
        64,
      );
      expect(
        _hex(out),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
        '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
      );
    });
  });

  group('PinHasher', () {
    const hasher = PinHasher(iterations: 10, useIsolate: false);

    test('verifies the right PIN and rejects a wrong one', () async {
      final encoded = await hasher.hash('4821');
      expect(encoded, startsWith(r'pbkdf2-sha256$10$'));
      expect(await hasher.verify('4821', encoded), isTrue);
      expect(await hasher.verify('4822', encoded), isFalse);
    });

    test('never stores the PIN in clear and salts every hash', () async {
      final a = await hasher.hash('1111');
      final b = await hasher.hash('1111');
      expect(a, isNot(contains('1111')));
      expect(a, isNot(b));
    });

    test('is deterministic for a fixed salt', () async {
      final salt = Uint8List(16);
      expect(
        await hasher.hash('1234', salt: salt),
        await hasher.hash('1234', salt: salt),
      );
    });

    test('verifies using the iteration count stored in the hash', () async {
      final old = await const PinHasher(
        iterations: 3,
        useIsolate: false,
      ).hash('9090');
      expect(await hasher.verify('9090', old), isTrue);
    });

    test('rejects malformed hashes and invalid PINs', () async {
      final encoded = await hasher.hash('1234');
      expect(await hasher.verify('1234', 'garbage'), isFalse);
      expect(await hasher.verify('1234', r'pbkdf2-sha256$x$a$b'), isFalse);
      expect(await hasher.verify('1234', r'pbkdf2-sha256$1$%%$%%'), isFalse);
      expect(await hasher.verify('12345', encoded), isFalse);
      expect(() => hasher.hash('12'), throwsArgumentError);
    });
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });
}
