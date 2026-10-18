import 'package:supabase_flutter/supabase_flutter.dart';

import '../../playlists/data/playlist_repository.dart';
import '../../playlists/domain/playlist_exception.dart';

/// The parent's public profile: just the name shown on published playlists.
abstract interface class ProfileRepository {
  Future<String> fetchDisplayName();
  Future<void> updateDisplayName(String name);

  static const maxNameLength = 40;
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client, {String? Function()? currentUserId})
    : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  String get _uid {
    final id = _currentUserId();
    if (id == null) throw const PlaylistException(PlaylistError.notFound);
    return id;
  }

  @override
  Future<String> fetchDisplayName() => guardPlaylistCall(() async {
    final row = await _client
        .from('profiles')
        .select('display_name')
        .eq('id', _uid)
        .single();
    return row['display_name']! as String;
  });

  @override
  Future<void> updateDisplayName(String name) => guardPlaylistCall(
    () => _client
        .from('profiles')
        .update({'display_name': name.trim()})
        .eq('id', _uid),
  );
}
