import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class Favorites extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async =>
      (await ref.watch(prefsProvider).getStringList('favorites') ?? const [])
          .toSet();

  Future<void> toggle(String id) async {
    final current = await future;
    final next = current.contains(id)
        ? ({...current}..remove(id))
        : {...current, id};
    await ref
        .read(prefsProvider)
        .setStringList('favorites', next.toList()..sort());
    state = AsyncData(next);
  }
}

final favoritesProvider = AsyncNotifierProvider<Favorites, Set<String>>(
  Favorites.new,
);
