import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'cafe.dart';
import 'demo_push.dart';
import 'push/message.dart';

void main() {
  final push = DemoPush();
  runApp(CafeApp(push: push));
  Timer(const Duration(seconds: 1), () {
    push.foregroundMessages.add(
      const PushMessage(
        PushKind.orderReady,
        orderId: '42',
        title: 'Your latte is ready',
        body: 'Order 42 is waiting at the counter.',
      ),
    );
  });
}
