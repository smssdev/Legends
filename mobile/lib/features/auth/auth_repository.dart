import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/storage/token_store.dart';
import 'account.dart';

/// [Sprint 15 F3] The account on the API: the app signs in by token (`/auth/token`, 30 days), signs up with the same
/// three fields as the web, asks for the password link, and gives its token back when it signs out.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Future<Account?> current() async {
    if (await _tokens.read() == null) return null;
    // [Sprint 61 F8] The app's start in one request, as the web's (Sprint 58 B1): the account, and the unread count the
    // inbox's badge takes once instead of asking for it.
    final b = api.BootstrapAnswer.fromJson(await _api.get('/bootstrap'));
    Bootstrap.unread = b.unread;
    return b.user == null ? null : Account.of(b.user!);
  }

  Future<Account> signIn(String login, String password) async {
    final data = await _api.post('/auth/token', {'email': login.trim(), 'password': password, 'device_name': AppConfig.deviceName});
    return _keep(data);
  }

  Future<Account> register({required String name, required String username, String? email, required String password}) async {
    final data = await _api.post('/auth/register', {
      'name': name.trim(),
      'username': username.trim().toLowerCase(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'password': password,
      'device_name': AppConfig.deviceName,
    });
    return _keep(data);
  }

  /// [Sprint 50 M5] Playing as a guest: an account the server makes, kept on this phone by its token.
  Future<Account> guest() async => _keep(await _api.post('/auth/guest', {'device_name': AppConfig.deviceName}));

  /// [Sprint 50 M5] The guest keeps the account with a name, a username and a password (an email if typed).
  Future<Account> keepGuest({required String name, required String username, String? email, required String password}) async {
    final data = await _api.post('/auth/guest/keep', {
      'name': name.trim(),
      'username': username.trim().toLowerCase(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'password': password,
    });
    return Account.of(api.AccountAnswer.fromJson(data).user!);
  }

  Future<void> forgot(String email) => _api.post('/auth/forgot-password', {'email': email.trim()});

  Future<void> signOut() async {
    try {
      await _api.delete('/auth/token');
    } catch (_) {
      // Offline or already gone: the phone forgets it anyway.
    }
    await _tokens.clear();
  }

  Future<Account> _keep(Map<String, dynamic> data) async {
    final answer = api.AccountTokenAnswer.fromJson(data);
    await _tokens.write(answer.token!);
    return Account.of(answer.user);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiProvider), ref.watch(tokenStoreProvider)));

/// [Sprint 61 F8] What the start's `/bootstrap` brought for the screens that open first, each taken once.
class Bootstrap {
  static int? unread;

  static int? takeUnread() {
    final u = unread;
    unread = null;
    return u;
  }
}
