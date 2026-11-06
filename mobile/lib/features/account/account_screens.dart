import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../auth/auth_controller.dart';
import '../home/home_data.dart';
import '../leagues/widgets.dart' show when;

/// [Sprint 18 F] The account and the community in the app: my account (name, look, password, invites, badges), a
/// league's stats, the ideas and polls (Sprint 28), support, the developers' announcements and the guide (X59).
final meProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async => (await ref.read(apiProvider).get('/auth/me'))['user'] as Map<String, dynamic>);
final achievementsProvider = FutureProvider.autoDispose<List>((ref) async => (await ref.read(apiProvider).get('/home/achievements'))['achievements'] as List? ?? const []);
final statsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, l) => ref.read(apiProvider).get('/leagues/$l/stats'));
final ideasProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.read(apiProvider).get('/ideas'));
final supportProvider = FutureProvider.autoDispose<List>((ref) async => (await ref.read(apiProvider).get('/support'))['messages'] as List? ?? const []);
final announcementsProvider = FutureProvider.autoDispose<List>((ref) async => (await ref.read(apiProvider).get('/announcements'))['announcements'] as List? ?? const []);
final rankingProvider = FutureProvider.autoDispose<List>((ref) async => (await ref.read(apiProvider).get('/rankings/coaches'))['coaches'] as List? ?? const []);
final guideProvider = FutureProvider.autoDispose<List>((ref) async => (await ref.read(apiProvider).get('/guide'))['sections'] as List? ?? const []);

Future<T?> _try<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

Widget _page(String title, Widget body, {List<Widget>? actions}) =>
    Scaffold(appBar: AppBar(title: Text(title), actions: actions), body: GlmBackground(child: body));

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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.holidayDays(days.round()), style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: days, min: 1, max: maxDays.toDouble(), divisions: (maxDays - 1).clamp(1, 100), activeColor: ctx.palette.gold, onChanged: (v) => set(() => days = v)),
          TextField(controller: reason, maxLength: 300, decoration: InputDecoration(labelText: l.holidayReason)),
          GlmButton(label: l.send, block: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    ),
  );
  if (ok == true && context.mounted) {
    final r = await _try(context, () => ref.read(apiProvider).post(path, {'days': days.round(), 'reason': reason.text.trim()}));
    if (r != null && context.mounted) showGlmToast(context, l.holidaySent);
  }
  reason.dispose();
}

String badgeName(L l, String key, int goal) => switch (key) {
      'first_win' => l.aFirstWin, 'matches' || 'matches_10' => l.aMatches(goal), 'wins' || 'wins_100' => l.aWins(goal), 'first_title' => l.aFirstTitle,
      'league_title' => l.aLeagueTitle, 'cup_title' => l.aCupTitle, 'professional' => l.aProfessional, 'legend' => l.aLegend,
      'friendlies' => l.aFriendlies(goal), 'idea' => l.aIdea, 'invites' => l.aInvites(goal), 'titles_5' => l.aTitles(goal), _ => key,
    };

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return _page(
      l.profile,
      AsyncView(
        value: ref.watch(meProvider),
        onRetry: () => ref.invalidate(meProvider),
        data: (me) {
          final p = context.palette;
          final look = (me['viewing'] as Map?)?['coach_look'] as String? ?? 'C1';
          final ref0 = me['referral'] as Map? ?? const {};
          Future<void> patch(Map<String, Object> body) async {
            if (await _try(context, () => api.patch('/auth/me', body)) != null) {
              ref.invalidate(meProvider);
              ref.invalidate(homeProvider);
              if (context.mounted) showGlmToast(context, l.displayNameSaved);
            }
          }

          return ListView(padding: const EdgeInsets.all(12), children: [
            GlmCard(
              gold: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // The picture: picked from the phone, squared by the server.
                Row(children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: p.brand,
                    foregroundImage: me['avatar_url'] == null ? null : NetworkImage('${me['avatar_url']}'),
                    child: Text('${me['name'] ?? ''}'.characters.take(1).toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(spacing: 4, children: [
                      TextButton.icon(
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: Text(l.changePhoto),
                        onPressed: () async {
                          final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
                          if (f == null || !context.mounted) return;
                          await _try(context, () => api.upload('/auth/avatar', 'image', f.path));
                          ref.invalidate(meProvider);
                        },
                      ),
                      if (me['avatar_url'] != null)
                        TextButton(onPressed: () async {
                          await _try(context, () => api.delete('/auth/avatar'));
                          ref.invalidate(meProvider);
                        }, child: Text(l.removePhoto)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: '${me['name'] ?? ''}',
                  decoration: InputDecoration(labelText: l.displayName, suffixIcon: const Icon(Icons.edit_rounded)),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (v) => v.trim().length >= 2 ? patch({'name': v.trim()}) : null,
                ),
                const SizedBox(height: 6),
                Text('@${me['username'] ?? ''} · ${l.accountNo(me['account_no'] as int? ?? 0)}', textDirection: TextDirection.ltr, style: TextStyle(color: p.textMuted)),
              ]),
            ),
            const SizedBox(height: 12),
            ...?(me['verification'] as Map?)?.let((v) => v['verified'] == true
                ? [Text(l.verified, textAlign: TextAlign.center, style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w700))]
                : [
                    GlmCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(l.verifyAccount(v['welcome_coins'] as int? ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        GlmButton(label: l.sendCode, variant: GlmButtonVariant.outline, onPressed: () async {
                          if (await _try(context, () => api.post('/auth/verify-account/send')) != null && context.mounted) showGlmToast(context, l.codeSent);
                        }),
                        TextField(
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l.verifyCode),
                          onSubmitted: (code) async {
                            await _try(context, () => api.post('/auth/verify-account', {'code': code.trim()}));
                            ref.invalidate(meProvider);
                            ref.invalidate(homeProvider);
                          },
                        ),
                      ]),
                    ),
                  ]),
            if (me['email'] != null && me['email_verified'] != true)
              TextButton(onPressed: () => _try(context, () => api.post('/auth/email/resend')), child: Text(l.resendEmail)),
            const SizedBox(height: 12),
            SectionTitle(l.coachLook),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [ButtonSegment(value: 'C1', label: Text('C1')), ButtonSegment(value: 'C2', label: Text('C2')), ButtonSegment(value: 'C3', label: Text('C3'))],
              selected: {look},
              onSelectionChanged: (s) => patch({'coach_look': s.first}),
            ),
            const SizedBox(height: 12),
            GlmButton(label: l.changePassword, variant: GlmButtonVariant.outline, icon: const Icon(Icons.lock_rounded), onPressed: () => _password(context, ref, me['has_password'] == true)),
            const SizedBox(height: 12),
            if (ref0['link'] != null)
              GlmCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.inviteFriends, style: context.text.titleMedium),
                  Text(l.inviteReward(ref0['coins'] as int? ?? 0, ref0['paid'] as int? ?? 0, ref0['max'] as int? ?? 0), style: TextStyle(color: p.textMuted)),
                  const SizedBox(height: 8),
                  GlmButton(label: l.share, icon: const Icon(Icons.share_rounded), onPressed: () => SharePlus.instance.share(ShareParams(text: '${ref0['link']}'))),
                ]),
              ),
            const SizedBox(height: 12),
            SectionTitle(l.achievements),
            ...?ref.watch(achievementsProvider).value?.map((a) {
              final m = a as Map;
              final goal = m['goal'] as int? ?? 1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(m['earned'] == true ? Icons.military_tech_rounded : Icons.lock_outline_rounded, color: m['earned'] == true ? p.gold : p.textMuted),
                title: Text(badgeName(l, '${m['key']}', goal), style: TextStyle(fontWeight: m['earned'] == true ? FontWeight.w800 : FontWeight.w500)),
                subtitle: LinearProgressIndicator(value: ((m['progress'] as int? ?? 0) / goal).clamp(0, 1).toDouble(), color: p.gold, backgroundColor: p.surfaceRaised),
                trailing: Text(l.coinsWord(m['reward'] as int? ?? 0), style: TextStyle(color: context.glm.goldText, fontSize: 12)),
              );
            }),
            const SizedBox(height: 12),
            // [UP13] A long holiday for the whole account (the developers answer it), or its end.
            if ((me['vacation'] as Map?)?['on'] == true)
              GlmButton(label: l.endHoliday, variant: GlmButtonVariant.outline, onPressed: () async {
                await _try(context, () => api.delete('/auth/vacation'));
                ref.invalidate(meProvider);
              })
            else if ((me['vacation'] as Map?)?['pending'] == null)
              GlmButton(label: l.holidayAccount, variant: GlmButtonVariant.quiet, icon: const Icon(Icons.beach_access_rounded),
                  onPressed: () => askHoliday(context, ref, '/auth/vacation', (me['vacation'] as Map?)?['max_days'] as int? ?? 60)),
            const SizedBox(height: 8),
            for (final (icon, label, path) in [
              (Icons.leaderboard_rounded, l.ranking, '/ranking'),
              (Icons.lightbulb_rounded, l.ideas, '/ideas'), (Icons.support_agent_rounded, l.support, '/support'),
              (Icons.campaign_rounded, l.announcements, '/announcements'), (Icons.menu_book_rounded, l.guide, '/guide'),
            ])
              ListTile(leading: Icon(icon, color: p.gold), title: Text(label), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push(path)),
            const SizedBox(height: 24),
            GlmButton(label: l.deleteAccount, variant: GlmButtonVariant.danger, onPressed: () => _delete(context, ref, me['has_password'] == true, '${me['email'] ?? ''}')),
          ]);
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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.deleteAccountLead),
          TextField(controller: phrase, decoration: const InputDecoration(labelText: 'احذف')),
          TextField(controller: secret, obscureText: hasPassword, textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: hasPassword ? l.currentPassword : l.email)),
          const SizedBox(height: 12),
          GlmButton(label: l.deleteAccount, variant: GlmButtonVariant.danger, block: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok == true && context.mounted) {
      final body = {'phrase': phrase.text.trim(), if (hasPassword) 'password': secret.text else 'confirm': secret.text.trim()};
      final r = await _try(context, () => ref.read(apiProvider).delete('/auth/me', body));
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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (hasOne) TextField(controller: current, obscureText: true, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l.currentPassword)),
          TextField(controller: next, obscureText: true, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l.newPassword, helperText: l.passwordHint)),
          const SizedBox(height: 12),
          GlmButton(label: l.save, block: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok == true && context.mounted) {
      final r = await _try(context, () => ref.read(apiProvider).put('/auth/password', {if (hasOne) 'current_password': current.text, 'password': next.text}));
      if (r != null && context.mounted) showGlmToast(context, l.passwordChanged);
    }
    current.dispose();
    next.dispose();
  }
}

/// [X18] The coaches' ranking: titles first, then wins.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.ranking,
      AsyncView(
        value: ref.watch(rankingProvider),
        onRetry: () => ref.invalidate(rankingProvider),
        data: (rows) => ListView(padding: const EdgeInsets.all(12), children: [
          for (final r in rows.cast<Map>())
            ListTile(
              leading: Text('${r['position']}', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 20, fontWeight: FontWeight.w800, color: context.glm.goldText)),
              title: Text('${(r['coach'] as Map?)?['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${l.trophiesShort(((r['trophies'] as Map?)?['total'] as int?) ?? 0)} · ${r['won']}/${r['played']} · ${((r['rating'] as Map?)?['points']) ?? 0}'),
              onTap: (r['coach'] as Map?)?['id'] == null ? null : () => context.push('/coaches/${(r['coach'] as Map)['id']}'),
            ),
        ]),
      ),
    );
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.stats,
      AsyncView(
        value: ref.watch(statsProvider(leagueId)),
        onRetry: () => ref.invalidate(statsProvider(leagueId)),
        data: (s) {
          final p = context.palette;
          Widget list(String title, List rows, String key, String unit) => GlmCard(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(title, style: context.text.titleMedium),
                  if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.noStatsYet, style: TextStyle(color: p.textMuted))),
                  for (final (i, r) in rows.take(10).indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        SizedBox(width: 24, child: Text('${i + 1}', style: TextStyle(color: p.textMuted, fontFamily: GlmFonts.numbers))),
                        Expanded(child: Text('${((r as Map)['player'] as Map?)?['name'] ?? ''}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                        Text('${(r['club'] as Map?)?['code'] ?? ''}  ', style: TextStyle(color: p.textMuted, fontSize: 12)),
                        Text('${r[key]} $unit', style: TextStyle(fontWeight: FontWeight.w800, color: context.glm.goldText)),
                      ]),
                    ),
                ]),
              );
          final values = s['value'] as List? ?? const [];
          return ListView(padding: const EdgeInsets.all(12), children: [
            list(l.scorers, s['scorers'] as List? ?? const [], 'goals', l.goalsShort),
            const SizedBox(height: 10),
            list(l.assistsTitle, s['assists'] as List? ?? const [], 'assists', l.assistsShort),
            const SizedBox(height: 10),
            GlmCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.squadValues, style: context.text.titleMedium),
                for (final v in values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      SizedBox(width: 24, child: Text('${(v as Map)['position']}', style: TextStyle(color: p.textMuted, fontFamily: GlmFonts.numbers))),
                      Expanded(child: Text('${(v['club'] as Map?)?['name'] ?? ''}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                      Text(money(context, (v['value'] as num? ?? 0).toInt()), textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  final title = TextEditingController(), body = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return _page(
      l.ideas,
      AsyncView(
        value: ref.watch(ideasProvider),
        onRetry: () => ref.invalidate(ideasProvider),
        data: (d) {
          final p = context.palette;
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final poll in (d['polls'] as List? ?? const []))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlmCard(
                  gold: (poll as Map)['state'] == 'open',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${poll['question']}', style: context.text.titleMedium),
                    if (poll['body'] != null) Text('${poll['body']}', style: TextStyle(color: p.textMuted)),
                    for (final o in (poll['options'] as List? ?? const []))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(poll['my_vote'] == (o as Map)['id'] ? Icons.radio_button_checked : Icons.radio_button_off, color: p.gold),
                        title: Text('${o['label']}'),
                        trailing: o['votes'] == null ? null : Text(l.votes(o['votes'] as int), style: TextStyle(color: p.textMuted)),
                        onTap: poll['state'] != 'open' || poll['my_vote'] != null
                            ? null
                            : () async {
                                await _try(context, () => api.post('/ideas/polls/${poll['id']}/vote', {'option_id': o['id']}));
                                ref.invalidate(ideasProvider);
                              },
                      ),
                  ]),
                ),
              ),
            GlmCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.ideasLead(d['left_today'] as int? ?? 0), style: TextStyle(color: p.textMuted)),
                TextField(controller: title, maxLength: 120, decoration: InputDecoration(labelText: l.articleTitle)),
                TextField(controller: body, maxLength: 2000, minLines: 3, maxLines: 8, decoration: InputDecoration(labelText: l.articleBody)),
                GlmButton(
                  label: l.suggest,
                  onPressed: (d['left_today'] as int? ?? 0) == 0
                      ? null
                      : () async {
                          final r = await _try(context, () => api.post('/ideas/suggestions', {'title': title.text.trim(), 'body': body.text.trim()}));
                          if (r != null && context.mounted) {
                            showGlmToast(context, l.suggestionSent);
                            title.clear();
                            body.clear();
                          }
                          ref.invalidate(ideasProvider);
                        },
                ),
              ]),
            ),
            const SizedBox(height: 10),
            for (final sgg in (d['suggestions'] as List? ?? const []))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${(sgg as Map)['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([
                  switch (sgg['status']) { 'accepted' => l.statusAccepted, 'built' => l.statusBuilt, 'rejected' => l.statusRejected, _ => l.statusPending },
                  if ((sgg['coins'] as int? ?? 0) > 0) l.coinsWord(sgg['coins'] as int),
                  if (sgg['reply'] != null) '${sgg['reply']}',
                ].join(' · ')),
              ),
            if ((d['honours'] as List? ?? const []).isNotEmpty) ...[
              SectionTitle(l.honourRoll),
              for (final h in d['honours'] as List)
                ListTile(
                  dense: true,
                  leading: Text('${(h as Map)['rank']}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                  title: Text('${(h['user'] as Map?)?['name'] ?? ''}'),
                  trailing: Text('${h['count']}'),
                ),
            ],
          ]);
        },
      ),
    );
  }
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return _page(
      l.support,
      Column(children: [
        Expanded(
          child: AsyncView(
            value: ref.watch(supportProvider),
            onRetry: () => ref.invalidate(supportProvider),
            data: (messages) => ListView(padding: const EdgeInsets.all(12), children: [
              Text(l.supportLead, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
              const SizedBox(height: 10),
              for (final m in messages)
                Align(
                  alignment: (m as Map)['from_team'] == true ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(color: m['from_team'] == true ? p.gold.withValues(alpha: .14) : p.surface, borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (m['from_team'] == true) Text(l.fromTeam, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12)),
                      Text('${m['body']}'),
                      if (DateTime.tryParse('${m['at']}') != null) Text(when(context, DateTime.parse('${m['at']}').toLocal()), style: TextStyle(color: p.textMuted, fontSize: 11)),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _text, minLines: 1, maxLines: 4, maxLength: 2000, decoration: InputDecoration(hintText: l.typeMessage, counterText: ''))),
              IconButton(
                tooltip: l.send,
                icon: Icon(Icons.send_rounded, color: p.gold),
                onPressed: () async {
                  final body = _text.text.trim();
                  if (body.isEmpty) return;
                  if (await _try(context, () => ref.read(apiProvider).post('/support', {'body': body})) != null) _text.clear();
                  ref.invalidate(supportProvider);
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.announcements,
      AsyncView(
        value: ref.watch(announcementsProvider),
        onRetry: () => ref.invalidate(announcementsProvider),
        data: (cards) => cards.isEmpty
            ? Center(child: Text(l.noAnnouncements))
            : ListView(padding: const EdgeInsets.all(12), children: [
                for (final a in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlmCard(
                      padding: EdgeInsets.zero,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if ((a as Map)['image_url'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network('${a['image_url']}', fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Text('${a['title']}', style: context.text.titleMedium),
                            const SizedBox(height: 4),
                            Text('${a['body']}'),
                            if (a['cta'] is Map) ...[
                              const SizedBox(height: 8),
                              GlmButton(label: '${(a['cta'] as Map)['label']}', variant: GlmButtonVariant.brand,
                                  onPressed: () => launchUrl(Uri.parse('${(a['cta'] as Map)['url']}'), mode: LaunchMode.externalApplication)),
                            ],
                          ]),
                        ),
                      ]),
                    ),
                  ),
              ]),
      ),
    );
  }
}

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.guide,
      AsyncView(
        value: ref.watch(guideProvider),
        onRetry: () => ref.invalidate(guideProvider),
        data: (sections) => ListView(padding: const EdgeInsets.all(12), children: [
          for (final s in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text('${(s as Map)['title']}', style: context.text.titleMedium),
                  children: [
                    for (final t in (s['topics'] as List? ?? const []))
                      ExpansionTile(
                        shape: const Border(),
                        title: Text('${(t as Map)['q']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('${t['a']}'))],
                      ),
                  ],
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
