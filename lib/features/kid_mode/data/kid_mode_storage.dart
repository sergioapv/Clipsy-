import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/kid_session.dart';
import '../domain/kid_settings.dart';

/// Kid mode preferences.
class KidSettingsRepository {
  const KidSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _limit = 'kid.defaultLimitMinutes';
  static const _mode = 'kid.timerMode';
  static const _end = 'kid.endBehaviour';
  static const _hold = 'kid.exitHoldSeconds';

  KidModeSettings load() {
    const d = KidModeSettings();
    return KidModeSettings(
      defaultLimit: Duration(
        minutes: _prefs.getInt(_limit) ?? d.defaultLimit.inMinutes,
      ),
      timerMode:
          _byName(TimerMode.values, _prefs.getString(_mode)) ?? d.timerMode,
      endBehaviour:
          _byName(EndBehaviour.values, _prefs.getString(_end)) ??
          d.endBehaviour,
      exitHold: Duration(seconds: _prefs.getInt(_hold) ?? d.exitHold.inSeconds),
    );
  }

  Future<void> save(KidModeSettings s) async {
    await _prefs.setInt(_limit, s.defaultLimit.inMinutes);
    await _prefs.setString(_mode, s.timerMode.name);
    await _prefs.setString(_end, s.endBehaviour.name);
    await _prefs.setInt(_hold, s.exitHold.inSeconds);
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      values.where((v) => v.name == name).firstOrNull;
}

/// Persists the active Kid mode session so it survives the app being killed.
class KidSessionStore {
  const KidSessionStore(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'kid.session';

  KidSession? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return KidSession.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      // A corrupt session must never brick the app; parent mode needs the PIN
      // anyway, so dropping it is safe.
      return null;
    }
  }

  Future<void> save(KidSession session) =>
      _prefs.setString(key, jsonEncode(session.toJson()));

  Future<void> clear() => _prefs.remove(key);
}
