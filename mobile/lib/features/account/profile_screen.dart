import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../auth/auth_controller.dart';
import '../home/home_data.dart';
import '../leagues/page.dart';
import 'account_data.dart';

/// A holiday request (days and a reason) sent to [path]: a league's (its creator answers) or the account's.
Future<void> askHoliday(BuildContext context, WidgetRef ref, String path, int maxDays) async {
  final l = L.of(context);
  final reason = TextEditingController();
  var days = 3.0.clamp(1, maxDays.toDouble()).toDouble();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.holidayDays(days.round()), style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(
              value: days,
              min: 1,
              max: maxDays.toDouble(),
              divisions: (maxDays - 1).clamp(1, 100),
              activeColor: ctx.palette.gold,
              onChanged: (v) => set(() => days = v),
            ),
            TextField(
              controller: reason,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.holidayReason),
            ),
            GlmButton(label: l.send, block: true, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    ),
  );
  if (ok == true && context.mounted) {
    final r = await tryAction(context, () => ref.read(apiProvider).post(path, {'days': days.round(), 'reason': reason.text.trim()}));
    if (r != null && context.mounted) showGlmToast(context, l.holidaySent);
  }
  reason.dispose();
}

String badgeName(L l, String key, int goal) => switch (key) {
  'first_win' => l.aFirstWin,
  'matches' || 'matches_10' => l.aMatches(goal),
  'wins' || 'wins_100' => l.aWins(goal),
  'first_title' => l.aFirstTitle,
  'league_title' => l.aLeagueTitle,
  'cup_title' => l.aCupTitle,
  'professional' => l.aProfessional,
  'legend' => l.aLegend,
  'friendlies' => l.aFriendlies(goal),
  'idea' => l.aIdea,
  'invites' => l.aInvites(goal),
  'titles_5' => l.aTitles(goal),
  _ => key,
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return screenPage(
      l.profile,
      AsyncView(
        value: ref.watch(meProvider),
        onRetry: () => ref.invalidate(meProvider),
        data: (me) {
          final p = context.palette;
          final look = me.viewing.coachLook;
          final ref0 = me.referral;
          Future<void> patch(Map<String, Object> body) async {
            if (await tryAction(context, () => api.patch('/auth/me', body)) != null) {
              ref.invalidate(meProvider);
              ref.invalidate(homeProvider);
              if (context.mounted) showGlmToast(context, l.displayNameSaved);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              GlmCard(
                gold: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The picture: picked from the phone, squared by the server.
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: p.brand,
                          foregroundImage: me.avatarUrl == null ? null : NetworkImage(me.avatarUrl!),
                          child: Text(
                            me.name.characters.take(1).toString(),
                            style: glmText(GlmType.headline, color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.photo_camera_rounded),
                                label: Text(l.changePhoto),
                                onPressed: () async {
                                  final f = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1024,
                                    maxHeight: 1024,
                                    imageQuality: 85,
                                  );
                                  if (f == null || !context.mounted) return;
                                  await tryAction(context, () => api.upload('/auth/avatar', 'image', f.path));
                                  ref.invalidate(meProvider);
                                },
                              ),
                              if (me.avatarUrl != null)
                                TextButton(
                                  onPressed: () async {
                                    await tryAction(context, () => api.delete('/auth/avatar'));
                                    ref.invalidate(meProvider);
                                  },
                                  child: Text(l.removePhoto),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: me.name,
                      decoration: InputDecoration(labelText: l.displayName, suffixIcon: const Icon(Icons.edit_rounded)),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (v) => v.trim().length >= 2 ? patch({'name': v.trim()}) : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@${me.username} · ${l.accountNo(me.accountNo)}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...me.verification.let(
                (v) => v.verified
                    ? [
                        Text(
                          l.verified,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w700),
                        ),
                      ]
                    : [
                        GlmCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l.verifyAccount(v.welcomeCoins), style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              GlmButton(
                                label: l.sendCode,
                                variant: GlmButtonVariant.outline,
                                onPressed: () async {
                                  if (await tryAction(context, () => api.post('/auth/verify-account/send')) != null && context.mounted) {
                                    showGlmToast(context, l.codeSent);
                                  }
                                },
                              ),
                              TextField(
                                textDirection: TextDirection.ltr,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: l.verifyCode),
                                onSubmitted: (code) async {
                                  await tryAction(context, () => api.post('/auth/verify-account', {'code': code.trim()}));
                                  ref.invalidate(meProvider);
                                  ref.invalidate(homeProvider);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
              ),
              if (me.email != null && !me.emailVerified)
                TextButton(onPressed: () => tryAction(context, () => api.post('/auth/email/resend')), child: Text(l.resendEmail)),
              const SizedBox(height: 12),
              SectionTitle(l.coachLook),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'C1', label: Text('C1')),
                  ButtonSegment(value: 'C2', label: Text('C2')),
                  ButtonSegment(value: 'C3', label: Text('C3')),
                ],
                selected: {look},
                onSelectionChanged: (s) => patch({'coach_look': s.first}),
              ),
              const SizedBox(height: 12),
              GlmButton(
                label: l.changePassword,
                variant: GlmButtonVariant.outline,
                icon: const Icon(Icons.lock_rounded),
                onPressed: () => _password(context, ref, me.hasPassword),
              ),
              const SizedBox(height: 12),
              if (ref0.link.isNotEmpty)
                GlmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.inviteFriends, style: context.text.titleMedium),
                      Text(l.inviteReward(ref0.coins, ref0.paid, ref0.max), style: TextStyle(color: p.textMuted)),
                      const SizedBox(height: 8),
                      GlmButton(
                        label: l.share,
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => SharePlus.instance.share(ShareParams(text: ref0.link)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SectionTitle(l.achievements),
              ...?ref.watch(achievementsProvider).value?.map((m) {
                final goal = m.goal == 0 ? 1 : m.goal;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    m.earned ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                    color: m.earned ? p.gold : p.textMuted,
                  ),
                  title: Text(badgeName(l, m.key, goal), style: TextStyle(fontWeight: m.earned ? FontWeight.w800 : FontWeight.w500)),
                  subtitle: LinearProgressIndicator(
                    value: (m.progress / goal).clamp(0, 1).toDouble(),
                    color: p.gold,
                    backgroundColor: p.surfaceRaised,
                  ),
                  trailing: Text(l.coinsWord(m.reward), style: glmText(GlmType.caption, color: context.glm.goldText)),
                );
              }),
              const SizedBox(height: 12),
              // [UP13] A long holiday for the whole account (the developers answer it), or its end.
              if (me.vacation.on_)
                GlmButton(
                  label: l.endHoliday,
                  variant: GlmButtonVariant.outline,
                  onPressed: () async {
                    await tryAction(context, () => api.delete('/auth/vacation'));
                    ref.invalidate(meProvider);
                  },
                )
              else if (me.vacation.pending == null)
                GlmButton(
                  label: l.holidayAccount,
                  variant: GlmButtonVariant.quiet,
                  icon: const Icon(Icons.beach_access_rounded),
                  onPressed: () => askHoliday(context, ref, '/auth/vacation', me.vacation.maxDays),
                ),
              const SizedBox(height: 8),
              for (final (icon, label, path) in [
                (Icons.leaderboard_rounded, l.ranking, '/ranking'),
                (Icons.lightbulb_rounded, l.ideas, '/ideas'),
                (Icons.support_agent_rounded, l.support, '/support'),
                (Icons.campaign_rounded, l.announcements, '/announcements'),
                (Icons.menu_book_rounded, l.guide, '/guide'),
              ])
                ListTile(
                  leading: Icon(icon, color: p.gold),
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(path),
                ),
              const SizedBox(height: 24),
              GlmButton(
                label: l.deleteAccount,
                variant: GlmButtonVariant.danger,
                onPressed: () => _delete(context, ref, me.hasPassword, me.email ?? ''),
              ),
            ],
          );
        },
      ),
    );
  }

  /// [X12] Asked twice: the word احذف, and the password (or the email of an account without one).
  Future<void> _delete(BuildContext context, WidgetRef ref, bool hasPassword, String email) async {
    final l = L.of(context);
    final phrase = TextEditingController(), secret = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.deleteAccountLead),
            TextField(
              controller: phrase,
              decoration: const InputDecoration(labelText: 'احذف'), // l10n-ok: the server's own word to type (AuthController)
            ),
            TextField(
              controller: secret,
              obscureText: hasPassword,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: hasPassword ? l.currentPassword : l.email),
            ),
            const SizedBox(height: 12),
            GlmButton(label: l.deleteAccount, variant: GlmButtonVariant.danger, block: true, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      final body = {'phrase': phrase.text.trim(), if (hasPassword) 'password': secret.text else 'confirm': secret.text.trim()};
      final r = await tryAction(context, () => ref.read(apiProvider).delete('/auth/me', body));
      if (r != null) await ref.read(authProvider.notifier).forgetHere();
    }
    phrase.dispose();
    secret.dispose();
  }

  Future<void> _password(BuildContext context, WidgetRef ref, bool hasOne) async {
    final l = L.of(context);
    final current = TextEditingController(), next = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasOne)
              TextField(
                controller: current,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.currentPassword),
              ),
            TextField(
              controller: next,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l.newPassword, helperText: l.passwordHint),
            ),
            const SizedBox(height: 12),
            GlmButton(label: l.save, block: true, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      final r = await tryAction(
        context,
        () => ref.read(apiProvider).put('/auth/password', {if (hasOne) 'current_password': current.text, 'password': next.text}),
      );
      if (r != null && context.mounted) showGlmToast(context, l.passwordChanged);
    }
    current.dispose();
    next.dispose();
  }
}
