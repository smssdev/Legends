import 'package:material_ui/material_ui.dart';

import 'motion/motion.dart';

// One transition for every page of the app, set once in the theme.
class FadeSlideTransitions extends PageTransitionsBuilder {
  const FadeSlideTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData themed(ThemeData base) => base.copyWith(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeSlideTransitions(),
      TargetPlatform.iOS: FadeSlideTransitions(),
    },
  ),
);

class StepPage extends StatelessWidget {
  const StepPage({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$n')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => StepPage(n: n + 1))),
        child: const Text('Next step'),
      ),
    ),
  );
}
