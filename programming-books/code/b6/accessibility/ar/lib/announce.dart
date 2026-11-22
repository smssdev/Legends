import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const OrderCounter()));

class OrderCounter extends StatefulWidget {
  const OrderCounter({super.key});

  @override
  State<OrderCounter> createState() => _OrderCounterState();
}

class _OrderCounterState extends State<OrderCounter> {
  var count = 0;

  void add() {
    setState(() => count++);
    // أخبر مستخدمي قارئ الشاشة بما تغيّر، فهم لا يرون الشارة.
    SemanticsService.sendAnnouncement(
      View.of(context),
      'لاتيه أُضيف, $count قطع في طلبك',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبك'),
        actions: [
          Badge.count(count: count, child: const Icon(Icons.local_cafe)),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: FilledButton(onPressed: add, child: const Text('أضف لاتيه')),
      ),
    );
  }
}
