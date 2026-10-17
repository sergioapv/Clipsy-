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
  /// **'Your playlists will appear here. Creating them arrives in the next update.'**
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
