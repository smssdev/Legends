import 'dart:convert';

/// FNV-1a over [text]'s bytes, 64 bits as 16 hex digits: a short, steady file name (the saved answers, the pictures).
String fnv64(String text) {
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode(text)) {
    h = (h ^ b) * 0x100000001b3;
  }
  // Dart's ints are signed: the two halves written apart.
  String half(int v) => v.toRadixString(16).padLeft(8, '0');
  return half((h >>> 32) & 0xffffffff) + half(h & 0xffffffff);
}
