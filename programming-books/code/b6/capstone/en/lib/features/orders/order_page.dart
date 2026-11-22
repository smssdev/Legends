import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../design/tokens.dart';
import '../../state/providers.dart';

class OrderPage extends ConsumerWidget {
  const OrderPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(id));
    final status = order.value?.status;
    return Scaffold(
      appBar: AppBar(title: Text('Order $id')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(orderProvider(id).future),
        child: ListView(
          padding: const EdgeInsets.all(Space.l),
          children: [
            for (final (step, label) in const [
              (OrderStatus.received, 'Received'),
              (OrderStatus.preparing, 'Being prepared'),
              (OrderStatus.ready, 'Ready at the counter'),
            ])
              ListTile(
                leading: Icon(
                  status != null && status.index >= step.index
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                title: Text(label),
                selected: status == step,
              ),
          ],
        ),
      ),
    );
  }
}
