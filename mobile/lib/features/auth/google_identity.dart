import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config.dart';
import '../../core/crash_reports.dart';

/// [X107] What Google gives the app to sign in with: the id_token of the account the player picks. The API checks it
/// (POST /auth/google/token) and makes the game's account; the app trusts nothing in it.
abstract class GoogleIdentity {
  /// The id_token of the account picked, or null when the player closed the sheet. Throws [GoogleIdentityError] when
  /// Google cannot sign in on this phone.
  Future<String?> idToken();
}

/// Why Google gave no token: a code of the plugin (clientConfigurationError, …), `no_id_token`, or `other`.
class GoogleIdentityError implements Exception {
  const GoogleIdentityError(this.code);

  final String code;

  @override
  String toString() => code;
}

/// Google Sign-In on the phone (the plugin's Credential Manager on Android), made for the game's web client
/// (`AppConfig.googleServerClientId`) so the token's audience is the one the API accepts.
class GoogleSignInIdentity implements GoogleIdentity {
  GoogleSignInIdentity([GoogleSignIn? signIn]) : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  Future<void>? _ready;

  @override
  Future<String?> idToken() async {
    String? token;
    try {
      _ready ??= _signIn.initialize(serverClientId: AppConfig.googleServerClientId);
      await _ready;
      token = (await _signIn.authenticate()).authentication.idToken;
    } on GoogleSignInException catch (e, s) {
      // A wrong or missing SHA-1 in Google Cloud often arrives as "canceled" (the plugin cannot tell it from a player
      // closing the sheet), so every outcome is counted: the admin panel's device errors show which one is happening.
      CrashReports.report(GoogleIdentityError(e.code.name), s);
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) return null;
      throw GoogleIdentityError(e.code.name);
    } catch (e, s) {
      _ready = null; // the plugin could not start: it starts again at the next tap
      CrashReports.report(GoogleIdentityError('other: ${e.runtimeType}'), s);
      throw const GoogleIdentityError('other');
    }
    if (token == null || token.isEmpty) {
      CrashReports.report(const GoogleIdentityError('no_id_token'), StackTrace.current);
      throw const GoogleIdentityError('no_id_token');
    }
    return token;
  }
}

final googleIdentityProvider = Provider<GoogleIdentity>((ref) => GoogleSignInIdentity());
