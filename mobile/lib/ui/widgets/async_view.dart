import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import 'glm_button.dart';

/// [Sprint 16] One way for every screen to wait, fail and show: a spinner, the API's message with «try again», or
/// the data. Keeps the previous data on screen while it refreshes.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.value as T);
    if (value.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 40, color: context.palette.textMuted),
            const SizedBox(height: 10),
            Text(ApiError.from(value.error!).message, textAlign: TextAlign.center, style: TextStyle(color: context.palette.textSoft)),
            if (onRetry != null) ...[const SizedBox(height: 14), GlmButton(label: L.of(context).retry, variant: GlmButtonVariant.quiet, onPressed: onRetry)],
          ]),
        ),
      );
    }
    return Center(child: CircularProgressIndicator(color: context.palette.gold));
  }
}

/// A section's title in a list, as the web's h2.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Row(children: [Expanded(child: Text(text, style: context.text.titleLarge)), ?trailing]),
      );
}
