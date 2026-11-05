import 'package:flutter/material.dart';

import '../theme.dart';

/// [Sprint 15 F2] The screens' ground as on the web: a night pitch glow (or warm paper by day) behind everything.
class GlmBackground extends StatelessWidget {
  const GlmBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.1),
          radius: 1.35,
          colors: context.glm.day ? [p.surface, p.bg, p.bgDeep] : [Color.lerp(p.brandDark, p.bg, .55)!, p.bg, p.bgDeep],
          stops: const [0, .55, 1],
        ),
      ),
      child: child,
    );
  }
}

/// A short message at the bottom (the web's toast): an error in red, the rest quiet.
void showGlmToast(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? p.live : p.surfaceRaised,
      duration: Duration(seconds: error ? 5 : 3),
    ));
}
