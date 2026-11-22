import 'package:material_ui/material_ui.dart';

import '../design/components.dart';
import '../design/context.dart';
import '../design/tokens.dart';

// شاشة حقيقية: لا شيء غير المكونات والرموز والثيم.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'لاتيه',
        'إسبريسو وحليب مبخّر',
        45,
        const StatusTag(label: 'جديد', kind: TagKind.success),
      ),
      ('شاي بالنعناع', 'نعناع طازج وقليل من السكر', 25, null),
      (
        'كيك الكرز',
        'خُبز هذا الصباح',
        60,
        const StatusTag(label: 'أوشك أن ينفد', kind: TagKind.warning),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة'), actions: actions),
      body: ListView.separated(
        padding: const EdgeInsets.all(Space.m),
        itemCount: items.length,
        separatorBuilder: (context, i) => const Gap(Space.m),
        itemBuilder: (context, i) {
          final (name, description, price, tag) = items[i];
          return MenuCard(
            name: name,
            description: description,
            price: price,
            tag: tag,
          );
        },
      ),
    );
  }
}

// كل بطاقة Widget خاص بها، فتقرأ الثيم من الـ context الخاص بها، وتُبنى من جديد حين يتغير الثيم.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    this.tag,
  });

  final String name;
  final String description;
  final int price;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: context.text.titleLarge)),
              ?tag,
            ],
          ),
          const Gap(Space.xs),
          Text(
            description,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const Gap(Space.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$price جنيه',
                  style: context.text.titleMedium!.copyWith(
                    color: context.brand.accent,
                  ),
                ),
              ),
              AppButton(label: 'اطلب', icon: Icons.add, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
