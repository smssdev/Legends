import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/tokens.g.dart';
import 'package:flutter/services.dart';
import '../../ui/widgets/console.dart';
import '../auth/auth_controller.dart';
import '../console/console_data.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/live/live_channels.dart';
import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/widgets.dart' show when;
import '../leagues/shell.dart';

/// [Sprint 18 E] The league's social screens in the app: the friendlies (Sprint 24, a quick match played back fast),
/// the predictions and the newspaper (UP12), and the chat groups (Sprint 29). The server decides and writes all of it.
class SocialRepository {
  SocialRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> friendlies(int league) => _api.get('/leagues/$league/friendlies');
  Future<Map<String, dynamic>> playFriendly(int league, int opponent) => Intents.run(
      'friendly:$league:$opponent', (key) => _api.post('/leagues/$league/friendlies', {'opponent_id': opponent, 'idempotency_key': key}));
  Future<Map<String, dynamic>> predictions(int league) => _api.get('/leagues/$league/predictions');
  Future<Map<String, dynamic>> predict(int league, int fixture, String pick) => _api.post('/leagues/$league/predictions', {'fixture_id': fixture, 'pick': pick});
  Future<Map<String, dynamic>> newspaper(int league) => _api.get('/leagues/$league/newspaper');
  Future<Map<String, dynamic>> write(int league, String title, String body) => _api.post('/leagues/$league/newspaper/articles', {'title': title, 'body': body});
  Future<Map<String, dynamic>> decide(int league, int article, bool publish) => _api.post('/leagues/$league/newspaper/articles/$article/decide', {'publish': publish});
  Future<Map<String, dynamic>> groups() => _api.get('/groups');
  Future<List<Map<String, dynamic>>> messages(int group) async => [for (final m in ((await _api.get('/groups/$group/messages'))['messages'] as List<dynamic>? ?? const [])) m as Map<String, dynamic>];
  Future<void> say(int group, String body, {int? replyTo}) => _api.post('/groups/$group/messages', {'body': body, 'reply_to': ?replyTo});
  Future<void> read(int group) => _api.post('/groups/$group/read');
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) => SocialRepository(ref.watch(apiProvider)));
final friendliesProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).friendlies(l));
final predictionsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).predictions(l));
final newspaperProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).newspaper(l));
final groupsProvider = FutureProvider.autoDispose((ref) => ref.read(socialRepositoryProvider).groups());

Future<T?> _try<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

Widget _page(String title, Widget body) => Scaffold(appBar: GameBar(title: Text(title)), body: GlmBackground(child: body));

class FriendliesScreen extends ConsumerWidget {
  const FriendliesScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.friendlies,
      AsyncView(
        value: ref.watch(friendliesProvider(leagueId)),
        onRetry: () => ref.invalidate(friendliesProvider(leagueId)),
        data: (f) {
          final p = context.palette;
          final recent = f['recent'] as List<dynamic>? ?? const [];
          return ListView(padding: const EdgeInsets.all(12), children: [
            Text(l.friendlyLead(f['fitness'] as int? ?? 0), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            Text(f['first_free'] == true ? l.friendlyFree : l.friendlyCost(f['coins'] as int? ?? 0), textAlign: TextAlign.center,
                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700)),
            if (f['blocked'] != null) Text('${f['blocked']}', textAlign: TextAlign.center, style: TextStyle(color: context.glm.liveText)),
            const SizedBox(height: 12),
            if (recent.isNotEmpty) ...[
              SectionTitle(l.recentFriendlies),
              for (final r in recent.take(3))
                ListTile(
                  dense: true,
                  title: Text('${((r as Map<dynamic, dynamic>)['opponent'] as Map<dynamic, dynamic>?)?['name'] ?? ''}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                  trailing: Text('${r['goals_for']} - ${r['goals_against']}', textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => QuickMatchScreen(home: '${f['club']?['name'] ?? ''}', played: Map<String, dynamic>.from(r)))),
                ),
              const SizedBox(height: 8),
            ],
            for (final o in (f['opponents'] as List<dynamic>? ?? const []))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  padding: const EdgeInsets.all(10),
                  gold: (o as Map<dynamic, dynamic>)['recommended'] == true,
                  child: Row(children: [
                    ClubCrest(url: o['crest_url'] as String?, name: '${o['code']}', size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${o['name']}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text([if (o['recommended'] == true) l.suggestedOpponent, if (o['played_today'] == true) l.playedToday, if (o['coach'] != null) '${o['coach']}'].join(' · '),
                            style: TextStyle(color: p.textMuted, fontSize: 12)),
                      ]),
                    ),
                    GlmButton(
                      label: l.playFriendly,
                      onPressed: f['blocked'] != null
                          ? null
                          : () async {
                              final r = await _try(context, () => ref.read(socialRepositoryProvider).playFriendly(leagueId, o['id'] as int));
                              ref.invalidate(friendliesProvider(leagueId));
                              if (r != null && context.mounted) {
                                await Navigator.of(context).push(MaterialPageRoute<void>(
                                    builder: (_) => QuickMatchScreen(home: '${f['club']?['name'] ?? ''}', played: Map<String, dynamic>.from(r['friendly'] as Map<dynamic, dynamic>))));
                              }
                            },
                    ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// The friendly played back fast (the web's QuickMatch): its minutes one by one with the score, then the best players.
class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key, required this.home, required this.played});

  final String home;
  final Map<String, dynamic> played;

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen> {
  late final List<Map<dynamic, dynamic>> _timeline = [for (final e in ((widget.played['report'] as Map<dynamic, dynamic>?)?['timeline'] as List<dynamic>? ?? const [])) e as Map<dynamic, dynamic>];
  int _at = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (_at >= _timeline.length) return t.cancel();
      setState(() => _at++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final done = _at >= _timeline.length;
    final shown = _timeline.take(_at).where((e) => e['k'] != 'quiet' && e['k'] != 'attack').toList().reversed;
    final last = _at == 0 ? null : _timeline[_at - 1];
    final score = done ? [widget.played['goals_for'], widget.played['goals_against']] : (last?['score'] as List<dynamic>? ?? const [0, 0]);
    final away = '${(widget.played['opponent'] as Map<dynamic, dynamic>?)?['name'] ?? ''}';
    final best = (widget.played['report'] as Map<dynamic, dynamic>?)?['best'] as List<dynamic>? ?? const [];
    String kind(String k) => switch (k) {
          'goal' => '⚽ ${l.kGoal}', 'saved' => '🧤 ${l.kSaved}', 'missed' => l.kMissed, 'corner' => '⛳ ${l.kCorner}', 'yellow' => '🟨 ${l.kYellow}', 'red' => '🟥 ${l.kRed}', _ => l.kAttack,
        };
    return _page(
      l.friendlies,
      Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Text(widget.home, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
            Column(children: [
              Text('${score[0]} - ${score[1]}', textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 36, fontWeight: FontWeight.w800, color: p.text)),
              Text(done ? l.fullTime : "${last?['m'] ?? 0}'", style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800)),
            ]),
            Expanded(child: Text(away, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ),
        if (!done) TextButton(onPressed: () => setState(() => _at = _timeline.length), child: Text(l.skip)),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            if (done && best.isNotEmpty)
              GlmCard(
                gold: true,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.bestOfMatch, style: context.text.titleMedium),
                  for (final b in best)
                    Row(children: [
                      Expanded(child: Text('${(b as Map<dynamic, dynamic>)['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                      Text(((b['rating'] as num? ?? 0) / 100).toStringAsFixed(1), style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                    ]),
                ]),
              ),
            const SizedBox(height: 8),
            for (final e in shown)
              ListTile(
                dense: true,
                leading: Text("${e['m']}'", style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                title: Text(kind('${e['k']}'), style: TextStyle(fontWeight: e['k'] == 'goal' ? FontWeight.w800 : FontWeight.w500)),
                subtitle: e['name'] == null ? null : Text('${e['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                trailing: Text(e['s'] == 'home' ? widget.home : away, textDirection: TextDirection.ltr, style: TextStyle(color: p.textMuted, fontSize: 12)),
              ),
          ]),
        ),
      ]),
    );
  }
}

class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  Map<String, dynamic>? _fresh;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _page(
      l.predictions,
      AsyncView(
        value: ref.watch(predictionsProvider(widget.leagueId)),
        onRetry: () => ref.invalidate(predictionsProvider(widget.leagueId)),
        data: (loaded) {
          final d = _fresh ?? loaded;
          final p = context.palette;
          return ListView(padding: const EdgeInsets.all(12), children: [
            Text(l.predictionsLead(d['round'] as int? ?? 0, money(context, (d['reward'] as num? ?? 0).toInt())), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 12),
            for (final m in (d['matches'] as List<dynamic>? ?? const []))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text('${((m as Map<dynamic, dynamic>)['home'] as Map<dynamic, dynamic>)['name']}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
                      const Text(' — '),
                      Expanded(child: Text('${(m['away'] as Map<dynamic, dynamic>)['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 8),
                    if (m['open'] != true)
                      Text(l.predictionClosed, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted))
                    else
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        emptySelectionAllowed: true,
                        segments: [
                          ButtonSegment(value: 'home', label: Text('${(m['home'] as Map<dynamic, dynamic>)['code']}', textDirection: TextDirection.ltr)),
                          ButtonSegment(value: 'draw', label: Text(l.draw)),
                          ButtonSegment(value: 'away', label: Text('${(m['away'] as Map<dynamic, dynamic>)['code']}', textDirection: TextDirection.ltr)),
                        ],
                        selected: {if (m['mine'] != null) '${m['mine'] is Map<dynamic, dynamic> ? (m['mine'] as Map<dynamic, dynamic>)['pick'] : m['mine']}'},
                        onSelectionChanged: (s) async {
                          if (s.isEmpty) return;
                          final r = await _try(context, () => ref.read(socialRepositoryProvider).predict(widget.leagueId, m['fixture_id'] as int, s.first));
                          if (r != null && mounted) setState(() => _fresh = r);
                        },
                      ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class NewspaperScreen extends ConsumerWidget {
  const NewspaperScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.newspaper,
      AsyncView(
        value: ref.watch(newspaperProvider(leagueId)),
        onRetry: () => ref.invalidate(newspaperProvider(leagueId)),
        data: (d) {
          final p = context.palette;
          final e = d['edition'] as Map<dynamic, dynamic>?;
          final articles = d['articles'] as List<dynamic>? ?? const [];
          final pending = d['pending'] as List<dynamic>? ?? const [];
          Future<void> decide(int id, bool publish) async {
            await _try(context, () => ref.read(socialRepositoryProvider).decide(leagueId, id, publish));
            ref.invalidate(newspaperProvider(leagueId));
          }

          return ListView(padding: const EdgeInsets.all(12), children: [
            if (e == null)
              Padding(padding: const EdgeInsets.all(16), child: Text(l.noEdition, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)))
            else ...[
              for (final s in (e['stories'] as List<dynamic>? ?? const []))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    gold: true,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('${(s as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                      Text('${s['text']}', style: TextStyle(color: p.textMuted)),
                    ]),
                  ),
                ),
              SectionTitle(l.roundResults(e['round'] as int? ?? 0)),
              GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(children: [
                  for (final r in (e['results'] as List<dynamic>? ?? const []))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text('${(r as Map<dynamic, dynamic>)['home']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                        Text('${r['home_goals']} - ${r['away_goals']}', textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800)),
                        Expanded(child: Text('${r['away']}', textDirection: TextDirection.ltr, textAlign: TextAlign.end)),
                      ]),
                    ),
                ]),
              ),
              if (e['coach'] is Map<dynamic, dynamic>) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Text('🎩', style: TextStyle(fontSize: 22)),
                  title: Text(l.coachOfRound),
                  subtitle: Text('${((e['coach'] as Map<dynamic, dynamic>)['coach'] as Map<dynamic, dynamic>?)?['name'] ?? ''} · ${(e['coach'] as Map<dynamic, dynamic>)['club'] ?? ''}'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            if (d['is_owner'] == true && pending.isNotEmpty) ...[
              SectionTitle(l.pendingArticles),
              for (final a in pending)
                GlmCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${(a as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                    Text('${a['body']}'),
                    Text('${(a['author'] as Map<dynamic, dynamic>?)?['name'] ?? ''}', style: TextStyle(color: p.textMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: GlmButton(label: l.publish, onPressed: () => decide(a['id'] as int, true))),
                      const SizedBox(width: 8),
                      Expanded(child: GlmButton(label: l.reject, variant: GlmButtonVariant.outline, onPressed: () => decide(a['id'] as int, false))),
                    ]),
                  ]),
                ),
              const SizedBox(height: 8),
            ],
            SectionTitle(l.articles),
            for (final a in articles)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${(a as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    Text('${a['body']}'),
                    const SizedBox(height: 4),
                    Text([(a['author'] as Map<dynamic, dynamic>?)?['name'] ?? '', if (DateTime.tryParse('${a['at']}') != null) when(context, DateTime.parse('${a['at']}').toLocal())].join(' · '),
                        style: TextStyle(color: p.textMuted, fontSize: 12)),
                  ]),
                ),
              ),
            if (d['wrote_this_round'] != true)
              GlmButton(
                label: l.writeArticle,
                variant: GlmButtonVariant.outline,
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _write(context, ref, d['max'] as int? ?? 2000),
              ),
          ]);
        },
      ),
    );
  }

  Future<void> _write(BuildContext context, WidgetRef ref, int max) async {
    final l = L.of(context);
    final title = TextEditingController(), body = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: title, maxLength: 120, decoration: InputDecoration(labelText: l.articleTitle)),
          TextField(controller: body, maxLength: max, minLines: 4, maxLines: 10, decoration: InputDecoration(labelText: l.articleBody)),
          const SizedBox(height: 8),
          GlmButton(label: l.send, block: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (send == true && context.mounted) {
      final r = await _try(context, () => ref.read(socialRepositoryProvider).write(leagueId, title.text.trim(), body.text.trim()));
      if (r != null && context.mounted) showGlmToast(context, l.articleSent);
      ref.invalidate(newspaperProvider(leagueId));
    }
    title.dispose();
    body.dispose();
  }
}

/// [Sprint 18 G] Open a group by its invite code (a link gamelegendmanager.online/groups/join/CODE, or typed).
Future<void> joinGroup(BuildContext context, WidgetRef ref, String code) async {
  final r = await _try(context, () => ref.read(apiProvider).post('/groups/join/${code.trim().toLowerCase()}'));
  ref.invalidate(groupsProvider);
  final g = r?['group'] as Map<dynamic, dynamic>?;
  if (g != null && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}')));
  }
}

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key, this.joinCode});

  /// A code from an invite link: joined as the screen opens.
  final String? joinCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    if (joinCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) joinGroup(context, ref, joinCode!);
      });
    }
    return Scaffold(
      appBar: GameBar(title: Text(l.groups), actions: [
        IconButton(
          tooltip: l.joinGroup,
          icon: const Icon(Icons.vpn_key_rounded),
          onPressed: () async {
            final code = TextEditingController();
            final ok = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: Text(l.joinGroup),
                content: TextField(controller: code, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l.groupCode)),
                actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.confirm))],
              ),
            );
            if (ok == true && context.mounted) await joinGroup(context, ref, code.text);
            code.dispose();
          },
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.group_add_rounded),
        label: Text(l.newGroup),
        onPressed: () async {
          final name = TextEditingController(), members = TextEditingController();
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(controller: name, maxLength: 60, decoration: InputDecoration(labelText: l.groupName)),
                TextField(controller: members, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l.groupMembers)),
                const SizedBox(height: 12),
                GlmButton(label: l.create, block: true, onPressed: () => Navigator.pop(ctx, true)),
              ]),
            ),
          );
          if (ok == true && context.mounted) {
            final usernames = [for (final u in members.text.split(RegExp(r'[,،\s]+'))) if (u.trim().isNotEmpty) u.trim().replaceFirst('@', '')];
            final r = await _try(context, () => ref.read(apiProvider).post('/groups', {'name': name.text.trim(), 'usernames': usernames}));
            ref.invalidate(groupsProvider);
            final g = r?['group'] as Map<dynamic, dynamic>?;
            if (g != null && context.mounted) {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}')));
            }
          }
          name.dispose();
          members.dispose();
        },
      ),
      body: GlmBackground(child: _GroupsConsole(list: (onOpen, open) => _groupsBody(context, ref, l, onOpen: onOpen, open: open))),
    );
  }

  Widget _groupsBody(BuildContext context, WidgetRef ref, L l, {void Function(int id, String name)? onOpen, int? open}) => AsyncView(
        value: ref.watch(groupsProvider),
        onRetry: () => ref.invalidate(groupsProvider),
        data: (d) {
          final groups = d['groups'] as List<dynamic>? ?? const [];
          if (groups.isEmpty) return Center(child: Text(l.noGroups));
          return RefreshIndicator(
            onRefresh: () => ref.refresh(groupsProvider.future),
            child: ListView(children: [
              for (final g in groups)
                ListTile(
                  // [Sprint 50 M7] The open chat lit as the site's open page (the brand green).
                  selected: open == (g as Map<dynamic, dynamic>)['id'],
                  selectedTileColor: context.palette.brand,
                  selectedColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(backgroundColor: open == g['id'] ? context.palette.brandDark : context.palette.brand, child: Icon(g['league_id'] != null ? Icons.emoji_events_rounded : Icons.groups_rounded, color: Colors.white)),
                  title: Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${(g['last'] as Map<dynamic, dynamic>?)?['body'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: (g['unread'] as int? ?? 0) > 0 ? Badge(backgroundColor: context.palette.gold, textColor: context.palette.onGold, label: Text('${g['unread']}')) : null,
                  onTap: () async {
                    if (onOpen != null) return onOpen(g['id'] as int, '${g['name']}');
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}')));
                    ref.invalidate(groupsProvider);
                  },
                ),
            ]),
          );
        },
      );
}

/// A picture sent in a group: private to its members, so fetched with the account's token, once.
class _GroupImage extends ConsumerStatefulWidget {
  const _GroupImage({required this.path});

  final String path;

  @override
  ConsumerState<_GroupImage> createState() => _GroupImageState();
}

class _GroupImageState extends ConsumerState<_GroupImage> {
  late final Future<List<int>> _bytes = ref.read(apiProvider).bytes(widget.path);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
        future: _bytes,
        builder: (_, s) => s.hasData && s.data!.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(Uint8List.fromList(s.data!), width: 240, fit: BoxFit.cover))
            : const SizedBox(width: 240, height: 140, child: Center(child: CircularProgressIndicator())),
      );
}

/// A voice note sent in a group: fetched once with the account's token, then played from the phone.
class _GroupVoice extends ConsumerStatefulWidget {
  const _GroupVoice({required this.path, required this.seconds});

  final String path;
  final int seconds;

  @override
  ConsumerState<_GroupVoice> createState() => _GroupVoiceState();
}

class _GroupVoiceState extends ConsumerState<_GroupVoice> {
  final _player = AudioPlayer();
  bool _playing = false, _loading = false;
  String? _file;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    if (_file == null) {
      setState(() => _loading = true);
      try {
        final bytes = await ref.read(apiProvider).bytes(widget.path);
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/voice-${widget.path.hashCode}.m4a');
        await f.writeAsBytes(bytes);
        _file = f.path;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
    }
    await _player.play(DeviceFileSource(_file!));
    if (mounted) {
      setState(() {
        _playing = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          onPressed: _loading ? null : _toggle,
          icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: context.palette.gold),
        ),
        Text(L.of(context).voiceNote(widget.seconds)),
      ]);
}

/// A group's conversation: the latest page, asked again every few seconds while open, and a line to write.
/// [Sprint 50 M7] The chats as the tablet and computer messengers: the list at the start (30%) and the open chat beside
/// it (70%) on a wide screen; on a narrow one, the list, each chat opening on its own page.
class _GroupsConsole extends ConsumerStatefulWidget {
  const _GroupsConsole({required this.list});

  final Widget Function(void Function(int id, String name)? onOpen, int? open) list;

  @override
  ConsumerState<_GroupsConsole> createState() => _GroupsConsoleState();
}

class _GroupsConsoleState extends ConsumerState<_GroupsConsole> {
  (int, String)? _open;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        if (box.maxWidth < 760) return widget.list(null, null);
        final l = L.of(context);
        return GlmSplitLayout(
          ratio: (30, 70),
          start: GlmCard(padding: const EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.fromLTRB(6, 4, 6, 6), child: GlmSectionTitle(l.channels)),
            Expanded(child: widget.list((id, name) {
              setState(() => _open = (id, name));
              ref.invalidate(groupsProvider);
            }, _open?.$1)),
          ])),
          end: _open == null
              ? Center(child: Text(l.pickChannel, style: TextStyle(color: context.palette.textMuted)))
              : GlmCard(
                  padding: EdgeInsets.zero,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: GlmSectionTitle(_open!.$2)),
                    Expanded(child: ChatRoom(key: ValueKey(_open!.$1), groupId: _open!.$1)),
                  ]),
                ),
        );
      });
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.groupId, required this.name});

  final int groupId;
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(appBar: GameBar(title: Text(name)), body: GlmBackground(child: ChatRoom(groupId: groupId)));
}

/// [Sprint 50 M7, M8] A chat's messages and its composer: my messages on the end side in the brand green, the others'
/// on the start side with their name; a swipe or a long press answers one (its quote over the composer), and a long
/// press gives the four quick reactions (the server counts them, one each).
class ChatRoom extends ConsumerStatefulWidget {
  const ChatRoom({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<ChatRoom> createState() => _ChatRoomState();
}

const _reactions = {'ball': '⚽', 'fire': '🔥', 'cup': '🏆', 'laugh': '😂'};

class _ChatRoomState extends ConsumerState<ChatRoom> {
  late final SocialRepository _repo = ref.read(socialRepositoryProvider);
  List<Map<String, dynamic>> _messages = const [];
  final _text = TextEditingController();
  Timer? _poll;
  bool _sending = false;
  Map<String, dynamic>? _replyTo;

  /// [Sprint 53 F2] The group's channel: a new message (or one changed) comes at once, and the 4-second poll runs only
  /// while the channel is down; with it, a check every 30 seconds as a safety net.
  LiveSubscription? _channel;
  DateTime _loadedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _load();
    _channel = ref.read(liveFeedProvider).join('chat.${widget.groupId}', {'chat': (_) => _load()});
    _channel!.subscribed.addListener(_load);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_channel?.subscribed.value != true || DateTime.now().difference(_loadedAt).inSeconds >= 30) _load();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _channel?.subscribed.removeListener(_load);
    _channel?.leave();
    _recorder.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _loadedAt = DateTime.now();
    try {
      final m = await _repo.messages(widget.groupId);
      if (mounted) setState(() => _messages = m);
      unawaited(_repo.read(widget.groupId).catchError((_) {}));
    } on ApiError {
      // Asked again in a moment.
    }
  }

  /// A voice note: the first tap records (AAC, up to the server's two minutes), the second stops and sends it.
  final _recorder = AudioRecorder();
  DateTime? _recordingSince;

  Future<void> _voice() async {
    if (_recordingSince == null) {
      if (!await _recorder.hasPermission()) {
        if (mounted) showGlmToast(context, L.of(context).micDenied, error: true);
        return;
      }
      final dir = await getTemporaryDirectory();
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 48000, sampleRate: 22050, numChannels: 1),
          path: '${dir.path}/note-${DateTime.now().millisecondsSinceEpoch}.m4a');
      setState(() => _recordingSince = DateTime.now());
      return;
    }
    final seconds = DateTime.now().difference(_recordingSince!).inSeconds.clamp(1, 120);
    final path = await _recorder.stop();
    setState(() {
      _recordingSince = null;
      _sending = true;
    });
    try {
      if (path != null) {
        await ref.read(apiProvider).upload('/groups/${widget.groupId}/media', 'file', path, fields: {'kind': 'audio', 'seconds': seconds}, type: 'audio/mp4');
        await _load();
      }
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.say(widget.groupId, body, replyTo: _replyTo?['id'] as int?);
      _text.clear();
      _replyTo = null;
      await _load();
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _react(Map<String, dynamic> m, String key) async {
    try {
      await ref.read(consoleRepositoryProvider).react(widget.groupId, m['id'] as int, key);
      HapticFeedback.selectionClick();
      await _load();
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    }
  }

  Future<void> _actions(Map<String, dynamic> m) async {
    final l = L.of(context);
    final pick = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final e in _reactions.entries)
                Semantics(
                  button: true,
                  selected: m['my_reaction'] == e.key,
                  label: {'ball': l.reactBall, 'fire': l.reactFire, 'cup': l.reactCup, 'laugh': l.reactLaugh}[e.key],
                  child: InkResponse(
                    onTap: () => Navigator.pop(ctx, e.key),
                    radius: 28,
                    child: Container(
                      width: 52, height: 52, alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: m['my_reaction'] == e.key ? ctx.palette.brand : ctx.palette.surfaceRaised),
                      child: Text(e.value, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            ListTile(leading: const Icon(Icons.reply_rounded), title: Text(l.reply), onTap: () => Navigator.pop(ctx, 'reply')),
          ]),
        ),
      ),
    );
    if (pick == null || !mounted) return;
    if (pick == 'reply') return setState(() => _replyTo = m);
    await _react(m, pick);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final me = ref.watch(authProvider).value?.id;
    return Column(children: [
      Expanded(
        child: ListView(reverse: true, padding: const EdgeInsets.all(12), children: [
          for (final m in _messages.reversed)
            if (m['kind'] == 'note')
              const SizedBox.shrink()
            else
              _bubble(context, l, p, m, mine: (m['user'] as Map<dynamic, dynamic>?)?['id'] == me),
        ]),
      ),
      if (_replyTo != null)
        Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
          decoration: BoxDecoration(color: p.surfaceRaised, borderRadius: BorderRadius.circular(10), border: BorderDirectional(start: BorderSide(color: p.brandLight, width: 3))),
          child: Row(children: [
            Expanded(child: Text(l.replyingTo('${_replyTo!['body'] ?? ''}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textSoft, fontSize: 12))),
            IconButton(tooltip: l.cancel, icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _replyTo = null)),
          ]),
        ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(children: [
            IconButton(
              tooltip: _recordingSince == null ? l.recordVoice : l.stopAndSend,
              icon: Icon(_recordingSince == null ? Icons.mic_rounded : Icons.stop_circle_rounded, color: _recordingSince == null ? p.gold : context.glm.liveText),
              onPressed: _sending ? null : _voice,
            ),
            IconButton(
              tooltip: l.sendPhoto,
              icon: Icon(Icons.image_rounded, color: p.gold),
              onPressed: _sending
                  ? null
                  : () async {
                      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
                      if (f == null) return;
                      setState(() => _sending = true);
                      try {
                        await ref.read(apiProvider).upload('/groups/${widget.groupId}/media', 'file', f.path, fields: {'kind': 'image'});
                        await _load();
                      } on ApiError catch (e) {
                        if (mounted) showGlmToast(this.context, e.message, error: true);
                      } finally {
                        if (mounted) setState(() => _sending = false);
                      }
                    },
            ),
            Expanded(
              child: TextField(
                controller: _text, minLines: 1, maxLines: 3,
                decoration: InputDecoration(hintText: l.typeMessage, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(22))),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: l.send,
              child: InkResponse(
                onTap: _sending ? null : _send,
                radius: 24,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: p.gold, shape: BoxShape.circle),
                  child: Icon(Icons.send_rounded, color: p.onGold, size: 20, textDirection: Directionality.of(context)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _bubble(BuildContext context, L l, GlmPalette p, Map<String, dynamic> m, {required bool mine}) {
    final reactions = ((m['reactions'] as Map<dynamic, dynamic>?) ?? const {}).entries.where((e) => (e.value as num) > 0).toList();
    final reply = m['reply_to'] as Map<dynamic, dynamic>?;
    final bubble = Container(
      margin: EdgeInsets.only(bottom: reactions.isEmpty ? 6 : 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: mine ? p.brandDark : p.surface,
        borderRadius: BorderRadius.circular(14),
        border: mine ? null : Border.all(color: p.surfaceRaised),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!mine) Text('${(m['user'] as Map<dynamic, dynamic>?)?['name'] ?? ''}', style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12)),
        if (reply != null)
          Container(
            margin: const EdgeInsets.only(top: 2, bottom: 4),
            padding: const EdgeInsetsDirectional.only(start: 6),
            decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: p.brandLight, width: 2))),
            child: Text('${reply['body'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textSoft, fontSize: 11)),
          ),
        if (m['deleted'] != true && m['kind'] == 'image')
          _GroupImage(path: '/groups/${widget.groupId}/media/${m['id']}')
        else if (m['deleted'] != true && m['kind'] == 'audio')
          _GroupVoice(path: '/groups/${widget.groupId}/media/${m['id']}', seconds: m['seconds'] as int? ?? 0)
        else
          Text(m['deleted'] == true ? l.messageDeleted : m['kind'] == 'text' ? '${m['body'] ?? ''}' : l.mediaOnWeb,
              style: TextStyle(fontStyle: m['deleted'] == true || m['kind'] != 'text' ? FontStyle.italic : null)),
        if (m['deleted'] != true && m['kind'] == 'image' && (m['body'] ?? '') != '') Text('${m['body']}'),
      ]),
    );
    final withReactions = Stack(clipBehavior: Clip.none, children: [
      bubble,
      if (reactions.isNotEmpty)
        PositionedDirectional(
          bottom: 2, end: 8,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final e in reactions)
              Container(
                margin: const EdgeInsetsDirectional.only(start: 3),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(color: m['my_reaction'] == e.key ? p.brand : p.surfaceRaised, borderRadius: BorderRadius.circular(8)),
                child: Text('${_reactions[e.key] ?? ''} ${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
    ]);
    // A swipe answers it (the bubble springs back), a long press opens the reactions and the reply.
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Dismissible(
        key: ValueKey('m${m['id']}'),
        direction: m['deleted'] == true ? DismissDirection.none : DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          HapticFeedback.selectionClick();
          setState(() => _replyTo = m);
          return false;
        },
        background: Align(alignment: AlignmentDirectional.centerStart, child: Icon(Icons.reply_rounded, color: p.brandLight)),
        child: GestureDetector(onLongPress: m['deleted'] == true ? null : () => _actions(m), child: withReactions),
      ),
    );
  }
}
