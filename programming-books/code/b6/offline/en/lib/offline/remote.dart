import 'dart:async';

import 'order.dart';

class Offline implements Exception {
  const Offline();
}

class Refused implements Exception {
  const Refused(this.reason);
  final String reason;
}

// The café's server, pretended: it can go offline, lose an answer, refuse an order, and change statuses by itself.
class FakeRemote {
  var online = true;
  var loseNextAnswer = false;
  final soldOut = <String>{};
  final orders = <String, Map<String, Object>>{};
  var _version = 0;

  void _check() {
    if (!online) {
      throw const Offline();
    }
  }

  Future<int> push(Order order) async {
    _check();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (soldOut.contains(order.title)) {
      throw const Refused('Sold out');
    }
    // The order id is the idempotency key: the same order sent twice is stored once.
    final saved = orders.putIfAbsent(
      order.id,
      () => {'title': order.title, 'status': 'new'},
    );
    saved['note'] = order.note;
    saved['version'] = ++_version;
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw const Offline();
    }
    return _version;
  }

  Future<List<Map<String, Object>>> changesSince(int version) async {
    _check();
    return [
      for (final MapEntry(:key, :value) in orders.entries)
        if ((value['version']! as int) > version) {...value, 'id': key},
    ];
  }

  /// The café's side: the barista changes an order's status.
  void setStatus(String id, String status) {
    orders[id]!
      ..['status'] = status
      ..['version'] = ++_version;
  }
}
