import 'dart:math';

import 'local_store.dart';
import 'order.dart';
import 'remote.dart';

class SyncReport {
  var sent = 0;
  var refused = 0;
  var pulled = 0;
  var offline = false;

  @override
  String toString() => offline
      ? 'offline (sent $sent)'
      : 'sent $sent, refused $refused, pulled $pulled';
}

// أرسل ما ينتظر، ثم اجلب ما تغيّر. ويتوقف بهدوء بلا اتصال؛ ويحاول من جديد في المرة القادمة.
class SyncEngine {
  SyncEngine(this.local, this.remote);

  final LocalStore local;
  final FakeRemote remote;

  Future<SyncReport> sync() async {
    final report = SyncReport();
    try {
      for (final order in await local.outbox()) {
        try {
          // لا تُرسل إلا حقول الشخص؛ والجواب يقول كم صارت نسخة الخادم حديثة.
          final version = await remote.push(order);
          await local.put(
            order.copyWith(sync: SyncState.synced, version: version),
          );
          report.sent++;
        } on Refused catch (e) {
          // الرفض لا يتغير بإعادة المحاولة: علّمه وتابع.
          await local.put(
            order.copyWith(sync: SyncState.failed, error: e.reason),
          );
          report.refused++;
        }
      }
      // فقط ما تغيّر منذ آخر مزامنة: والمؤشر أعلى إصدار رأيناه.
      var cursor = await local.cursor();
      for (final change in await remote.changesSince(cursor)) {
        await _merge(change);
        cursor = max(cursor, change['version']! as int);
        report.pulled++;
      }
      await local.setCursor(cursor);
    } on Offline {
      report.offline = true;
    }
    return report;
  }

  // ادمج حقلاً حقلاً: حالة المقهى تغلب دائماً؛ وملاحظة الخادم فقط إن لم يكن لملاحظتنا تغيير لم يُرسل.
  Future<void> _merge(Map<String, Object> change) async {
    final id = change['id']! as String;
    final mine = await local.get(id);
    final status = change['status']! as String;
    final version = change['version']! as int;
    if (mine == null) {
      await local.put(
        Order(
          id: id,
          title: change['title']! as String,
          note: change['note']! as String,
          status: status,
          sync: SyncState.synced,
          version: version,
        ),
      );
    } else if (mine.sync == SyncState.queued) {
      await local.put(mine.copyWith(status: status));
    } else {
      await local.put(
        mine.copyWith(
          status: status,
          note: change['note']! as String,
          version: version,
        ),
      );
    }
  }
}
