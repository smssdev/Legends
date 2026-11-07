import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/motion.dart';
import '../leagues/shell.dart' show GameBar;

/// A club the simulator can field (the data's clubs, the national teams left out by the server).
class SimClub {
  const SimClub({required this.id, required this.name, required this.code, this.league, this.strength, this.logo, this.color});

  factory SimClub.fromJson(Map<String, dynamic> j) => SimClub(
        id: j['id'] as int,
        name: '${j['name'] ?? ''}',
        code: '${j['code'] ?? ''}',
        league: j['league_name'] as String?,
        strength: (j['strength_cp'] as num?)?.toInt(),
        logo: j['logo'] as String?,
        color: _hex(j['color_primary']),
      );

  final int id;
  final String name, code;
  final String? league, logo;
  final int? strength;
  final Color? color;

  static Color? _hex(Object? v) {
    final s = '${v ?? ''}'.replaceFirst('#', '');
    final n = int.tryParse(s, radix: 16);
    return n == null || s.length != 6 ? null : Color(0xFF000000 | n);
  }
}

class SimRepository {
  SimRepository(this._api);

  final ApiClient _api;

  /// The clubs, strongest first, matching [q] (the server answers a list).
  Future<List<SimClub>> clubs(String q) async {
    try {
      final r = await _api.dio.get('/sim/clubs', queryParameters: {if (q.trim().isNotEmpty) 'q': q.trim()});
      return [for (final c in (r.data as List? ?? const [])) SimClub.fromJson(c as Map<String, dynamic>)];
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// A match against the computer (solo: the coach holds home), or against a friend (live: two seats, home here and
  /// away in the friend's link).
  Future<({int id, String? home, String? away})> create({required SimClub me, required SimClub them, required bool friend}) async {
    final j = await _api.post('/sim/matches', {
      'home_id': me.id,
      'away_id': them.id,
      'mode': friend ? 'live' : 'solo',
      'control': {'home': 'me', 'away': friend ? 'me' : 'cpu'},
    });
    final seats = j['seats'] as Map<String, dynamic>?;
    return (id: j['id'] as int, home: seats?['home'] as String?, away: seats?['away'] as String?);
  }
}

final simRepositoryProvider = Provider<SimRepository>((ref) => SimRepository(ref.watch(apiProvider)));
final simClubsProvider = FutureProvider.autoDispose.family<List<SimClub>, String>((ref, q) => ref.read(simRepositoryProvider).clubs(q));

/// [Sprint 47] The simulator in the app, as in the approved design: a trial match apart from the leagues, against the
/// computer or a friend. The two crests face each other over the night pitch with a VS between them; the two modes as
/// cards; your team and the opponent picked from the data's clubs; the gold button. The match itself is played on the
/// simulator's page (the site's, the same for both friends), opened after the face-off.
class SimSetupScreen extends ConsumerStatefulWidget {
  const SimSetupScreen({super.key});

  @override
  ConsumerState<SimSetupScreen> createState() => _SimSetupScreenState();
}

class _SimSetupScreenState extends ConsumerState<SimSetupScreen> {
  bool _friend = false;
  SimClub? _me, _them;
  bool _busy = false;

  Future<void> _start(List<SimClub> clubs) async {
    final l = L.of(context);
    final me = _me ?? (clubs.isNotEmpty ? clubs.first : null);
    if (me == null) return;
    final rest = clubs.where((c) => c.id != me.id).toList();
    final them = _them != null && _them!.id != me.id ? _them! : (rest.isEmpty ? null : rest[math.Random().nextInt(math.min(rest.length, 12))]);
    if (them == null) return;
    setState(() => _busy = true);
    try {
      final m = await ref.read(simRepositoryProvider).create(me: me, them: them, friend: _friend);
      if (!mounted) return;
      GameSounds.play(Sfx.whistle);
      await Navigator.of(context).push(PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => SimVersusScreen(
          home: me,
          away: them,
          friend: _friend,
          matchUrl: '${AppConfig.siteUrl}/sim/${m.id}${m.home == null ? '' : '?seat=${m.home}'}',
          inviteUrl: m.away == null ? null : '${AppConfig.siteUrl}/sim/${m.id}?seat=${m.away}',
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.status == 404 ? l.simOff : e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool mine) async {
    final picked = await showModalBottomSheet<SimClub>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _ClubSearch());
    if (picked != null && mounted) setState(() => mine ? _me = picked : _them = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final clubs = ref.watch(simClubsProvider(''));
    final list = clubs.value ?? const <SimClub>[];
    final me = _me ?? (list.isNotEmpty ? list.first : null);
    return Scaffold(
      appBar: GameBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.simTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(l.simLead, style: TextStyle(fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w500)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: p.success.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
            child: Text(l.simFree, style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
      body: GlmBackground(
        wide: true,
        child: LayoutBuilder(builder: (context, box) {
          final modes = Row(children: [
            Expanded(child: _ModeCard(on: !_friend, icon: Icons.smart_toy_rounded, iconColor: p.ring, title: l.simVsCpu, lead: l.simVsCpuLead, onTap: () => setState(() => _friend = false))),
            const SizedBox(width: 10),
            Expanded(child: _ModeCard(on: _friend, icon: Icons.group_rounded, iconColor: p.gold, title: l.simVsFriend, lead: l.simVsFriendLead, onTap: () => setState(() => _friend = true))),
          ]);
          final teams = SizedBox(
            height: 96,
            child: clubs.isLoading && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : clubs.hasError && list.isEmpty
                    ? Center(child: Text(clubs.error is ApiError && (clubs.error as ApiError).status == 404 ? l.simOff : '${clubs.error}', textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)))
                    : ListView(scrollDirection: Axis.horizontal, children: [
                        for (final c in [if (_me != null && !list.take(10).any((x) => x.id == _me!.id)) _me!, ...list.take(10)])
                          Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: _TeamChip(club: c, on: c.id == me?.id, onTap: () => setState(() => _me = c))),
                      ]),
          );
          final picks = <Widget>[
            _Label(l.simYourTeam, action: l.simSearch, onAction: () => _pick(true)),
            const SizedBox(height: 6),
            teams,
            const SizedBox(height: 10),
            _Label(l.simOpponent, action: l.simSearch, onAction: () => _pick(false)),
            const SizedBox(height: 6),
            _OpponentRow(club: _them, onTap: () => _pick(false), onClear: _them == null ? null : () => setState(() => _them = null)),
          ];
          final go = GlmButton(
            label: _friend ? l.simOpenRoom : l.simStart,
            block: true,
            loading: _busy,
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: list.isEmpty ? null : () => _start(list),
          );
          // [Sprint 47] The phone is held sideways (the app is landscape): the face-off and the two modes on one side,
          // the teams and the gold button on the other, all in sight at once.
          if (box.maxWidth > box.maxHeight) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    flex: 11,
                    child: Column(children: [
                      Expanded(child: _FaceOff(home: me, away: _them, friend: _friend)),
                      const SizedBox(height: 10),
                      modes,
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 9,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: picks))),
                      const SizedBox(height: 10),
                      go,
                    ]),
                  ),
                ]),
              ),
            );
          }
          return ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 24), children: [
            SizedBox(height: 190, child: _FaceOff(home: me, away: _them, friend: _friend)),
            const SizedBox(height: 12),
            modes,
            const SizedBox(height: 16),
            ...picks,
            const SizedBox(height: 22),
            go,
          ]);
        }),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.palette.textSoft))),
        if (action != null)
          TextButton.icon(onPressed: onAction, icon: const Icon(Icons.search_rounded, size: 18), label: Text(action!),
              style: TextButton.styleFrom(foregroundColor: context.glm.brandText, textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: GlmFonts.body))),
      ]);
}

/// A mode: its icon, its name and its line, the chosen one in a mint ring.
class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.on, required this.icon, required this.iconColor, required this.title, required this.lead, required this.onTap});

  final bool on;
  final IconData icon;
  final Color iconColor;
  final String title, lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ring = context.glm.day ? p.brand : p.ring;
    return Semantics(
      selected: on,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: on ? p.brand.withValues(alpha: .16) : p.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: on ? ring : p.surfaceRaised, width: 2),
          boxShadow: on ? [BoxShadow(color: ring.withValues(alpha: .15), spreadRadius: 4)] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              GameSounds.play(Sfx.tap);
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(lead, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.textMuted)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A club to pick: its crest, its name, its strength; the chosen one framed in gold.
class _TeamChip extends StatelessWidget {
  const _TeamChip({required this.club, required this.on, required this.onTap});

  final SimClub club;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: on ? p.gold.withValues(alpha: .12) : p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: on ? p.gold : p.surfaceRaised, width: 2)),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: SizedBox(
          width: 86,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClubCrest(url: club.logo, name: club.code, size: 36, color: club.color),
              const SizedBox(height: 4),
              Text(club.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              if (club.strength != null)
                Text('${club.strength}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 14, color: on ? context.glm.goldText : p.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The opponent: the one picked, or a random one from the strongest.
class _OpponentRow extends StatelessWidget {
  const _OpponentRow({required this.club, required this.onTap, this.onClear});

  final SimClub? club;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.surfaceRaised)),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            if (club == null)
              Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.gold, width: 2)), child: Icon(Icons.shuffle_rounded, color: p.gold, size: 20))
            else
              ClubCrest(url: club!.logo, name: club!.code, size: 36, color: club!.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(club?.name ?? l.simRandom, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: club == null ? null : TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            if (club?.strength != null) Text(l.simStrength(club!.strength!), style: TextStyle(color: p.textMuted, fontSize: 13)),
            if (onClear != null) IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded), tooltip: MaterialLocalizations.of(context).deleteButtonTooltip),
          ]),
        ),
      ),
    );
  }
}

/// The search for any club, in a sheet.
class _ClubSearch extends ConsumerStatefulWidget {
  const _ClubSearch();

  @override
  ConsumerState<_ClubSearch> createState() => _ClubSearchState();
}

class _ClubSearchState extends ConsumerState<_ClubSearch> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final found = ref.watch(simClubsProvider(_q));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(hintText: l.simSearch, prefixIcon: const Icon(Icons.search_rounded)),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: found.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e is ApiError && e.status == 404 ? l.simOff : '$e', style: TextStyle(color: p.textMuted))),
              data: (clubs) => ListView(children: [
                for (final c in clubs)
                  ListTile(
                    leading: ClubCrest(url: c.logo, name: c.code, size: 36, color: c.color),
                    title: Text(c.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                    subtitle: c.league == null ? null : Text(c.league!, textDirection: TextDirection.ltr, textAlign: TextAlign.start, style: TextStyle(color: p.textMuted, fontSize: 12)),
                    trailing: c.strength == null ? null : Text('${c.strength}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 18)),
                    onTap: () => Navigator.pop(context, c),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The face-off over the night pitch: the two crests slide in toward each other, the VS swings between them, the
/// floodlights sway and a ball bounces on the centre spot.
class _FaceOff extends StatefulWidget {
  const _FaceOff({required this.home, required this.away, required this.friend});

  final SimClub? home, away;
  final bool friend;

  @override
  State<_FaceOff> createState() => _FaceOffState();
}

class _FaceOffState extends State<_FaceOff> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!still && Ambient.on) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _in.value = 1;
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = glmNight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _loop]),
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_in.value.clamp(0.0, 1.0));
          final w = math.sin(_loop.value * math.pi * 2);
          final bounce = (math.sin(_loop.value * math.pi * 2 * 1.4)).abs();
          Widget side(Widget crest, String name, bool start) => Transform.translate(
                offset: Offset((start ? 1 : -1) * (1 - t) * 120 * (Directionality.of(context) == TextDirection.rtl ? 1 : -1), w * 3),
                child: Opacity(
                  opacity: _in.value.clamp(0.0, 1.0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(height: 76, child: Center(child: crest)),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .8), borderRadius: BorderRadius.circular(6)),
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.text)),
                    ),
                  ]),
                ),
              );
          final away = widget.friend
              ? Container(width: 60, height: 60, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.gold, width: 3)),
                  child: Text('?', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 30, fontWeight: FontWeight.w700, color: p.gold)))
              : widget.away != null
                  ? ClubCrest(url: widget.away!.logo, name: widget.away!.code, size: 66, color: widget.away!.color)
                  : Icon(Icons.smart_toy_rounded, size: 62, color: p.ring);
          return Stack(fit: StackFit.expand, children: [
            ColoredBox(color: p.bgDeep),
            CustomPaint(painter: _NightPitch(sway: w)),
            Row(children: [
              Expanded(child: side(widget.home == null ? const SizedBox(width: 66) : ClubCrest(url: widget.home!.logo, name: widget.home!.code, size: 66, color: widget.home!.color), widget.home?.name ?? '', true)),
              Transform.scale(
                scale: 1 + .1 * w,
                child: Transform.rotate(
                  angle: .07 * w,
                  child: Text('VS', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 40, color: p.gold,
                      shadows: [Shadow(color: p.goldDark, offset: const Offset(0, 2)), Shadow(color: p.gold.withValues(alpha: .55), blurRadius: 18)])),
                ),
              ),
              Expanded(child: side(away, widget.friend ? l.simWaitingFriend : widget.away?.name ?? l.simComputer, false)),
            ]),
            Positioned(
              bottom: 12 + bounce * 26,
              left: 0,
              right: 0,
              child: Center(child: CustomPaint(size: const Size.square(18), painter: BallPainter())),
            ),
          ]);
        },
      ),
    );
  }
}

/// A night pitch in perspective under two swaying beams.
class _NightPitch extends CustomPainter {
  _NightPitch({required this.sway});

  final double sway;

  @override
  void paint(Canvas canvas, Size s) {
    final p = glmNight;
    for (final left in [true, false]) {
      canvas.save();
      canvas.translate(left ? 30 : s.width - 30, -10);
      canvas.rotate((left ? -.25 : .25) + .2 * sway * (left ? 1 : -1));
      final beam = Path()..addPolygon([const Offset(-7, 0), const Offset(7, 0), Offset(70, s.height * 1.3), Offset(-70, s.height * 1.3)], true);
      canvas.drawPath(beam, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0x47FFF0C8), const Color(0x00FFF0C8)]).createShader(Rect.fromLTWH(-70, 0, 140, s.height)));
      canvas.restore();
    }
    final top = s.height * .54, k = s.width / 390;
    final field = Path()..addPolygon([Offset(80 * k, top), Offset(310 * k, top), Offset(s.width, s.height), Offset(0, s.height)], true);
    canvas.drawPath(field, Paint()..color = p.pitchDark);
    canvas.drawPath(Path()..addPolygon([Offset(118 * k, top), Offset(157 * k, top), Offset(140 * k, s.height), Offset(78 * k, s.height)], true), Paint()..color = p.pitch);
    canvas.drawPath(Path()..addPolygon([Offset(195 * k, top), Offset(234 * k, top), Offset(250 * k, s.height), Offset(195 * k, s.height)], true), Paint()..color = p.pitch);
    final line = Paint()
      ..color = p.text.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(field, line);
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width / 2, top + (s.height - top) * .4), width: 108 * k, height: 28), line);
  }

  @override
  bool shouldRepaint(_NightPitch old) => old.sway != sway;
}

/// [Sprint 47] The face-off before the match, the approved design's motion graphic: the screen split on a gold
/// diagonal in the two sides' colours, speed lines running, the crests slamming in one after the other, the VS
/// crashing between them with a flash ring, the three lines' strength bars filling, sparks rising, and the countdown
/// ring to the kick-off. Then the way into the match (and, against a friend, the invite).
class SimVersusScreen extends StatefulWidget {
  const SimVersusScreen({super.key, required this.home, required this.away, required this.friend, required this.matchUrl, this.inviteUrl});

  final SimClub home, away;
  final bool friend;
  final String matchUrl;
  final String? inviteUrl;

  static const length = Duration(milliseconds: 3600);

  @override
  State<SimVersusScreen> createState() => _SimVersusScreenState();
}

class _SimVersusScreenState extends State<SimVersusScreen> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: SimVersusScreen.length);
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (still || !Ambient.on) {
        _c.value = 1;
        return;
      }
      _loop.repeat();
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve curve = Curves.linear]) {
    final s = _c.value * SimVersusScreen.length.inMilliseconds / 1000;
    return curve.transform(((s - a) / (b - a)).clamp(0.0, 1.0));
  }

  Future<void> _open() async {
    GameSounds.play(Sfx.whistle);
    await launchUrl(Uri.parse(widget.matchUrl), mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = glmNight;
    final homeColor = widget.home.color ?? p.live;
    final awayColor = widget.away.color ?? const Color(0xFF2F6FDB);
    // The strength of each line from the club's (the simulator shows the real squads on its page).
    final hs = widget.home.strength ?? 75, as = widget.away.strength ?? 75;
    return Scaffold(
      backgroundColor: p.bgDeep,
      body: AnimatedBuilder(
        animation: Listenable.merge([_c, _loop]),
        builder: (context, _) {
          final slamH = _seg(0, .8, Curves.elasticOut);
          final slamA = _seg(.3, 1.1, Curves.elasticOut);
          final vs = _seg(1.1, 1.6, Curves.easeOutBack);
          final flash = _seg(1.2, 2.0, Curves.easeOut);
          final bars = _seg(1.5, 2.6, Curves.easeOutCubic);
          final ring = _seg(2.2, 3.6);
          final done = _c.value >= 1;
          final wide = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
          final title = Text('${l.simTitle} · ${widget.friend ? l.simVsFriend : l.simVsCpu}', textAlign: TextAlign.center,
              style: TextStyle(color: p.chrome, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: .5));
          final vsMark = SizedBox(
            width: 120,
            height: 120,
            child: Stack(alignment: Alignment.center, children: [
              if (flash > 0 && flash < 1)
                Container(
                  width: 70 * (1 + flash * 2.2),
                  height: 70 * (1 + flash * 2.2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.gold.withValues(alpha: (1 - flash) * .9), width: 4)),
                ),
              Transform.scale(
                scale: vs * (1 + .06 * math.sin(_loop.value * math.pi * 2)),
                child: Transform.rotate(
                  angle: (1 - vs) * -.7,
                  child: Text('VS', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 76, height: 1, color: p.gold,
                      shadows: [Shadow(color: p.goldDark, offset: const Offset(0, 4)), Shadow(color: p.gold.withValues(alpha: .7), blurRadius: 30)])),
                ),
              ),
            ]),
          );
          final duels = Opacity(
            opacity: _seg(1.4, 1.9),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .78), borderRadius: BorderRadius.circular(15), border: Border.all(color: p.surfaceRaised)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final (i, label) in [l.simAttack, l.simMidfield, l.simDefence].indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                    child: _Duel(label: label, home: (hs + [3, 0, -2][i]).clamp(1, 99), away: (as + [-2, 1, 0][i]).clamp(1, 99), t: bars, homeColor: homeColor, awayColor: awayColor),
                  ),
              ]),
            ),
          );
          final start = GlmButton(label: l.simStart, block: true, icon: const Icon(Icons.play_arrow_rounded), onPressed: _open);
          final invite = widget.inviteUrl == null
              ? null
              : GlmButton(label: l.simInvite, block: true, variant: GlmButtonVariant.brand, icon: const Icon(Icons.share_rounded),
                  onPressed: () => SharePlus.instance.share(ShareParams(text: l.simInviteText(widget.inviteUrl!))));
          final countdown = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: ring, strokeWidth: 5, color: p.gold, backgroundColor: p.surfaceRaised)),
                Text('${(3 - (ring * 3).floor()).clamp(1, 3)}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 28, color: p.gold)),
              ]),
            ),
            const SizedBox(width: 14),
            Text(l.simKickoff, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: p.text)),
          ]);
          // [Sprint 47] Landscape (the app's way): the crests at either side of the screen, the VS and the duels
          // between them, the way in at the foot. Upright: the crests one above the other on the diagonal.
          final scene = wide
              ? SizedBox(
                  width: 844,
                  height: 390,
                  child: Stack(children: [
                    Positioned(top: 12, left: 0, right: 0, child: title),
                    PositionedDirectional(top: 54, start: 36, child: _Slam(t: slamH, from: const Offset(260, 0), club: widget.home, tint: homeColor)),
                    PositionedDirectional(top: 54, end: 36, child: _Slam(t: slamA, from: const Offset(-260, 0), club: widget.away, tint: awayColor)),
                    Positioned(top: 34, left: 0, right: 0, child: Center(child: vsMark)),
                    Positioned(top: 160, left: 0, right: 0, child: Center(child: SizedBox(width: 380, child: duels))),
                    Positioned(
                      left: 0, right: 0, bottom: 14,
                      child: Center(
                        child: SizedBox(
                          width: done && invite != null ? 560 : 380,
                          child: done ? Row(children: [Expanded(child: start), if (invite != null) ...[const SizedBox(width: 12), Expanded(child: invite)]]) : countdown,
                        ),
                      ),
                    ),
                  ]),
                )
              : SizedBox(
                  width: 390,
                  height: 780,
                  child: Stack(children: [
                    Positioned(top: 14, left: 0, right: 0, child: title),
                    PositionedDirectional(top: 40, start: 28, child: _Slam(t: slamH, from: const Offset(160, -120), club: widget.home, tint: homeColor)),
                    PositionedDirectional(top: 318, end: 28, child: _Slam(t: slamA, from: const Offset(-160, 120), club: widget.away, tint: awayColor)),
                    Positioned(top: 222, left: 0, right: 0, child: Center(child: vsMark)),
                    Positioned(left: 22, right: 22, bottom: 146, child: duels),
                    Positioned(
                      left: 22, right: 22, bottom: 26,
                      child: done ? Column(children: [start, if (invite != null) ...[const SizedBox(height: 10), invite]]) : countdown,
                    ),
                  ]),
                );
          return Stack(fit: StackFit.expand, children: [
            CustomPaint(painter: _Split(home: homeColor, away: awayColor, gold: p.gold, run: _loop.value, wide: wide)),
            CustomPaint(painter: _Sparks(t: _loop.value, colors: [p.gold, p.ring, p.text])),
            SafeArea(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: scene))),
            SafeArea(child: Align(alignment: AlignmentDirectional.topStart, child: Padding(padding: const EdgeInsets.all(6), child: CloseButton(color: p.text)))),
          ]);
        },
      ),
    );
  }
}

/// A crest slamming into place from off the screen, with its name and strength.
class _Slam extends StatelessWidget {
  const _Slam({required this.t, required this.from, required this.club, required this.tint});

  final double t;
  final Offset from;
  final SimClub club;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = glmNight;
    final k = 1 - t;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: from * k,
        child: Transform.scale(
          scale: 1 + k * 1.4,
          child: Transform.rotate(
            angle: k * .3,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClubCrest(url: club.logo, name: club.code, size: 104, color: club.color),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: Text(club.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, textDirection: TextDirection.ltr,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: p.text)),
              ),
              if (club.strength != null) Text(l.simStrength(club.strength!), style: TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w700, fontSize: 15, color: Color.lerp(tint, Colors.white, .45))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One line's strength, home against away, the bars filling from the middle.
class _Duel extends StatelessWidget {
  const _Duel({required this.label, required this.home, required this.away, required this.t, required this.homeColor, required this.awayColor});

  final String label;
  final int home, away;
  final double t;
  final Color homeColor, awayColor;

  @override
  Widget build(BuildContext context) {
    final p = glmNight;
    Widget bar(int v, Color c, AlignmentDirectional from) => Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: p.text.withValues(alpha: .1), borderRadius: BorderRadius.circular(4)),
            alignment: from,
            child: FractionallySizedBox(widthFactor: (v / 100 * t).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)))),
          ),
        );
    TextStyle n() => TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 17, color: p.text);
    return Row(children: [
      SizedBox(width: 30, child: Text('$home', textAlign: TextAlign.center, style: n())),
      bar(home, homeColor, AlignmentDirectional.centerEnd),
      SizedBox(width: 56, child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.textSoft))),
      bar(away, awayColor, AlignmentDirectional.centerStart),
      SizedBox(width: 30, child: Text('$away', textAlign: TextAlign.center, style: n())),
    ]);
  }
}

/// The ground split on a gold diagonal, each half in its side's colour, speed lines running across.
class _Split extends CustomPainter {
  _Split({required this.home, required this.away, required this.gold, required this.run, this.wide = false});

  final Color home, away, gold;
  final double run;

  /// Landscape: the diagonal runs from the top to the bottom, the home side at the reading start.
  final bool wide;

  @override
  void paint(Canvas canvas, Size s) {
    final ink = glmNight.bgDeep;
    if (wide) {
      // Home on the right (Arabic reads from it), away on the left: the gold line from the top at 58% to the foot at 42%.
      final x1 = s.width * .58, x2 = s.width * .42;
      final right = Path()..addPolygon([Offset(x1, 0), Offset(s.width, 0), Offset(s.width, s.height), Offset(x2, s.height)], true);
      final left = Path()..addPolygon([Offset.zero, Offset(x1, 0), Offset(x2, s.height), Offset(0, s.height)], true);
      canvas.drawPath(right, Paint()..color = Color.lerp(ink, home, .32)!);
      canvas.drawPath(left, Paint()..color = Color.lerp(ink, away, .32)!);
      for (final (c, at) in [(home, Offset(s.width * .82, s.height * .3)), (away, Offset(s.width * .18, s.height * .7))]) {
        canvas.drawCircle(at, s.height * 1.1, Paint()..shader = RadialGradient(colors: [c.withValues(alpha: .42), c.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: at, radius: s.height * 1.1)));
      }
      final lines = Paint()
        ..color = Colors.white.withValues(alpha: .06)
        ..strokeWidth = 10;
      final dy = run * 90;
      for (final x in [.12, .26, .74, .88]) {
        canvas.drawLine(Offset(s.width * x + 40, -90 + dy), Offset(s.width * x - 40, s.height + dy), lines);
      }
      canvas.drawLine(Offset(x1, 0), Offset(x2, s.height), Paint()
        ..color = gold
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6));
      return;
    }
    final a = s.height * .30, b = s.height * .56;
    final top = Path()..addPolygon([Offset.zero, Offset(s.width, 0), Offset(s.width, b), Offset(0, a)], true);
    final bottom = Path()..addPolygon([Offset(0, a), Offset(s.width, b), Offset(s.width, s.height), Offset(0, s.height)], true);
    canvas.drawPath(top, Paint()..color = Color.lerp(ink, home, .32)!);
    canvas.drawPath(bottom, Paint()..color = Color.lerp(ink, away, .32)!);
    canvas.drawCircle(Offset(s.width * .8, s.height * .18), s.width * .7, Paint()..shader = RadialGradient(colors: [home.withValues(alpha: .4), home.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(s.width * .8, s.height * .18), radius: s.width * .7)));
    canvas.drawCircle(Offset(s.width * .2, s.height * .7), s.width * .7, Paint()..shader = RadialGradient(colors: [away.withValues(alpha: .45), away.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(s.width * .2, s.height * .7), radius: s.width * .7)));
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 10;
    final dx = -run * 120;
    for (final y in [.14, .24, .66, .76]) {
      canvas.drawLine(Offset(dx - 120, s.height * y), Offset(s.width + 120 + dx, s.height * y + (b - a)), lines);
    }
    canvas.drawLine(Offset(0, a), Offset(s.width, b), Paint()
      ..color = gold
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6));
  }

  @override
  bool shouldRepaint(_Split old) => old.run != run || old.home != home || old.away != away || old.wide != wide;
}

/// Sparks rising, each on its own path.
class _Sparks extends CustomPainter {
  _Sparks({required this.t, required this.colors});

  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * s.width, y0 = s.height * (.35 + rnd.nextDouble() * .5), off = rnd.nextDouble();
      final k = (t + off) % 1;
      canvas.drawCircle(Offset(x + math.sin(k * 6 + i) * 8, y0 - k * 240), 3 * (1 - k * .7), Paint()..color = colors[i % colors.length].withValues(alpha: (1 - k) * (k < .15 ? k / .15 : 1)));
    }
  }

  @override
  bool shouldRepaint(_Sparks old) => old.t != t;
}
