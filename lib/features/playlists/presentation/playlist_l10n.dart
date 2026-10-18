import '../../../core/l10n/l10n.dart';
import '../domain/imported_playlist.dart';
import '../domain/label.dart';
import '../domain/playlist.dart';
import '../domain/playlist_exception.dart';
import '../domain/video_metadata.dart';

extension PlaylistL10n on AppLocalizations {
  /// Localised label name, falling back to the database name for labels
  /// added after this version of the app.
  String labelName(Label label) => switch (label.slug) {
    'science' => labelScience,
    'nature' => labelNature,
    'animals' => labelAnimals,
    'football' => labelFootball,
    'sports' => labelSports,
    'music' => labelMusic,
    'art' => labelArt,
    'languages' => labelLanguages,
    'maths' => labelMaths,
    'stories' => labelStories,
    'bedtime' => labelBedtime,
    'cartoons' => labelCartoons,
    'history' => labelHistory,
    'space' => labelSpace,
    'cooking' => labelCooking,
    'crafts' => labelCrafts,
    _ => label.name,
  };

  String ageRangeLabel(AgeRange range) => ageRange(range.min, range.max);

  String playlistError(Object error) => switch (error) {
    PlaylistException(error: PlaylistError.duplicateVideo) =>
      videoErrorDuplicate,
    PlaylistException(error: PlaylistError.tooManyVideos) =>
      playlistErrorTooManyVideos,
    PlaylistException(error: PlaylistError.tooManyLabels) =>
      playlistErrorTooManyLabels,
    PlaylistException(error: PlaylistError.notFound) => playlistErrorNotFound,
    PlaylistException(error: PlaylistError.network) => errorNetwork,
    _ => errorGeneric,
  };

  String playlistImportError(PlaylistImportError error) => switch (error) {
    PlaylistImportError.unsupported => importErrorUnsupported,
    PlaylistImportError.notFound => importErrorNotFound,
    PlaylistImportError.notConfigured => importErrorNotConfigured,
    PlaylistImportError.quota => importErrorQuota,
    PlaylistImportError.network => errorNetwork,
    PlaylistImportError.unknown => errorGeneric,
  };

  String videoLookupError(VideoLookupError error) => switch (error) {
    VideoLookupError.invalidUrl => videoErrorInvalidUrl,
    VideoLookupError.notFound => videoErrorNotFound,
    VideoLookupError.notEmbeddable => videoErrorNotEmbeddable,
    VideoLookupError.network => errorNetwork,
    VideoLookupError.unknown => errorGeneric,
  };
}
