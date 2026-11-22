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

// Push what is waiting, then pull what changed. Stops quietly when offline; tries again next time.
class SyncEngine {
  SyncEngine(this.local, this.remote);

  final LocalStore local;
  final FakeRemote remote;

  Future<SyncReport> sync() async {
    final report = SyncReport();
    try {
      for (final order in await local.outbox()) {
        try {
          // Only the person's fields are sent; the answer says how new the server's copy now is.
          final version = await remote.push(order);
          await local.put(
            order.copyWith(sync: SyncState.synced, version: version),
          );
          report.sent++;
        } on Refused catch (e) {
          // A refusal will not change by retrying: mark it and move on.
          await local.put(
            order.copyWith(sync: SyncState.failed, error: e.reason),
          );
          report.refused++;
        }
      }
      // Only what changed since the last sync: the cursor is the highest version seen.
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

  // Merge field by field: the café's status always wins; the note from the server only if ours has no unsent change.
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
