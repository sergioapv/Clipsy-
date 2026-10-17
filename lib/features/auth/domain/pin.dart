import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Parent PIN rules.
abstract final class Pin {
  static const length = 4;
  static final _pattern = RegExp(r'^\d{4}$');

  static bool isValid(String pin) => _pattern.hasMatch(pin);
}

/// Salted PBKDF2-HMAC-SHA256 hashing for the parent PIN.
///
/// A 4-digit PIN has only 10,000 combinations, so the hash alone cannot stop
/// an offline attack. The real protections are that the hash lives in the
/// platform keystore (`flutter_secure_storage`) and that [PinLockoutPolicy]
/// throttles guesses. Hashing still means the PIN is never stored in clear.
///
/// Encoded format: `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`.
class PinHasher {
  const PinHasher({
    this.iterations = defaultIterations,
    this.useIsolate = true,
  });

  static const defaultIterations = 20000;
  static const _scheme = 'pbkdf2-sha256';
  static const _saltBytes = 16;
  static const _keyBytes = 32;

  final int iterations;

  /// Runs the key derivation off the UI isolate. Disabled in tests.
  final bool useIsolate;

  Future<String> hash(String pin, {Uint8List? salt}) async {
    if (!Pin.isValid(pin)) {
      throw ArgumentError.value(pin, 'pin', 'must be ${Pin.length} digits');
    }
    final s = salt ?? _randomSalt();
    final iters = iterations;
    final derived = useIsolate
        ? await Isolate.run(
            () => pbkdf2Sha256(utf8.encode(pin), s, iters, _keyBytes),
          )
        : pbkdf2Sha256(utf8.encode(pin), s, iters, _keyBytes);
    return '$_scheme\$$iters\$${base64Encode(s)}\$${base64Encode(derived)}';
  }

  /// Checks [pin] against an [encoded] hash produced by [hash]. Uses the
  /// iteration count stored in the hash, so the default can change later.
  Future<bool> verify(String pin, String encoded) async {
    if (!Pin.isValid(pin)) return false;
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final iters = int.tryParse(parts[1]);
    if (iters == null || iters < 1) return false;
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = useIsolate
        ? await Isolate.run(
            () => pbkdf2Sha256(utf8.encode(pin), salt, iters, expected.length),
          )
        : pbkdf2Sha256(utf8.encode(pin), salt, iters, expected.length);
    return constantTimeEquals(actual, expected);
  }

  static Uint8List _randomSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => rng.nextInt(256)),
    );
  }
}

/// PBKDF2 (RFC 8018) with HMAC-SHA256.
Uint8List pbkdf2Sha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  const hLen = 32;
  final blocks = (keyLength + hLen - 1) ~/ hLen;
  final out = BytesBuilder(copy: false);
  for (var i = 1; i <= blocks; i++) {
    final blockIndex = Uint8List(4)
      ..buffer.asByteData().setUint32(0, i, Endian.big);
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = Uint8List.fromList(u);
    for (var j = 1; j < iterations; j++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < hLen; k++) {
        t[k] ^= u[k];
      }
    }
    out.add(t);
  }
  return Uint8List.sublistView(out.takeBytes(), 0, keyLength);
}

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
