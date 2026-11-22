import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

String mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';

Future<ui.Image> decode(Uint8List bytes, {int? width}) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  return (await codec.getNextFrame()).image;
}

void main() {
  testWidgets('the memory of a decoded photo', (tester) async {
    await tester.runAsync(() async {
      final file = await File('assets/photos/latte.jpg').readAsBytes();
      final full = await decode(file);
      final small = await decode(file, width: 168);
      debugPrint('file on disk:            ${mb(file.length)}');
      debugPrint(
        'decoded, full size:      ${full.width} x ${full.height}, ${mb(full.width * full.height * 4)}',
      );
      debugPrint(
        'decoded, cacheWidth 168: ${small.width} x ${small.height}, ${mb(small.width * small.height * 4)}',
      );
    });
  });
}
