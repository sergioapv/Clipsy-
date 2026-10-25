// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Clipsy';

  @override
  String get tagline =>
      'Every video, picked by a parent. When the time\'s up, it stops.';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navCommunity => 'Community';

  @override
  String get navSettings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get or => 'or';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get signInParentsOnly =>
      'Sign in as a parent. Kids don\'t need an account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get sendMagicLink => 'Email me a sign-in link';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String magicLinkSent(String email) {
    return 'We sent a sign-in link to $email. Open it on this device.';
  }

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get signInFailed => 'Couldn\'t sign in. Please try again.';

  @override
  String get signInRateLimited =>
      'Too many requests. Wait a minute and try again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'This also removes the parent PIN from this device. You\'ll set a new one next time you sign in.';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get pinCreateTitle => 'Create a parent PIN';

  @override
  String get pinCreateSubtitle =>
      'You\'ll need these 4 digits to leave Kid mode and open parent settings. Keep it secret from the kids!';

  @override
  String get pinConfirmTitle => 'Enter the PIN again';

  @override
  String get pinMismatch => 'The PINs didn\'t match. Try again.';

  @override
  String get pinEnterCurrent => 'Enter your current PIN';

  @override
  String get pinChooseNew => 'Choose a new PIN';

  @override
  String get pinChanged => 'PIN changed';

  @override
  String get changePin => 'Change PIN';

  @override
  String get pinWrong => 'Wrong PIN';

  @override
  String pinWrongAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count tries left before a short wait.',
      one: 'Wrong PIN. 1 try left before a short wait.',
    );
    return '$_temp0';
  }

  @override
  String pinLockedOut(String time) {
    return 'Too many tries. Try again in $time.';
  }

  @override
  String pinDigitsEntered(int entered, int total) {
    return '$entered of $total digits entered';
  }

  @override
  String get pinBackspace => 'Delete last digit';

  @override
  String get unlockTitle => 'Enter parent PIN';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinTitle => 'Reset your PIN';

  @override
  String get forgotPinBody =>
      'To reset the PIN you\'ll sign in again with your parent account, then choose a new PIN.';

  @override
  String get forgotPinConfirm => 'Sign in again';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Clipsy';

  @override
  String get onboardingWelcomeBody =>
      'Build playlists of YouTube videos you\'ve chosen yourself, then hand over the device knowing exactly what your child will watch, and for how long.';

  @override
  String get onboardingKidModeTitle => 'How Kid mode works';

  @override
  String get onboardingKidModeBody =>
      'Kid mode plays one playlist with big, simple controls. There\'s no search and no suggestions.';

  @override
  String get onboardingKidModeStep1 => 'Pick a playlist and a time limit.';

  @override
  String get onboardingKidModeStep2 =>
      'Confirm with your PIN and hand over the device.';

  @override
  String get onboardingKidModeStep3 =>
      'When time\'s up, playback stops. Only your PIN can add more time or exit.';

  @override
  String get onboardingPinningTitle => 'Lock the screen to Clipsy';

  @override
  String get onboardingPinningBody =>
      'When Kid mode starts, Android will ask to pin Clipsy to the screen. Accept it: Home and Recents stay blocked until you exit Kid mode with your PIN.';

  @override
  String get onboardingGuidedAccessTitle => 'Turn on Guided Access';

  @override
  String get onboardingGuidedAccessBody =>
      'iPhone and iPad apps can\'t lock themselves. Guided Access, built into iOS, keeps your child inside Clipsy. Kid mode still works without it, with in-app protections only.';

  @override
  String get onboardingGuidedAccessStep1 =>
      'Open Settings → Accessibility → Guided Access and turn it on.';

  @override
  String get onboardingGuidedAccessStep2 => 'Set a Guided Access passcode.';

  @override
  String get onboardingGuidedAccessStep3 =>
      'In Kid mode, triple-click the side (or Home) button and tap Start.';

  @override
  String onboardingPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get playlistsEmptyTitle => 'No playlists yet';

  @override
  String get playlistsEmptyBody =>
      'Create your first playlist, then add videos by pasting YouTube links.';

  @override
  String get communityComingTitle => 'Community library';

  @override
  String get communityComingBody =>
      'Browse, save and rate playlists made by other parents. Coming soon.';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAbout => 'About';

  @override
  String get lockParentMode => 'Lock parent mode now';

  @override
  String get lockParentModeHint => 'Requires the PIN to get back in';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get retry => 'Try again';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorTitle => 'Couldn\'t load this';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String get paste => 'Paste';

  @override
  String get moreOptions => 'More options';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get editDetails => 'Edit details';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String deletePlaylistTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get deletePlaylistBody =>
      'The playlist and its video list will be removed. The videos stay on YouTube.';

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'No videos',
    );
    return '$_temp0';
  }

  @override
  String ageRange(int min, int max) {
    return 'Ages $min–$max';
  }

  @override
  String ageYears(int years) {
    return '$years years';
  }

  @override
  String get playlistTitleLabel => 'Title';

  @override
  String get playlistTitleHint => 'e.g. Dinosaur facts';

  @override
  String get playlistTitleRequired => 'Give the playlist a title';

  @override
  String get playlistDescriptionLabel => 'Description (optional)';

  @override
  String get ageRangeTitle => 'Age range';

  @override
  String get labelsTitle => 'Labels';

  @override
  String labelsHint(int max) {
    return 'Pick up to $max. They help other parents find your playlist if you share it later.';
  }

  @override
  String get createPlaylist => 'Create playlist';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get playlistEmptyTitle => 'No videos yet';

  @override
  String get playlistEmptyBody =>
      'Tap “Add video” and paste a YouTube link. You can also share videos to Clipsy from the YouTube app (coming soon).';

  @override
  String get reorderHint => 'Hold the dots to reorder · swipe left to remove';

  @override
  String get videoRemoved => 'Video removed';

  @override
  String get removeVideo => 'Remove video';

  @override
  String get videoUnavailable => 'No longer available on YouTube';

  @override
  String get addVideo => 'Add video';

  @override
  String get addVideoHint =>
      'Paste a link from YouTube. We\'ll check that it can be played in Clipsy.';

  @override
  String get youtubeLink => 'YouTube link';

  @override
  String get checkVideo => 'Check video';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String videosAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos added',
      one: '1 video added',
    );
    return '$_temp0';
  }

  @override
  String get videoErrorInvalidUrl =>
      'That doesn\'t look like a link to a YouTube video.';

  @override
  String get videoErrorNotFound =>
      'We couldn\'t find that video. It may have been removed or made private.';

  @override
  String get videoErrorNotEmbeddable =>
      'The owner of this video doesn\'t allow it to play outside YouTube, so it can\'t be added.';

  @override
  String get videoErrorDuplicate => 'This video is already in the playlist.';

  @override
  String get playlistErrorTooManyVideos =>
      'This playlist is full. Remove a video to add another.';

  @override
  String get playlistErrorTooManyLabels =>
      'A playlist can have at most 3 labels.';

  @override
  String get playlistErrorNotFound => 'This playlist no longer exists.';

  @override
  String get labelScience => 'Science';

  @override
  String get labelNature => 'Nature';

  @override
  String get labelAnimals => 'Animals';

  @override
  String get labelFootball => 'Football';

  @override
  String get labelSports => 'Sports';

  @override
  String get labelMusic => 'Music';

  @override
  String get labelArt => 'Art';

  @override
  String get labelLanguages => 'Languages';

  @override
  String get labelMaths => 'Maths';

  @override
  String get labelStories => 'Stories';

  @override
  String get labelBedtime => 'Bedtime';

  @override
  String get labelCartoons => 'Cartoons';

  @override
  String get labelHistory => 'History';

  @override
  String get labelSpace => 'Space';

  @override
  String get labelCooking => 'Cooking';

  @override
  String get labelCrafts => 'Crafts';

  @override
  String get ok => 'OK';

  @override
  String get gotIt => 'Got it';

  @override
  String get startKidMode => 'Start Kid mode';

  @override
  String get kidNeedsVideos =>
      'Add at least one video before starting Kid mode.';

  @override
  String get kidConfirmPin => 'Enter your PIN to start Kid mode';

  @override
  String useDefaultLimit(int minutes) {
    return 'Use default: $minutes min';
  }

  @override
  String get orChooseLimit => 'Or choose a time limit';

  @override
  String get customLimit => 'Custom…';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes left',
      one: '1 minute left',
    );
    return '$_temp0';
  }

  @override
  String get pinningDialogTitle => 'Clipsy will pin itself';

  @override
  String get pinningDialogBody =>
      'Android will now ask to pin Clipsy to the screen. Tap “Pin” (or “Got it”). While pinned, Home and Recents are blocked.\n\nTo leave Kid mode, hold the small lock in the corner and enter your PIN.\n\nTip: in Android Settings → Security → App pinning, turn on “Ask for PIN before unpinning” for extra safety.';

  @override
  String get guidedAccessOffBody =>
      'Guided Access is off, so your child could leave Clipsy with the Home gesture. Kid mode still blocks everything inside the app.';

  @override
  String get startAnyway => 'Start anyway';

  @override
  String get kidPlay => 'Play';

  @override
  String get kidPause => 'Pause';

  @override
  String get kidAlmostDone => 'Almost done!';

  @override
  String get kidLastVideo => 'Last video!';

  @override
  String kidExitHint(int seconds) {
    return 'Parent exit. Hold for $seconds seconds.';
  }

  @override
  String get timeUpTitle => 'All done for now!';

  @override
  String get timeUpBody => 'Great watching! Time for something else.';

  @override
  String get timeUpParent => 'Parent';

  @override
  String get timeUpParentTitle => 'More time, or finish?';

  @override
  String addMinutes(int minutes) {
    return '+$minutes min';
  }

  @override
  String get exitKidMode => 'Exit Kid mode';

  @override
  String get settingsKidMode => 'Kid mode';

  @override
  String get defaultTimeLimit => 'Default time limit';

  @override
  String get timerModeTitle => 'Count';

  @override
  String get timerModeWallClock => 'Clock time (includes pauses)';

  @override
  String get timerModePlayback => 'Watching time only';

  @override
  String get endBehaviourTitle => 'When time\'s up';

  @override
  String get endHardStop => 'Stop right away';

  @override
  String endFinishVideo(int minutes) {
    return 'Let the current video finish (up to $minutes min)';
  }

  @override
  String get exitGestureTitle => 'Exit button';

  @override
  String exitGestureValue(int seconds) {
    return 'Hold for $seconds seconds, then PIN';
  }

  @override
  String get guidedAccessOn => 'On';

  @override
  String get guidedAccessOffShort => 'Off · tap for how to turn it on';

  @override
  String get browseYouTube => 'Browse YouTube';

  @override
  String get orPasteLink => 'or paste a link';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get inPlaylist => 'In this playlist';

  @override
  String addToNamedPlaylist(String title) {
    return 'Add to “$title”';
  }

  @override
  String videoAddedNamed(String title) {
    return 'Added “$title”';
  }

  @override
  String get addWholePlaylist => 'Add whole playlist';

  @override
  String get addWholePlaylistInstead => 'Add the whole playlist instead';

  @override
  String get importPlaylistTitle => 'Add a YouTube playlist';

  @override
  String importAddVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count videos',
      one: 'Add 1 video',
    );
    return '$_temp0';
  }

  @override
  String get importNothingToAdd => 'Nothing new to add';

  @override
  String importAlreadyThere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos are already in this playlist',
      one: '1 video is already in this playlist',
    );
    return '$_temp0';
  }

  @override
  String importUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count videos can\'t play in Clipsy (private, removed or not embeddable) and will be skipped',
      one: '1 video can\'t play in Clipsy (private, removed or not embeddable) and will be skipped',
    );
    return '$_temp0';
  }

  @override
  String importOverLimit(int max) {
    return 'A playlist can hold up to $max videos, so some will be left out.';
  }

  @override
  String get importErrorUnsupported =>
      'Mixes and personal lists (like Watch later) can\'t be added. Open a regular playlist instead.';

  @override
  String get importErrorNotFound =>
      'We couldn\'t read that playlist. It may be private, deleted or empty.';

  @override
  String get kidFullscreen => 'Full screen';

  @override
  String get kidExitFullscreen => 'Exit full screen';

  @override
  String get importFindingVideos => 'Finding the playlist\'s videos…';

  @override
  String importCheckingVideos(int checked, int total) {
    return 'Checking videos… $checked of $total';
  }

  @override
  String get kidNextVideo => 'Next video';

  @override
  String get kidPickVideo => 'Choose a video';

  @override
  String get minutesUnit => 'min';

  @override
  String get communityTopRated => 'Top rated';

  @override
  String get communityNew => 'New';

  @override
  String get communityByLabel => 'By label';

  @override
  String get communitySearchHint => 'Search shared playlists';

  @override
  String get communityAllAges => 'All ages';

  @override
  String get communityEmptyTitle => 'Nothing here yet';

  @override
  String get communityEmptyBody =>
      'No shared playlists match. Try another label or age, or share one of yours.';

  @override
  String get communityPickLabel => 'Pick a topic';

  @override
  String communityByAuthor(String name) {
    return 'by $name';
  }

  @override
  String get communityYours => 'Yours';

  @override
  String get communityLoadMoreFailed => 'Couldn\'t load more.';

  @override
  String get ratingNone => 'No ratings yet';

  @override
  String ratingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$_temp0';
  }

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String ratingAverage(String average) {
    return 'Rated $average out of 5';
  }

  @override
  String get communitySaveToLibrary => 'Save to my playlists';

  @override
  String get communitySaved => 'Saved to your playlists';

  @override
  String get communityOpen => 'Open';

  @override
  String get communityRateTitle => 'Your rating';

  @override
  String get communityRateHint => 'Tap a star to rate this playlist.';

  @override
  String get communityRateThanks => 'Thanks for rating.';

  @override
  String get communityOwnPlaylist =>
      'This is your playlist. Other parents can save and rate it.';

  @override
  String get communityBasedOn => 'Based on another parent\'s playlist';

  @override
  String get communityVideos => 'Videos';

  @override
  String get reportPlaylist => 'Report';

  @override
  String get reportTitle => 'Report this playlist';

  @override
  String get reportBody =>
      'Tell us what\'s wrong. After several reports, the playlist is hidden until it\'s reviewed.';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonViolent => 'Violent or scary';

  @override
  String get reportReasonNotForKids => 'Not suitable for children';

  @override
  String get reportReasonMisleading => 'Misleading title or labels';

  @override
  String get reportReasonSpam => 'Spam or advertising';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Thanks. We\'ll take a look.';

  @override
  String get playlistErrorNeedsLabel =>
      'Pick at least one label to share this playlist.';

  @override
  String get playlistErrorNeedsVideo =>
      'Shared playlists need at least one video.';

  @override
  String get playlistErrorOwnPlaylist =>
      'You can\'t rate or report your own playlist.';

  @override
  String get playlistErrorAlreadyReported =>
      'You\'ve already reported this playlist.';

  @override
  String get shareWithCommunity => 'Share with the community';

  @override
  String get shareWithCommunityHint =>
      'Other parents can find, save and rate it. They see your community name, never your email.';

  @override
  String get shareNeedsVideos => 'Add a video first, then you can share it.';

  @override
  String get sharedStatus => 'Shared with the community';

  @override
  String get hiddenStatus =>
      'Hidden from the community after reports, until it\'s reviewed.';

  @override
  String get stopSharing => 'Stop sharing';

  @override
  String get unsharedSnack => 'No longer shared';

  @override
  String get communityName => 'Name shown in the community';

  @override
  String get communityNameInvalid => 'Use 1 to 40 characters.';

  @override
  String get shareIntakeTitle => 'Add to a playlist';

  @override
  String get shareIntakeBody => 'Choose where to add this YouTube link.';

  @override
  String get shareIntakeNotYouTube =>
      'That link isn\'t a YouTube video or playlist.';

  @override
  String get shareIntakeNoPlaylists =>
      'Create a playlist first, then share the link again.';

  @override
  String get kidSeekBack => 'Back 10 seconds';

  @override
  String get kidSeekForward => 'Forward 10 seconds';

  @override
  String get kidSeekBar => 'Video position';

  @override
  String get kidSeekShow => 'Move through the video';

  @override
  String get kidSeekHide => 'Hide the video bar';

  @override
  String get languagesTitle => 'Languages';

  @override
  String languagesHint(int count) {
    return 'Up to $count. Needed to share a playlist.';
  }

  @override
  String get addLanguage => 'Add language';

  @override
  String get languageAny => 'Any language';

  @override
  String get languageAllVariants => 'All variants';

  @override
  String get languageSearchHint => 'Search, or type a code like pt-BR';

  @override
  String get languageNoMatch => 'No language matches.';

  @override
  String get languageFilter => 'Language';

  @override
  String languagesFull(int count) {
    return 'You can pick up to $count languages.';
  }

  @override
  String get playlistErrorNeedsLanguage =>
      'Pick at least one language to share this playlist.';

  @override
  String get playlistsNoneInLanguageTitle => 'No playlists in this language';

  @override
  String get playlistsNoneInLanguageBody =>
      'Pick another language, or show them all.';

  @override
  String removeLanguage(String language) {
    return 'Remove $language';
  }
}
