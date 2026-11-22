import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cafe_api.dart';
import 'models.dart';

class MenuRepository {
  MenuRepository(this.api, this.prefs);

  final CafeApi api;
  final SharedPreferencesAsync prefs;

  // القائمة المحفوظة أولاً، فوراً؛ ثم الجديدة حين تصل.
  Stream<(List<Drink>, {bool fresh})> watch() async* {
    final saved = await prefs.getString('menu');
    if (saved != null) {
      yield (
        [
          for (final item in jsonDecode(saved) as List)
            Drink.fromJson(item as Map<String, Object?>),
        ],
        fresh: false,
      );
    }
    final menu = await api.menu();
    await prefs.setString(
      'menu',
      jsonEncode([for (final drink in menu) drink.toJson()]),
    );
    yield (menu, fresh: true);
  }
}
