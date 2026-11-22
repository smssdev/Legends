import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

// When the network comes back, sync without being asked.
final autoSyncProvider = Provider<void>((ref) {
  ref.listen(onlineProvider, (wasOnline, online) {
    if (online && wasOnline == false) {
      ref.read(lastSyncProvider.notifier).run();
    }
  });
});
