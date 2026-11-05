/// [Sprint 15 F3] The signed-in account, as `/auth/me` and the sign-in give it (only what the app uses).
class Account {
  const Account({required this.id, required this.name, required this.username, this.email, this.accountNo, this.avatarUrl, this.admin = false});

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as int,
        name: '${j['name'] ?? ''}',
        username: '${j['username'] ?? ''}',
        email: j['email'] as String?,
        accountNo: j['account_no'] as int?,
        avatarUrl: j['avatar_url'] as String?,
        admin: j['role'] == 'admin',
      );

  final int id;
  final String name;
  final String username;
  final String? email;
  final int? accountNo;
  final String? avatarUrl;
  final bool admin;
}
