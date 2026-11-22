import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

// حين تعود الشبكة، زامن دون أن يُطلب منك.
final autoSyncProvider = Provider<void>((ref) {
  ref.listen(onlineProvider, (wasOnline, online) {
    if (online && wasOnline == false) {
      ref.read(lastSyncProvider.notifier).run();
    }
  });
});
