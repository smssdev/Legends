import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';

/// [Sprint 15 F1] The start (the crest breathing while the account is checked), "update the app", and "no connection".
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GlmBackground(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const BrandMark(size: 120, stacked: true),
              const SizedBox(height: 36),
              SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3, color: context.palette.gold)),
            ]),
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, required this.action, required this.onPressed});

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GlmBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const BrandMark(size: 72, stacked: true),
                  const SizedBox(height: 36),
                  Icon(icon, size: 48, color: context.palette.gold),
                  const SizedBox(height: 14),
                  Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(body, style: context.text.bodyMedium?.copyWith(color: context.palette.textMuted), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  GlmButton(label: action, onPressed: onPressed),
                ]),
              ),
            ),
          ),
        ),
      );
}

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _Message(icon: Icons.system_update_rounded, title: l.updateTitle, body: l.updateBody, action: l.update,
        onPressed: () => launchUrl(Uri.parse(AppConfig.siteUrl), mode: LaunchMode.externalApplication));
  }
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _Message(icon: Icons.wifi_off_rounded, title: l.offlineTitle, body: message, action: l.retry, onPressed: onRetry);
  }
}
