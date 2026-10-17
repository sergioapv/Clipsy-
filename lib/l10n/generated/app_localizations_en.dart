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
      'Your playlists will appear here. Creating them arrives in the next update.';

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
}
