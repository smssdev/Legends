import 'package:material_ui/material_ui.dart';

import 'motion/motion.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const OrderPage(),
    ),
  );
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final full = count > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('طلبك')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ضمنية: غيّر القيمة، فيتحرك الـ Widget إليها وحده.
            AnimatedContainer(
              key: const ValueKey('card'),
              duration: motion(context, Motion.medium),
              curve: Motion.move,
              height: full ? 180 : 96,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: full
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(full ? 28 : 12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'طلبك',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      // مفتاح جديد يعني ابناً جديداً: الرقم القديم يغادر والجديد يصل.
                      AnimatedSwitcher(
                        duration: motion(context, Motion.medium),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: CircleAvatar(
                          key: ValueKey(count),
                          child: Text('$count'),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: full ? 1 : 0,
                      duration: motion(context, Motion.medium),
                      curve: Motion.enter,
                      child: Text(
                        '${count * 45} جنيه',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => setState(() => count++),
              icon: const Icon(Icons.add),
              label: const Text('أضف لاتيه'),
            ),
          ],
        ),
      ),
    );
  }
}
