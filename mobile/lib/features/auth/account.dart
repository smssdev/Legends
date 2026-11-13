import '../../api/gen/models.g.dart' as api;

/// [Sprint 15 F3] The signed-in account, as `/auth/me` and the sign-in give it (only what the app uses).
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.accountNo,
    this.avatarUrl,
    this.admin = false,
    this.guest = false,
  });

  /// [Sprint 59 F1] From the generated model (`Account` in openapi.yaml).
  factory Account.of(api.Account a) => Account(
    id: a.id,
    name: a.name,
    username: a.username,
    email: a.email,
    accountNo: a.accountNo,
    avatarUrl: a.avatarUrl,
    admin: a.role == 'admin',
    guest: a.guest ?? false,
  );

  final int id;
  final String name;
  final String username;
  final String? email;
  final int? accountNo;
  final String? avatarUrl;
  final bool admin;

  /// [Sprint 50 M5] Playing as a guest until the account is kept.
  final bool guest;
}
