import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'cafe_api.dart';
import 'models.dart';

// حين تفشل الشبكة ينتظر الطلب في صندوق الصادر ويُرسل لاحقاً (الفصل 6).
class Outbox {
  Outbox(this.api, this.prefs);

  final CafeApi api;
  final SharedPreferencesAsync prefs;

  Future<Order?> place(Map<String, int> lines) async {
    try {
      return await api.place(lines);
    } on SocketException {
      final waiting = await prefs.getStringList('outbox') ?? [];
      await prefs.setStringList('outbox', [...waiting, jsonEncode(lines)]);
      return null;
    }
  }

  Future<int> flush() async {
    final waiting = await prefs.getStringList('outbox') ?? [];
    var sent = 0;
    for (final lines in waiting) {
      try {
        await api.place(
          (jsonDecode(lines) as Map<String, Object?>).cast<String, int>(),
        );
        sent++;
      } on SocketException {
        break;
      }
    }
    await prefs.setStringList('outbox', waiting.sublist(sent));
    return sent;
  }
}
