import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/widgets/motion.dart';

/// [Sprint 59 F8] The screenshots against their references in goldens/ (the look of each screen, kept in the
/// repository like the web's e2e/visual.spec.ts): a change shows as a failure with its picture in failures/. A change
/// meant to be is written with `--update-goldens` in the same PR, after looking at it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // As every widget test: the endless motion (the sheen, the pulse) off, so a screen can settle.
  Ambient.on = false;
  final local = goldenFileComparator;
  if (local is LocalFileComparator) goldenFileComparator = TolerantComparator(local.basedir.resolve('shots_test.dart'));
  await testMain();
}

/// Pixel for pixel, with room only for a few faint edge pixels another machine may draw differently: 0.002 % of the
/// picture (about 26 of a screenshot's 1.3 million). One letter changed is more (an exclamation mark in a title: 119).
class TolerantComparator extends LocalFileComparator {
  TolerantComparator(super.testFile);

  static const tolerance = 0.00002;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
