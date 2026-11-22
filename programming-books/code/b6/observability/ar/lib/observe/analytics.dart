import 'dart:async';

abstract interface class EventTransport {
  Future<void> send(List<Map<String, Object?>> batch);
}

class Analytics {
  Analytics(
    this.transport, {
    this.batchSize = 10,
    this.every = const Duration(seconds: 30),
  });

  final EventTransport transport;
  final int batchSize;
  final Duration every;
  final _queue = <Map<String, Object?>>[];
  var _consent = false;
  Timer? _timer;

  // لا يُجمع شيء قبل موافقة المستخدم، ويُحذف كل ما في الطابور حين يرفض.
  void setConsent(bool granted) {
    _consent = granted;
    if (!granted) {
      _queue.clear();
      _timer?.cancel();
    }
  }

  void log(String name, [Map<String, Object?> params = const {}]) {
    if (!_consent) {
      return;
    }
    _queue.add({'name': name, ...params});
    // الأحداث تسافر دفعات: طلبات أقل، وبطارية أقل.
    if (_queue.length >= batchSize) {
      flush();
    } else {
      _timer ??= Timer(every, flush);
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) {
      return;
    }
    final batch = List.of(_queue);
    _queue.clear();
    await transport.send(batch);
  }
}
