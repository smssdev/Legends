import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glm_button.dart';
import '../auth/auth_controller.dart';
import '../inbox/inbox_data.dart';

/// [Sprint 18 H] The assistant coach (Sprint 22, Manager Bot) in the app: a button over every screen (on the left in
/// Arabic, on the right in English, as on the site) opens the conversation. The server answers from the game's guide,
/// or reads the coach's numbers with the free AI when it is on; it advises and never changes anything itself.
class AssistantRepository {
  AssistantRepository(this._api);

  final ApiClient _api;

  /// [Sprint 59 F1] Both replies read through their generated models (`AssistantStart`, `AssistantAnswer`).
  Future<api.AssistantStart> start(String page) async =>
      api.AssistantStart.fromJson(await _api.get('/assistant/start', query: {'page': page}));
  Future<api.AssistantAnswer> ask(
    String question, {
    String? topic,
    required String page,
    int? leagueId,
    List<Map<String, String>> history = const [],
  }) async => api.AssistantAnswer.fromJson(
    await _api.post('/assistant/ask', {'question': question, 'topic': ?topic, 'page': page, 'league_id': ?leagueId, 'history': history}),
  );
}

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) => AssistantRepository(ref.watch(apiProvider)));

/// The screen's name for the assistant (its first path part) and its league, from the app's path.
({String page, int? league}) contextOf(String path) {
  final seg = Uri.parse(path).pathSegments;
  if (seg.isEmpty) return (page: 'home', league: null);
  if (seg.first == 'leagues' && seg.length >= 2) {
    final id = int.tryParse(seg[1]);
    return (page: seg.length >= 3 ? seg[2] : 'league', league: id);
  }
  return (page: seg.first, league: null);
}

/// Where an answer's «go» leads in the app.
String? goRoute(String? go, int? league) => switch (go) {
  null || '' => null,
  'leagues' => '/leagues',
  'league' => league == null ? '/leagues' : '/leagues/$league',
  _ =>
    appRoute('/$go', league) ??
        (const {'wallet', 'profile', 'support', 'ideas', 'groups', 'tournaments', 'inbox'}.contains(go) ? '/$go' : null),
};

/// Over every screen of a signed-in coach, except the sign-in pages and the live match (which fills the screen).
class AssistantOverlay extends ConsumerStatefulWidget {
  const AssistantOverlay({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<AssistantOverlay> createState() => _AssistantOverlayState();
}

class _AssistantOverlayState extends ConsumerState<AssistantOverlay> {
  String _path = '/';

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_moved);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_moved);
    super.dispose();
  }

  void _moved() {
    final p = widget.router.routerDelegate.currentConfiguration.uri.path;
    if (p != _path && mounted) setState(() => _path = p);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authProvider).value != null;
    const hidden = ['/start', '/login', '/register', '/forgot', '/offline', '/join', '/match/'];
    final show = signedIn && !hidden.any((h) => _path.startsWith(h));
    return Stack(
      children: [
        widget.child,
        if (show)
          PositionedDirectional(
            end: 14,
            bottom: 96 + MediaQuery.of(context).padding.bottom,
            child: Material(
              color: context.palette.brand,
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => openAssistant(widget.router.routerDelegate.navigatorKey.currentContext ?? context, widget.router, _path),
                child: const SizedBox(width: 52, height: 52, child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 28)),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> openAssistant(BuildContext context, GoRouter router, String path) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => AssistantSheet(router: router, path: path),
);

class AssistantSheet extends ConsumerStatefulWidget {
  const AssistantSheet({super.key, required this.router, required this.path});

  final GoRouter router;
  final String path;

  @override
  ConsumerState<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends ConsumerState<AssistantSheet> {
  late final AssistantRepository _repo = ref.read(assistantRepositoryProvider);
  late final ctx = contextOf(widget.path);
  final List<({bool me, String text, String? go})> _talk = [];
  List<({String question, String? topic})> _suggested = const [];
  String _name = '';
  bool _busy = true;
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo
        .start(ctx.page)
        .then(
          (s) {
            if (!mounted) return;
            setState(() {
              _name = s.name;
              _talk.add((me: false, text: s.intro, go: null));
              _suggested = _questions(s.questions);
              _busy = false;
            });
          },
          onError: (Object e) {
            if (mounted) setState(() => _busy = false);
          },
        );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<({String question, String? topic})> _questions(List<api.AssistantQuestion> list) => [
    for (final q in list) (question: q.question, topic: q.topic),
  ];

  Future<void> _ask(String question, {String? topic}) async {
    if (question.trim().isEmpty || _busy) return;
    final history = [
      for (final t in _talk.skip(1)) {'from': t.me ? 'me' : 'bot', 'text': t.text},
    ];
    setState(() {
      _talk.add((me: true, text: question.trim(), go: null));
      _busy = true;
      _suggested = const [];
    });
    _text.clear();
    try {
      final a = await _repo.ask(
        question.trim(),
        topic: topic,
        page: ctx.page,
        leagueId: ctx.league,
        history: history.length > 8 ? history.sublist(history.length - 8) : history,
      );
      if (!mounted) return;
      setState(() {
        _talk.add((me: false, text: a.answer, go: a.go));
        _suggested = _questions(a.related);
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _talk.add((me: false, text: e.message, go: null)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return SizedBox(
      height: MediaQuery.of(context).size.height * .8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Text(_name, style: context.text.titleMedium),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final t in _talk)
                    Align(
                      alignment: t.me ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: t.me ? p.gold.withValues(alpha: .18) : p.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.text),
                            if (goRoute(t.go, ctx.league) case final route?)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GlmButton(
                                  label: l.openIt,
                                  variant: GlmButtonVariant.quiet,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.router.push(route);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final q in _suggested.take(6))
                        ActionChip(
                          label: Text(q.question),
                          onPressed: () => _ask(q.question, topic: q.topic),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(hintText: l.typeMessage),
                        onSubmitted: (v) => _ask(v),
                      ),
                    ),
                    IconButton(
                      tooltip: l.send,
                      icon: Icon(Icons.send_rounded, color: p.gold),
                      onPressed: _busy ? null : () => _ask(_text.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
