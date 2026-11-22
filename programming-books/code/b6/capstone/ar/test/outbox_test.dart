import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/models.dart';
import 'package:bit_app/data/outbox.dart';

import 'fakes.dart';

class FlakyApi extends FakeApi {
  var online = false;

  @override
  Future<Order> place(Map<String, int> lines) {
    if (!online) {
      throw const SocketException('Network is unreachable');
    }
    return super.place(lines);
  }
}

void main() {
  test('طلب أُرسل دون اتصال يُرسل حين تعود الشبكة', () async {
    final api = FlakyApi();
    final outbox = Outbox(api, memoryPrefs());
    final order = await outbox.place({'latte': 1});
    debugPrint(
      'offline: order ${order?.id ?? 'queued'}, sent to the server: ${api.placed.length}',
    );
    expect(await outbox.flush(), 0);
    api.online = true;
    debugPrint(
      'back online: ${await outbox.flush()} sent, server received ${api.placed}',
    );
    expect(await outbox.flush(), 0);
  });
}
