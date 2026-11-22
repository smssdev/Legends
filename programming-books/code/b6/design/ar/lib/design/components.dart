import 'package:material_ui/material_ui.dart';

import 'context.dart';
import 'tokens.dart';

enum ButtonKind { primary, secondary }

// زر واحد للتطبيق كله؛ والشاشات تختار ما يعنيه، لا كيف يبدو.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Space.s,
      children: [if (icon != null) Icon(icon, size: 18), Text(label)],
    );
    return switch (kind) {
      ButtonKind.primary => FilledButton(onPressed: onPressed, child: child),
      ButtonKind.secondary => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
    };
  }
}

enum TagKind { success, warning, neutral }

// الوسم يقول شيئاً واحداً بنظرة: ونوعه يختار الألوان.
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    this.kind = TagKind.neutral,
  });

  final String label;
  final TagKind kind;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final (background, foreground) = switch (kind) {
      TagKind.success => (brand.success, brand.onSuccess),
      TagKind.warning => (brand.warning, brand.onWarning),
      TagKind.neutral => (brand.muted, context.colors.onSurface),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.s),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s,
          vertical: Space.xs,
        ),
        child: Text(
          label,
          style: context.text.labelMedium!.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(Space.m), child: child),
  );
}

// فراغ من المقياس: الشاشات لا تكتب رقماً أبداً.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
