import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';

/// [Sprint 15 F1] Whether this app may still talk to the server: `/health` says the oldest app version it accepts
/// (`game.app.min_version`); older, the app asks to be updated before anything else.
final updateRequiredProvider = FutureProvider<bool>((ref) async {
  final info = await PackageInfo.fromPlatform();
  try {
    final health = api.HealthAnswer.fromJson(await ref.read(apiProvider).get('/health'));
    return olderThan(info.version, health.minAppVersion);
  } catch (_) {
    // Offline: the screens say so themselves; never block on the check.
    return false;
  }
});

/// a < b by their numbers (1.2.10 after 1.2.9). Pure.
bool olderThan(String a, String b) {
  List<int> parts(String v) => v.split('+').first.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final m = i < x.length ? x[i] : 0, n = i < y.length ? y[i] : 0;
    if (m != n) return m < n;
  }
  return false;
}
