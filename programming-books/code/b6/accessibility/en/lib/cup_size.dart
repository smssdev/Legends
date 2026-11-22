import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const Scaffold(body: Center(child: CupSize()))));

class CupSize extends StatefulWidget {
  const CupSize({super.key});

  @override
  State<CupSize> createState() => _CupSizeState();
}

class _CupSizeState extends State<CupSize> {
  var chosen = 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const sizes = ['Small', 'Medium', 'Large'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (final (i, size) in sizes.indexed)
          // A custom control must say what it is, and which choice is selected.
          Semantics(
            button: true,
            selected: i == chosen,
            inMutuallyExclusiveGroup: true,
            label: 'Cup size: $size',
            excludeSemantics: true,
            onTap: () => setState(() => chosen = i),
            child: GestureDetector(
              onTap: () => setState(() => chosen = i),
              child: Container(
                constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: i == chosen
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: i == chosen ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
