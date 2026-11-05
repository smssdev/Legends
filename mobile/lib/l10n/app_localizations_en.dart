// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Game Legend Manager';

  @override
  String get tagline => 'A free online football manager';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInLead => 'Sign in to carry on your season';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot it?';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get createAccount => 'Create one';

  @override
  String get haveAccount => 'Have an account?';

  @override
  String get registerTitle => 'Your new account';

  @override
  String get registerLead =>
      'Three fields and you start: your name, a username and a password';

  @override
  String get displayName => 'Your display name';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'English letters and digits, 3 to 20';

  @override
  String get emailOptional => 'Email (optional, to get your password back)';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get acceptTerms => 'I accept the terms and the privacy policy';

  @override
  String get termsAndPrivacy => 'Terms and privacy policy';

  @override
  String get mustAcceptTerms => 'Accept the terms and the privacy policy first';

  @override
  String get register => 'Create the account';

  @override
  String get forgotTitle => 'Get your password back';

  @override
  String get forgotLead =>
      'Type your account\'s email and we send you a link for a new password';

  @override
  String get email => 'Email';

  @override
  String get sendLink => 'Send the link';

  @override
  String get linkSent =>
      'If the email belongs to an account, the link is on its way. Open it from your inbox.';

  @override
  String get required => 'Required';

  @override
  String get google => 'Continue with Google';

  @override
  String get googleSoon => 'Google sign-in is coming to the app soon';

  @override
  String get orByEmail => 'or by email';

  @override
  String get updateTitle => 'Update the app';

  @override
  String get updateBody =>
      'A new version of the game is out, and this one no longer works with it. Update the app to carry on.';

  @override
  String get update => 'Update now';

  @override
  String get offlineTitle => 'No connection';

  @override
  String get retry => 'Try again';

  @override
  String get greetingMorning => 'Good morning, coach';

  @override
  String get greetingEvening => 'Good evening, coach';

  @override
  String get coins => 'coins';

  @override
  String get myTeams => 'My teams';

  @override
  String slotsOpen(int open, int total) {
    return '$open of $total';
  }

  @override
  String get slotFree => 'Free slot';

  @override
  String get slotWaiting => 'A join request waits for its answer';

  @override
  String get slotLocked => 'Locked';

  @override
  String slotOpensIn(String time) {
    return 'Opens free in $time';
  }

  @override
  String get createLeague => 'Make a league';

  @override
  String get joinByCode => 'Join with a code';

  @override
  String get openClub => 'Open the club';

  @override
  String get nextMatch => 'Next match';

  @override
  String vs(String club) {
    return 'vs $club';
  }

  @override
  String position(int n, int of) {
    return 'Place $n of $of';
  }

  @override
  String waitsForYou(int n) {
    return '$n waiting for you';
  }

  @override
  String record(int w, int d, int l) {
    return '$w won · $d drawn · $l lost';
  }

  @override
  String get onWebForNow => 'Opens on the site until it reaches the app';

  @override
  String get settings => 'Settings';

  @override
  String get look => 'Look';

  @override
  String get lookAuto => 'Automatic';

  @override
  String get lookNight => 'Night';

  @override
  String get lookDay => 'Day';

  @override
  String get language => 'Language';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out on this phone?';

  @override
  String get cancel => 'Cancel';

  @override
  String accountNo(int n) {
    return 'Your account number $n';
  }

  @override
  String days(int n) {
    return '$n d';
  }

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get tierProspect => 'Prospect';

  @override
  String get tierTactician => 'Tactician';

  @override
  String get tierProfessional => 'Professional';

  @override
  String get tierElite => 'Elite';

  @override
  String get tierMastermind => 'Mastermind';

  @override
  String get tierIcon => 'Icon';

  @override
  String get tierLegend => 'Legend';
}
