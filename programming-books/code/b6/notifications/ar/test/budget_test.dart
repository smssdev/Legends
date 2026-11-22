import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/background/budget.dart';
import 'package:bit_app/background/orders_api.dart';

class SlowApi implements OrdersApi {
  SlowApi(this.delay);

  final Duration delay;

  @override
  Future<List<Order>> mine() =>
      Future.delayed(delay, () => const [Order('42', true)]);
}

class MemorySeen implements Seen {
  final ids = <String>{};

  @override
  Future<bool> contains(String id) async => ids.contains(id);

  @override
  Future<void> add(String id) async => ids.add(id);
}

class Recorded implements Notify {
  final sent = <String>[];

  @override
  Future<void> orderReady(String id) async => sent.add(id);
}

void main() {
  test('شبكة بطيئة: توقف مبكراً وأعد المحاولة لاحقاً', () {
    fakeAsync((time) {
      final seen = MemorySeen();
      final notify = Recorded();
      Outcome? slow;
      Outcome? fast;
      syncWithin(
        const Duration(seconds: 20),
        SlowApi(const Duration(seconds: 45)),
        seen,
        notify,
      ).then((o) => slow = o);
      time.elapse(const Duration(seconds: 60));
      syncWithin(
        const Duration(seconds: 20),
        SlowApi(const Duration(seconds: 2)),
        seen,
        notify,
      ).then((o) => fast = o);
      time.elapse(const Duration(seconds: 60));
      debugPrint(
        'network answers in 45 s: ${slow!.name}; in 2 s: ${fast!.name}; notified ${notify.sent}',
      );
      expect((slow, fast), (Outcome.retry, Outcome.done));
    });
  });
}
