import 'package:flutter/material.dart';

import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/glm_background.dart';

/// [Sprint 15 F3] The sign-in screens' frame (MobileLogin.dc.html): the mark at the top, the form in the middle,
/// the way to the other screen at the bottom; scrolls above the keyboard.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.lead, required this.children, this.footer});

  final String title;
  final String lead;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: GlmBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandMark(size: 92, stacked: true)),
                      const SizedBox(height: 32),
                      Text(title, textAlign: TextAlign.center, style: text.headlineMedium),
                      const SizedBox(height: 6),
                      Text(lead, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      ...children,
                      if (footer != null) ...[const SizedBox(height: 28), Center(child: footer!)],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
