import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../ui/widgets/glm_background.dart';
import 'shell.dart';

/// [Sprint 59 F4] What every screen of the game shares, once (each library had its own copy): a screen in the frame
/// with its title, and an action whose refusal shows the server's reason.

/// A screen of the game: its title in the bar (with its actions), its body on the background, and a button if any.
Widget screenPage(String title, Widget body, {List<Widget>? actions, Widget? fab}) => Scaffold(
  appBar: GameBar(title: Text(title), actions: actions),
  floatingActionButton: fab,
  body: GlmBackground(child: body),
);

/// Runs [action]; a refusal shows its reason and gives null.
Future<T?> tryAction<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

/// `x.let((x) => ...)`: a value passed on to a function (Kotlin's let), for a null check in an expression.
extension Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
