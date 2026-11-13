import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/settings.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glm_button.dart';
import '../auth/auth_controller.dart';

/// [Sprint 15] This phone's settings: the look (automatic by default, as the web since Sprint 43 A1), the language,
/// the account number, the app's version, and signing out.
Future<void> showSettingsSheet(BuildContext context, {int? accountNo}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  backgroundColor: context.palette.panel,
  builder: (_) => _SettingsSheet(accountNo: accountNo),
);

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet({this.accountNo});

  final int? accountNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final s = ref.watch(settingsProvider);
    final settings = ref.read(settingsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.settings, style: context.text.titleLarge),
            const SizedBox(height: 16),
            Text(l.look, style: context.text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.lookAuto), icon: const Icon(Icons.phone_android_rounded)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.lookNight), icon: const Icon(Icons.dark_mode_rounded)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.lookDay), icon: const Icon(Icons.light_mode_rounded)),
              ],
              selected: {s.theme},
              onSelectionChanged: (v) => settings.setTheme(v.first),
            ),
            const SizedBox(height: 18),
            Text(l.language, style: context.text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ar', label: Text('العربية')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {s.language},
              onSelectionChanged: (v) => settings.setLanguage(v.first),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(s.sounds ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: context.palette.gold),
              title: Text(l.gameSounds),
              value: s.sounds,
              activeThumbColor: context.palette.gold,
              onChanged: (v) {
                settings.setSounds(v);
                GameSounds.enabled = v;
                if (v) GameSounds.play(Sfx.confirm);
              },
            ),
            // [Sprint 63 G13] The levels, the site's same (its third, the commentator, waits for a voice in the app).
            if (s.sounds)
              for (final (which, label, value, sample) in [
                ('ui', l.soundInterface, s.soundUi, Sfx.confirm),
                ('stadium', l.soundStadium, s.soundStadium, Sfx.whistle),
              ])
                Row(
                  children: [
                    SizedBox(width: 96, child: Text(label, style: context.type.body)),
                    Expanded(
                      child: Slider(
                        value: value.toDouble(),
                        max: 100,
                        divisions: 20,
                        label: '$value%',
                        activeColor: context.palette.gold,
                        onChanged: (v) {
                          settings.setLevel(which, v.round());
                          if (which == 'ui') {
                            GameSounds.ui = v.round();
                          } else {
                            GameSounds.stadium = v.round();
                          }
                        },
                        onChangeEnd: (_) => GameSounds.play(sample),
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 4),
            // [Sprint 18 F] The account: name, look, password, invites and badges; and the community's pages from it.
            ListTile(
              leading: Icon(Icons.person_rounded, color: context.palette.gold),
              title: Text(l.profile),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events_rounded, color: context.palette.gold),
              title: Text(l.tournaments),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push('/tournaments');
              },
            ),
            ListTile(
              leading: Icon(Icons.forum_rounded, color: context.palette.gold),
              title: Text(l.groups),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push('/groups');
              },
            ),
            // [Sprint 19 F1] Which notifications the account wants.
            ListTile(
              leading: Icon(Icons.notifications_rounded, color: context.palette.gold),
              title: Text(l.notifications),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push('/notifications');
              },
            ),
            const SizedBox(height: 12),
            if (accountNo != null)
              Text(
                l.accountNo(accountNo!),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textMuted),
              ),
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (_, v) => Text(
                v.hasData ? l.version(v.data!.version) : '',
                textAlign: TextAlign.center,
                style: glmText(GlmType.caption, color: context.palette.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            GlmButton(
              label: l.signOut,
              variant: GlmButtonVariant.danger,
              block: true,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(l.signOutConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: context.palette.live),
                        onPressed: () => Navigator.pop(d, true),
                        child: Text(l.signOut),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).signOut();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
