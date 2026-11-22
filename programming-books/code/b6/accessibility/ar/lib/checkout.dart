import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const Checkout(ordered: true)));

class Checkout extends StatelessWidget {
  const Checkout({super.key, required this.ordered});

  final bool ordered;

  @override
  Widget build(BuildContext context) {
    final pay = FilledButton(
      focusNode: FocusNode(debugLabel: 'pay'),
      onPressed: () {},
      child: const Text('ادفع'),
    );
    final page = Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        // «ادفع» مرسوم في الأعلى، لكن يجب أن يُبلغ أخيراً، بعد الحقول.
        actions: [
          ordered
              ? FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: pay,
                )
              : pay,
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: TextField(
                focusNode: FocusNode(debugLabel: 'name'),
                decoration: const InputDecoration(labelText: 'اسمك'),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: TextField(
                focusNode: FocusNode(debugLabel: 'phone'),
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
            ),
          ],
        ),
      ),
    );
    return ordered
        ? FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: page)
        : page;
  }
}
