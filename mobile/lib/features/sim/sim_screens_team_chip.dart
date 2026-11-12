part of 'sim_screens.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: on ? p.gold : p.surfaceRaised, width: 2),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: SizedBox(
          width: 86,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubCrest(url: club.logo, name: club.code, size: 36, color: club.color),
                const SizedBox(height: 4),
                Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                if (club.strength != null)
                  Text(
                    '${club.strength}',
                    style: TextStyle(
                      fontFamily: GlmFonts.numbers,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: on ? context.glm.goldText : p.textMuted,
                    ),
                  ),
              ],
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.surfaceRaised),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (club == null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.gold, width: 2),
                  ),
                  child: Icon(Icons.shuffle_rounded, color: p.gold, size: 20),
                )
              else
                ClubCrest(url: club!.logo, name: club!.code, size: 36, color: club!.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  club?.name ?? l.simRandom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: club == null ? null : TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              if (club?.strength != null) Text(l.simStrength(club!.strength!), style: TextStyle(color: p.textMuted, fontSize: 13)),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
            ],
          ),
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
        child: Column(
          children: [
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
                error: (e, _) => Center(
                  child: Text(e is ApiError && e.status == 404 ? l.simOff : '$e', style: TextStyle(color: p.textMuted)),
                ),
                data: (clubs) => ListView(
                  children: [
                    for (final c in clubs)
                      ListTile(
                        leading: ClubCrest(url: c.logo, name: c.code, size: 36, color: c.color),
                        title: Text(c.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                        subtitle: c.league == null
                            ? null
                            : Text(
                                c.league!,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.start,
                                style: TextStyle(color: p.textMuted, fontSize: 12),
                              ),
                        trailing: c.strength == null
                            ? null
                            : Text(
                                '${c.strength}',
                                style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                        onTap: () => Navigator.pop(context, c),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 76, child: Center(child: crest)),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .8), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          );
          final away = widget.friend
              ? Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.gold, width: 3),
                  ),
                  child: Text(
                    '?',
                    style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 30, fontWeight: FontWeight.w700, color: p.gold),
                  ),
                )
              : widget.away != null
              ? ClubCrest(url: widget.away!.logo, name: widget.away!.code, size: 66, color: widget.away!.color)
              : Icon(Icons.smart_toy_rounded, size: 62, color: p.ring);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.bgDeep),
              CustomPaint(painter: _NightPitch(sway: w)),
              Row(
                children: [
                  Expanded(
                    child: side(
                      widget.home == null
                          ? const SizedBox(width: 66)
                          : ClubCrest(url: widget.home!.logo, name: widget.home!.code, size: 66, color: widget.home!.color),
                      widget.home?.name ?? '',
                      true,
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + .1 * w,
                    child: Transform.rotate(
                      angle: .07 * w,
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: GlmFonts.numbers,
                          fontWeight: FontWeight.w700,
                          fontSize: 40,
                          color: p.gold,
                          shadows: [
                            Shadow(color: p.goldDark, offset: const Offset(0, 2)),
                            Shadow(color: p.gold.withValues(alpha: .55), blurRadius: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: side(away, widget.friend ? l.simWaitingFriend : widget.away?.name ?? l.simComputer, false)),
                ],
              ),
              Positioned(
                bottom: 12 + bounce * 26,
                left: 0,
                right: 0,
                child: Center(
                  child: CustomPaint(size: const Size.square(18), painter: BallPainter()),
                ),
              ),
            ],
          );
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
      final beam = Path()
        ..addPolygon([const Offset(-7, 0), const Offset(7, 0), Offset(70, s.height * 1.3), Offset(-70, s.height * 1.3)], true);
      canvas.drawPath(
        beam,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x47FFF0C8), Color(0x00FFF0C8)],
          ).createShader(Rect.fromLTWH(-70, 0, 140, s.height)),
      );
      canvas.restore();
    }
    final top = s.height * .54, k = s.width / 390;
    final field = Path()..addPolygon([Offset(80 * k, top), Offset(310 * k, top), Offset(s.width, s.height), Offset(0, s.height)], true);
    canvas.drawPath(field, Paint()..color = p.pitchDark);
    canvas.drawPath(
      Path()..addPolygon([Offset(118 * k, top), Offset(157 * k, top), Offset(140 * k, s.height), Offset(78 * k, s.height)], true),
      Paint()..color = p.pitch,
    );
    canvas.drawPath(
      Path()..addPolygon([Offset(195 * k, top), Offset(234 * k, top), Offset(250 * k, s.height), Offset(195 * k, s.height)], true),
      Paint()..color = p.pitch,
    );
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
