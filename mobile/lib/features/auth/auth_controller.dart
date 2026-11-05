import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../notifications/push.dart';
import 'account.dart';
import 'auth_repository.dart';

/// [Sprint 15 F3] Who is signed in: loading at the start, then an account or nobody. A 401 anywhere signs out.
class AuthController extends AsyncNotifier<Account?> {
  @override
  Future<Account?> build() async {
    ref.listen(unauthorizedProvider, (_, _) => _forget());
    try {
      return await ref.read(authRepositoryProvider).current();
    } on ApiError catch (e) {
      // Offline at the start: the stored token stays, and the screen offers to try again.
      if (e.offline) rethrow;
      await ref.read(tokenStoreProvider).clear();
      return null;
    }
  }

  Future<void> signIn(String login, String password) async {
    state = AsyncData(await ref.read(authRepositoryProvider).signIn(login, password));
  }

  Future<void> register({required String name, required String username, String? email, required String password}) async {
    state = AsyncData(await ref.read(authRepositoryProvider).register(name: name, username: username, email: email, password: password));
  }

  Future<void> signOut() async {
    // [Sprint 19 F1] This phone stops getting the account's pushes (while the token is still good).
    await ref.read(pushProvider).forget();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  Future<void> _forget() async {
    if (state.value == null) return;
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, Account?>(AuthController.new);
