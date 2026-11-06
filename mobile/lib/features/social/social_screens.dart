import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
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

/// [Sprint 18 E] The league's social screens in the app: the friendlies (Sprint 24, a quick match played back fast),
/// the predictions and the newspaper (UP12), and the chat groups (Sprint 29). The server decides and writes all of it.
class SocialRepository {
  SocialRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> friendlies(int league) => _api.get('/leagues/$league/friendlies');
  Future<Map<String, dynamic>> playFriendly(int league, int opponent) =>
      _api.post('/leagues/$league/friendlies', {'opponent_id': opponent, 'idempotency_key': 'app-${DateTime.now().microsecondsSinceEpoch}'});
  Future<Map<String, dynamic>> predictions(int league) => _api.get('/leagues/$league/predictions');
  Future<Map<String, dynamic>> predict(int league, int fixture, String pick) => _api.post('/leagues/$league/predictions', {'fixture_id': fixture, 'pick': pick});
  Future<Map<String, dynamic>> newspaper(int league) => _api.get('/leagues/$league/newspaper');
  Future<Map<String, dynamic>> write(int league, String title, String body) => _api.post('/leagues/$league/newspaper/articles', {'title': title, 'body': body});
  Future<Map<String, dynamic>> decide(int league, int article, bool publish) => _api.post('/leagues/$league/newspaper/articles/$article/decide', {'publish': publish});
  Future<Map<String, dynamic>> groups() => _api.get('/groups');
  Future<List<Map<String, dynamic>>> messages(int group) async => [for (final m in ((await _api.get('/groups/$group/messages'))['messages'] as List? ?? const [])) m as Map<String, dynamic>];
  Future<void> say(int group, String body) => _api.post('/groups/$group/messages', {'body': body});
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

Widget _page(String title, Widget body) => Scaffold(appBar: AppBar(title: Text(title)), body: GlmBackground(child: body));

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
          final recent = f['recent'] as List? ?? const [];
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
                  title: Text('${((r as Map)['opponent'] as Map?)?['name'] ?? ''}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                  trailing: Text('${r['goals_for']} - ${r['goals_against']}', textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuickMatchScreen(home: '${f['club']?['name'] ?? ''}', played: Map<String, dynamic>.from(r)))),
                ),
              const SizedBox(height: 8),
            ],
            for (final o in (f['opponents'] as List? ?? const []))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  padding: const EdgeInsets.all(10),
                  gold: (o as Map)['recommended'] == true,
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
                                await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => QuickMatchScreen(home: '${f['club']?['name'] ?? ''}', played: Map<String, dynamic>.from(r['friendly'] as Map))));
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
  late final List<Map> _timeline = [for (final e in ((widget.played['report'] as Map?)?['timeline'] as List? ?? const [])) e as Map];
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
    final score = done ? [widget.played['goals_for'], widget.played['goals_against']] : (last?['score'] as List? ?? const [0, 0]);
    final away = '${(widget.played['opponent'] as Map?)?['name'] ?? ''}';
    final best = (widget.played['report'] as Map?)?['best'] as List? ?? const [];
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
                      Expanded(child: Text('${(b as Map)['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
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
            for (final m in (d['matches'] as List? ?? const []))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text('${((m as Map)['home'] as Map)['name']}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
                      const Text(' — '),
                      Expanded(child: Text('${(m['away'] as Map)['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 8),
                    if (m['open'] != true)
                      Text(l.predictionClosed, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted))
                    else
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        emptySelectionAllowed: true,
                        segments: [
                          ButtonSegment(value: 'home', label: Text('${(m['home'] as Map)['code']}', textDirection: TextDirection.ltr)),
                          ButtonSegment(value: 'draw', label: Text(l.draw)),
                          ButtonSegment(value: 'away', label: Text('${(m['away'] as Map)['code']}', textDirection: TextDirection.ltr)),
                        ],
                        selected: {if (m['mine'] != null) '${m['mine'] is Map ? (m['mine'] as Map)['pick'] : m['mine']}'},
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
          final e = d['edition'] as Map?;
          final articles = d['articles'] as List? ?? const [];
          final pending = d['pending'] as List? ?? const [];
          Future<void> decide(int id, bool publish) async {
            await _try(context, () => ref.read(socialRepositoryProvider).decide(leagueId, id, publish));
            ref.invalidate(newspaperProvider(leagueId));
          }

          return ListView(padding: const EdgeInsets.all(12), children: [
            if (e == null)
              Padding(padding: const EdgeInsets.all(16), child: Text(l.noEdition, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)))
            else ...[
              for (final s in (e['stories'] as List? ?? const []))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    gold: true,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('${(s as Map)['title']}', style: context.text.titleMedium),
                      Text('${s['text']}', style: TextStyle(color: p.textMuted)),
                    ]),
                  ),
                ),
              SectionTitle(l.roundResults(e['round'] as int? ?? 0)),
              GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(children: [
                  for (final r in (e['results'] as List? ?? const []))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text('${(r as Map)['home']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                        Text('${r['home_goals']} - ${r['away_goals']}', textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800)),
                        Expanded(child: Text('${r['away']}', textDirection: TextDirection.ltr, textAlign: TextAlign.end)),
                      ]),
                    ),
                ]),
              ),
              if (e['coach'] is Map) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Text('🎩', style: TextStyle(fontSize: 22)),
                  title: Text(l.coachOfRound),
                  subtitle: Text('${((e['coach'] as Map)['coach'] as Map?)?['name'] ?? ''} · ${(e['coach'] as Map)['club'] ?? ''}'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            if (d['is_owner'] == true && pending.isNotEmpty) ...[
              SectionTitle(l.pendingArticles),
              for (final a in pending)
                GlmCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${(a as Map)['title']}', style: context.text.titleMedium),
                    Text('${a['body']}'),
                    Text('${(a['author'] as Map?)?['name'] ?? ''}', style: TextStyle(color: p.textMuted, fontSize: 12)),
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
                    Text('${(a as Map)['title']}', style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    Text('${a['body']}'),
                    const SizedBox(height: 4),
                    Text([(a['author'] as Map?)?['name'] ?? '', if (DateTime.tryParse('${a['at']}') != null) when(context, DateTime.parse('${a['at']}').toLocal())].join(' · '),
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
  final g = r?['group'] as Map?;
  if (g != null && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}')));
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
      appBar: AppBar(title: Text(l.groups), actions: [
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
            final g = r?['group'] as Map?;
            if (g != null && context.mounted) {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}')));
            }
          }
          name.dispose();
          members.dispose();
        },
      ),
      body: GlmBackground(child: _groupsBody(context, ref, l)),
    );
  }

  Widget _groupsBody(BuildContext context, WidgetRef ref, L l) => AsyncView(
        value: ref.watch(groupsProvider),
        onRetry: () => ref.invalidate(groupsProvider),
        data: (d) {
          final groups = d['groups'] as List? ?? const [];
          if (groups.isEmpty) return Center(child: Text(l.noGroups));
          return RefreshIndicator(
            onRefresh: () => ref.refresh(groupsProvider.future),
            child: ListView(children: [
              for (final g in groups)
                ListTile(
                  leading: CircleAvatar(backgroundColor: context.palette.brand, child: const Icon(Icons.groups_rounded, color: Colors.white)),
                  title: Text('${(g as Map)['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${(g['last'] as Map?)?['body'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: (g['unread'] as int? ?? 0) > 0 ? Badge(label: Text('${g['unread']}')) : null,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}')));
                    ref.invalidate(groupsProvider);
                  },
                ),
            ]),
          );
        },
      );
}

/// A group's conversation: the latest page, asked again every few seconds while open, and a line to write.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.groupId, required this.name});

  final int groupId;
  final String name;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final SocialRepository _repo = ref.read(socialRepositoryProvider);
  List<Map<String, dynamic>> _messages = const [];
  final _text = TextEditingController();
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final m = await _repo.messages(widget.groupId);
      if (mounted) setState(() => _messages = m);
      unawaited(_repo.read(widget.groupId).catchError((_) {}));
    } on ApiError {
      // Asked again in a moment.
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.say(widget.groupId, body);
      _text.clear();
      await _load();
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: GlmBackground(
        child: Column(children: [
          Expanded(
            child: ListView(reverse: true, padding: const EdgeInsets.all(12), children: [
              for (final m in _messages.reversed)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.surfaceRaised)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${(m['user'] as Map?)?['name'] ?? ''}', style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12)),
                      Text(m['deleted'] == true ? l.messageDeleted : m['kind'] == 'text' ? '${m['body'] ?? ''}' : l.mediaOnWeb,
                          style: TextStyle(fontStyle: m['deleted'] == true || m['kind'] != 'text' ? FontStyle.italic : null)),
                    ]),
                  ),
                ),
            ]),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(children: [
                Expanded(child: TextField(controller: _text, minLines: 1, maxLines: 4, decoration: InputDecoration(hintText: l.typeMessage), onSubmitted: (_) => _send())),
                IconButton(tooltip: l.send, icon: Icon(Icons.send_rounded, color: p.gold), onPressed: _sending ? null : _send),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
