import 'package:material_ui/material_ui.dart';

import '../design/components.dart';
import '../design/context.dart';
import '../design/tokens.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.l, bottom: Space.s),
      child: Text(text, style: context.text.titleMedium),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Components'), actions: actions),
      body: ListView(
        padding: const EdgeInsets.all(Space.m),
        children: [
          title('Buttons'),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              AppButton(label: 'Order', icon: Icons.add, onPressed: () {}),
              AppButton(
                label: 'Details',
                kind: ButtonKind.secondary,
                onPressed: () {},
              ),
              const AppButton(label: 'Order', onPressed: null),
            ],
          ),
          title('Tags'),
          const Wrap(
            spacing: Space.s,
            children: [
              StatusTag(label: 'Ready', kind: TagKind.success),
              StatusTag(label: 'Almost sold out', kind: TagKind.warning),
              StatusTag(label: 'New'),
            ],
          ),
          title('Cards'),
          AppCard(
            child: Text(
              'Espresso and steamed milk',
              style: context.text.bodyLarge,
            ),
          ),
          title('Space'),
          for (final (name, size) in [
            ('xs', Space.xs),
            ('s', Space.s),
            ('m', Space.m),
            ('l', Space.l),
            ('xl', Space.xl),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: Space.xl,
                    child: Text(name, style: context.text.labelMedium),
                  ),
                  Container(
                    width: size * 4,
                    height: Space.s,
                    color: context.brand.accent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
