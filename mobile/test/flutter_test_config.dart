import 'dart:async';

import 'package:glm/ui/widgets/motion.dart';

/// Every widget test: the endless motion (the sheen, the pulse) off, so a screen can settle.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Ambient.on = false;
  await testMain();
}
