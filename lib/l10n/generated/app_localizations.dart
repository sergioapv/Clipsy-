import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Clipsy'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Every video, picked by a parent. When the time\'s up, it stops.'**
  String get tagline;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @signInParentsOnly.
  ///
  /// In en, this message translates to:
  /// **'Sign in as a parent. Kids don\'t need an account.'**
  String get signInParentsOnly;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a sign-in link'**
  String get sendMagicLink;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a sign-in link to {email}. Open it on this device.'**
  String magicLinkSent(String email);

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Please try again.'**
  String get signInFailed;

  /// No description provided for @signInRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Wait a minute and try again.'**
  String get signInRateLimited;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This also removes the parent PIN from this device. You\'ll set a new one next time you sign in.'**
  String get signOutConfirmBody;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a parent PIN'**
  String get pinCreateTitle;

  /// No description provided for @pinCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need these 4 digits to leave Kid mode and open parent settings. Keep it secret from the kids!'**
  String get pinCreateSubtitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get pinConfirmTitle;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs didn\'t match. Try again.'**
  String get pinMismatch;

  /// No description provided for @pinEnterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get pinEnterCurrent;

  /// No description provided for @pinChooseNew.
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN'**
  String get pinChooseNew;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get pinChanged;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get pinWrong;

  /// No description provided for @pinWrongAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. 1 try left before a short wait.} other{Wrong PIN. {count} tries left before a short wait.}}'**
  String pinWrongAttemptsLeft(int count);

  /// No description provided for @pinLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Try again in {time}.'**
  String pinLockedOut(String time);

  /// No description provided for @pinDigitsEntered.
  ///
  /// In en, this message translates to:
  /// **'{entered} of {total} digits entered'**
  String pinDigitsEntered(int entered, int total);

  /// No description provided for @pinBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get pinBackspace;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter parent PIN'**
  String get unlockTitle;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your PIN'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinBody.
  ///
  /// In en, this message translates to:
  /// **'To reset the PIN you\'ll sign in again with your parent account, then choose a new PIN.'**
  String get forgotPinBody;

  /// No description provided for @forgotPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get forgotPinConfirm;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Clipsy'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Build playlists of YouTube videos you\'ve chosen yourself, then hand over the device knowing exactly what your child will watch, and for how long.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingKidModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How Kid mode works'**
  String get onboardingKidModeTitle;

  /// No description provided for @onboardingKidModeBody.
  ///
  /// In en, this message translates to:
  /// **'Kid mode plays one playlist with big, simple controls. There\'s no search and no suggestions.'**
  String get onboardingKidModeBody;

  /// No description provided for @onboardingKidModeStep1.
  ///
  /// In en, this message translates to:
  /// **'Pick a playlist and a time limit.'**
  String get onboardingKidModeStep1;

  /// No description provided for @onboardingKidModeStep2.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your PIN and hand over the device.'**
  String get onboardingKidModeStep2;

  /// No description provided for @onboardingKidModeStep3.
  ///
  /// In en, this message translates to:
  /// **'When time\'s up, playback stops. Only your PIN can add more time or exit.'**
  String get onboardingKidModeStep3;

  /// No description provided for @onboardingPinningTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the screen to Clipsy'**
  String get onboardingPinningTitle;

  /// No description provided for @onboardingPinningBody.
  ///
  /// In en, this message translates to:
  /// **'When Kid mode starts, Android will ask to pin Clipsy to the screen. Accept it: Home and Recents stay blocked until you exit Kid mode with your PIN.'**
  String get onboardingPinningBody;

  /// No description provided for @onboardingGuidedAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on Guided Access'**
  String get onboardingGuidedAccessTitle;

  /// No description provided for @onboardingGuidedAccessBody.
  ///
  /// In en, this message translates to:
  /// **'iPhone and iPad apps can\'t lock themselves. Guided Access, built into iOS, keeps your child inside Clipsy. Kid mode still works without it, with in-app protections only.'**
  String get onboardingGuidedAccessBody;

  /// No description provided for @onboardingGuidedAccessStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Accessibility → Guided Access and turn it on.'**
  String get onboardingGuidedAccessStep1;

  /// No description provided for @onboardingGuidedAccessStep2.
  ///
  /// In en, this message translates to:
  /// **'Set a Guided Access passcode.'**
  String get onboardingGuidedAccessStep2;

  /// No description provided for @onboardingGuidedAccessStep3.
  ///
  /// In en, this message translates to:
  /// **'In Kid mode, triple-click the side (or Home) button and tap Start.'**
  String get onboardingGuidedAccessStep3;

  /// No description provided for @onboardingPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageOf(int current, int total);

  /// No description provided for @playlistsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get playlistsEmptyTitle;

  /// No description provided for @playlistsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first playlist, then add videos by pasting YouTube links.'**
  String get playlistsEmptyBody;

  /// No description provided for @communityComingTitle.
  ///
  /// In en, this message translates to:
  /// **'Community library'**
  String get communityComingTitle;

  /// No description provided for @communityComingBody.
  ///
  /// In en, this message translates to:
  /// **'Browse, save and rate playlists made by other parents. Coming soon.'**
  String get communityComingBody;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @lockParentMode.
  ///
  /// In en, this message translates to:
  /// **'Lock parent mode now'**
  String get lockParentMode;

  /// No description provided for @lockParentModeHint.
  ///
  /// In en, this message translates to:
  /// **'Requires the PIN to get back in'**
  String get lockParentModeHint;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String deletePlaylistTitle(String title);

  /// No description provided for @deletePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'The playlist and its video list will be removed. The videos stay on YouTube.'**
  String get deletePlaylistBody;

  /// No description provided for @videoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No videos} =1{1 video} other{{count} videos}}'**
  String videoCount(int count);

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Ages {min}–{max}'**
  String ageRange(int min, int max);

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String ageYears(int years);

  /// No description provided for @playlistTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get playlistTitleLabel;

  /// No description provided for @playlistTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dinosaur facts'**
  String get playlistTitleHint;

  /// No description provided for @playlistTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the playlist a title'**
  String get playlistTitleRequired;

  /// No description provided for @playlistDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get playlistDescriptionLabel;

  /// No description provided for @ageRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get ageRangeTitle;

  /// No description provided for @labelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsTitle;

  /// No description provided for @labelsHint.
  ///
  /// In en, this message translates to:
  /// **'Pick up to {max}. They help other parents find your playlist if you share it later.'**
  String labelsHint(int max);

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylist;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add video” and paste a YouTube link. You can also share videos to Clipsy from the YouTube app (coming soon).'**
  String get playlistEmptyBody;

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag ☰ to reorder · swipe left to remove'**
  String get reorderHint;

  /// No description provided for @videoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Video removed'**
  String get videoRemoved;

  /// No description provided for @removeVideo.
  ///
  /// In en, this message translates to:
  /// **'Remove video'**
  String get removeVideo;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available on YouTube'**
  String get videoUnavailable;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// No description provided for @addVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link from YouTube. We\'ll check that it can be played in Clipsy.'**
  String get addVideoHint;

  /// No description provided for @youtubeLink.
  ///
  /// In en, this message translates to:
  /// **'YouTube link'**
  String get youtubeLink;

  /// No description provided for @checkVideo.
  ///
  /// In en, this message translates to:
  /// **'Check video'**
  String get checkVideo;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @videosAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 video added} other{{count} videos added}}'**
  String videosAdded(int count);

  /// No description provided for @videoErrorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a link to a YouTube video.'**
  String get videoErrorInvalidUrl;

  /// No description provided for @videoErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that video. It may have been removed or made private.'**
  String get videoErrorNotFound;

  /// No description provided for @videoErrorNotEmbeddable.
  ///
  /// In en, this message translates to:
  /// **'The owner of this video doesn\'t allow it to play outside YouTube, so it can\'t be added.'**
  String get videoErrorNotEmbeddable;

  /// No description provided for @videoErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This video is already in the playlist.'**
  String get videoErrorDuplicate;

  /// No description provided for @playlistErrorTooManyVideos.
  ///
  /// In en, this message translates to:
  /// **'This playlist is full. Remove a video to add another.'**
  String get playlistErrorTooManyVideos;

  /// No description provided for @playlistErrorTooManyLabels.
  ///
  /// In en, this message translates to:
  /// **'A playlist can have at most 3 labels.'**
  String get playlistErrorTooManyLabels;

  /// No description provided for @playlistErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This playlist no longer exists.'**
  String get playlistErrorNotFound;

  /// No description provided for @labelScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get labelScience;

  /// No description provided for @labelNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get labelNature;

  /// No description provided for @labelAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get labelAnimals;

  /// No description provided for @labelFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get labelFootball;

  /// No description provided for @labelSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get labelSports;

  /// No description provided for @labelMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get labelMusic;

  /// No description provided for @labelArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get labelArt;

  /// No description provided for @labelLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get labelLanguages;

  /// No description provided for @labelMaths.
  ///
  /// In en, this message translates to:
  /// **'Maths'**
  String get labelMaths;

  /// No description provided for @labelStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get labelStories;

  /// No description provided for @labelBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get labelBedtime;

  /// No description provided for @labelCartoons.
  ///
  /// In en, this message translates to:
  /// **'Cartoons'**
  String get labelCartoons;

  /// No description provided for @labelHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get labelHistory;

  /// No description provided for @labelSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get labelSpace;

  /// No description provided for @labelCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get labelCooking;

  /// No description provided for @labelCrafts.
  ///
  /// In en, this message translates to:
  /// **'Crafts'**
  String get labelCrafts;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @startKidMode.
  ///
  /// In en, this message translates to:
  /// **'Start Kid mode'**
  String get startKidMode;

  /// No description provided for @kidNeedsVideos.
  ///
  /// In en, this message translates to:
  /// **'Add at least one video before starting Kid mode.'**
  String get kidNeedsVideos;

  /// No description provided for @kidConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to start Kid mode'**
  String get kidConfirmPin;

  /// No description provided for @useDefaultLimit.
  ///
  /// In en, this message translates to:
  /// **'Use default: {minutes} min'**
  String useDefaultLimit(int minutes);

  /// No description provided for @orChooseLimit.
  ///
  /// In en, this message translates to:
  /// **'Or choose a time limit'**
  String get orChooseLimit;

  /// No description provided for @customLimit.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get customLimit;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute left} other{{minutes} minutes left}}'**
  String minutesLeft(int minutes);

  /// No description provided for @pinningDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clipsy will pin itself'**
  String get pinningDialogTitle;

  /// No description provided for @pinningDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Android will now ask to pin Clipsy to the screen. Tap “Pin” (or “Got it”). While pinned, Home and Recents are blocked.\n\nTo leave Kid mode, hold the small lock in the corner and enter your PIN.\n\nTip: in Android Settings → Security → App pinning, turn on “Ask for PIN before unpinning” for extra safety.'**
  String get pinningDialogBody;

  /// No description provided for @guidedAccessOffBody.
  ///
  /// In en, this message translates to:
  /// **'Guided Access is off, so your child could leave Clipsy with the Home gesture. Kid mode still blocks everything inside the app.'**
  String get guidedAccessOffBody;

  /// No description provided for @startAnyway.
  ///
  /// In en, this message translates to:
  /// **'Start anyway'**
  String get startAnyway;

  /// No description provided for @kidPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get kidPlay;

  /// No description provided for @kidPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get kidPause;

  /// No description provided for @kidAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done!'**
  String get kidAlmostDone;

  /// No description provided for @kidLastVideo.
  ///
  /// In en, this message translates to:
  /// **'Last video!'**
  String get kidLastVideo;

  /// No description provided for @kidExitHint.
  ///
  /// In en, this message translates to:
  /// **'Parent exit. Hold for {seconds} seconds.'**
  String kidExitHint(int seconds);

  /// No description provided for @timeUpTitle.
  ///
  /// In en, this message translates to:
  /// **'All done for now!'**
  String get timeUpTitle;

  /// No description provided for @timeUpBody.
  ///
  /// In en, this message translates to:
  /// **'Great watching! Time for something else.'**
  String get timeUpBody;

  /// No description provided for @timeUpParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get timeUpParent;

  /// No description provided for @timeUpParentTitle.
  ///
  /// In en, this message translates to:
  /// **'More time, or finish?'**
  String get timeUpParentTitle;

  /// No description provided for @addMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min'**
  String addMinutes(int minutes);

  /// No description provided for @exitKidMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Kid mode'**
  String get exitKidMode;

  /// No description provided for @settingsKidMode.
  ///
  /// In en, this message translates to:
  /// **'Kid mode'**
  String get settingsKidMode;

  /// No description provided for @defaultTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Default time limit'**
  String get defaultTimeLimit;

  /// No description provided for @timerModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get timerModeTitle;

  /// No description provided for @timerModeWallClock.
  ///
  /// In en, this message translates to:
  /// **'Clock time (includes pauses)'**
  String get timerModeWallClock;

  /// No description provided for @timerModePlayback.
  ///
  /// In en, this message translates to:
  /// **'Watching time only'**
  String get timerModePlayback;

  /// No description provided for @endBehaviourTitle.
  ///
  /// In en, this message translates to:
  /// **'When time\'s up'**
  String get endBehaviourTitle;

  /// No description provided for @endHardStop.
  ///
  /// In en, this message translates to:
  /// **'Stop right away'**
  String get endHardStop;

  /// No description provided for @endFinishVideo.
  ///
  /// In en, this message translates to:
  /// **'Let the current video finish (up to {minutes} min)'**
  String endFinishVideo(int minutes);

  /// No description provided for @exitGestureTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit button'**
  String get exitGestureTitle;

  /// No description provided for @exitGestureValue.
  ///
  /// In en, this message translates to:
  /// **'Hold for {seconds} seconds, then PIN'**
  String exitGestureValue(int seconds);

  /// No description provided for @guidedAccessOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get guidedAccessOn;

  /// No description provided for @guidedAccessOffShort.
  ///
  /// In en, this message translates to:
  /// **'Off · tap for how to turn it on'**
  String get guidedAccessOffShort;

  /// No description provided for @browseYouTube.
  ///
  /// In en, this message translates to:
  /// **'Browse YouTube'**
  String get browseYouTube;

  /// No description provided for @orPasteLink.
  ///
  /// In en, this message translates to:
  /// **'or paste a link'**
  String get orPasteLink;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @inPlaylist.
  ///
  /// In en, this message translates to:
  /// **'In this playlist'**
  String get inPlaylist;

  /// No description provided for @addToNamedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to “{title}”'**
  String addToNamedPlaylist(String title);

  /// No description provided for @videoAddedNamed.
  ///
  /// In en, this message translates to:
  /// **'Added “{title}”'**
  String videoAddedNamed(String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
