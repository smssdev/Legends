import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/local_store.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  test(
    'an offline note and the new status from the café both survive',
    () async {
      final local = MemoryLocalStore();
      final remote = FakeRemote();
      final engine = SyncEngine(local, remote);
      await local.put(const Order(id: 'a', title: 'Latte'));
      await engine.sync();

      // Offline, the person adds a note; meanwhile, the café marks the order ready.
      remote.online = false;
      final mine = (await local.get('a'))!;
      await local.put(mine.copyWith(note: 'No sugar', sync: SyncState.queued));
      remote.setStatus('a', 'ready');

      remote.online = true;
      await engine.sync();
      final merged = (await local.get('a'))!;
      expect(merged.note, 'No sugar');
      expect(merged.status, 'ready');
      expect(remote.orders['a']!['note'], 'No sugar');
      expect(remote.orders['a']!['status'], 'ready');
    },
  );
}
