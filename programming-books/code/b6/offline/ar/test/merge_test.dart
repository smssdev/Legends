import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/offline/local_store.dart';
import 'package:bit_app/offline/order.dart';
import 'package:bit_app/offline/remote.dart';
import 'package:bit_app/offline/sync_engine.dart';

void main() {
  test('ملاحظة كُتبت بلا اتصال وحالة المقهى الجديدة تبقيان معاً', () async {
    final local = MemoryLocalStore();
    final remote = FakeRemote();
    final engine = SyncEngine(local, remote);
    await local.put(const Order(id: 'a', title: 'Latte'));
    await engine.sync();

    // بلا اتصال يضيف الشخص ملاحظة؛ وفي الأثناء يعلّم المقهى الطلب جاهزاً.
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
  });
}
