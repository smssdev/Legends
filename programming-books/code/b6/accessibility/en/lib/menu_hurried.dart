import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const HurriedMenu()));

class HurriedMenu extends StatelessWidget {
  const HurriedMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final (name, about, price) in drinks)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 12,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_cafe,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                about,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('$price EGP'),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(Icons.favorite_border, size: 20),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 64,
            color: colors.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Total: 90 EGP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                FilledButton(onPressed: () {}, child: const Text('Check out')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
