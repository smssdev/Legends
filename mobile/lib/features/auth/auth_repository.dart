import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final data = await _api.get('/auth/me');
    final user = data['user'];
    return user is Map<String, dynamic> ? Account.fromJson(user) : null;
  }

  Future<Account> signIn(String login, String password) async {
    final data = await _api.post('/auth/token', {'email': login.trim(), 'password': password, 'device_name': AppConfig.deviceName});
    return _keep(data);
  }

  Future<Account> register({required String name, required String username, String? email, required String password}) async {
    final data = await _api.post('/auth/register', {
      'name': name.trim(), 'username': username.trim().toLowerCase(), if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'password': password, 'device_name': AppConfig.deviceName,
    });
    return _keep(data);
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
    await _tokens.write(data['token'] as String);
    return Account.fromJson(data['user'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiProvider), ref.watch(tokenStoreProvider)));
