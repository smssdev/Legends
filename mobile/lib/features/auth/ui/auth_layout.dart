import 'package:flutter/material.dart';

import '../../../ui/widgets/console.dart';

import 'package:go_router/go_router.dart';

import '../../../core/sounds.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/tokens.g.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/legend_crest.dart';
import '../../../ui/widgets/motion.dart';

/// Which of the two sign-in pages is open, for the ivory tabs at the top of the form (none on the other pages).
enum AuthTab { signIn, register }

/// [Sprint 15 F3, Sprint 47] The sign-in screens' frame in the approved design: a pitch at night across the top with
/// the crest, the game's name and the page's greeting at its foot; then the two ivory tabs (sign in, a new account)
/// and the form. Landscape: the pitch on one side, the form on the other. Scrolls above the keyboard.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.lead, required this.children, this.footer, this.tab});

  final String title;
  final String lead;
  final List<Widget> children;
  final Widget? footer;
  final AuthTab? tab;

  @override
  Widget build(BuildContext context) {
    final form = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tab != null) ...[_Tabs(tab: tab!), const SizedBox(height: 18)],
          ...children,
          if (footer != null) ...[const SizedBox(height: 18), Center(child: footer!)],
        ],
      ),
    );
    // Asked above the Scaffold: under it the keyboard's height is already taken out of the body.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: GlmBackground(
        wide: true,
        child: LayoutBuilder(
          builder: (context, box) {
            // [Sprint 72 R5] The keyboard up (in landscape it leaves under half the height): the form alone, across the
            // whole width and scrolling, so the field being typed in and the button under it stay in sight. The pitch
            // and its greeting come back when it goes.
            if (keyboard && box.maxWidth > box.maxHeight) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                  child: Center(
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: form),
                  ),
                ),
              );
            }
            if (box.maxWidth > box.maxHeight) {
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _PitchHead(title: title, lead: lead, tall: true),
                  ),
                  Expanded(
                    flex: 5,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: FadeSlideIn(index: 2, child: form),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 280 + MediaQuery.paddingOf(context).top,
                    child: _PitchHead(title: title, lead: lead),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                        child: FadeSlideIn(index: 1, child: form),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The pitch at night: mown stripes and white lines fading into the ink, the crest and the name at its top, the
/// page's greeting at its foot.
class _PitchHead extends StatelessWidget {
  const _PitchHead({required this.title, required this.lead, this.tall = false});

  final String title, lead;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final p = glmNight;
    return CustomPaint(
      // [Sprint 73 D9] Wide: no penalty box drawn through the crest and the game's name.
      painter: _Pitch(fade: context.palette.bg, box: !tall),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Column(
            crossAxisAlignment: tall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisAlignment: tall ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: tall ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  LegendCrest(size: tall ? 64 : 40, letters: tall),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'GAME LEGEND MANAGER',
                        textDirection: TextDirection.ltr,
                        style: glmText(
                          tall ? GlmType.headline : GlmType.title,
                          fontFamily: GlmFonts.numbers,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: p.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // [Sprint 50 M4] The cinematic stage: our trophy in 3D turning under the floodlights (wide only).
              if (tall)
                SizedBox(
                  height: 150,
                  width: 150,
                  child: GlmModelSpin(
                    model: 'trophy',
                    label: 'GLM',
                    fallback: Icon(Icons.emoji_events_rounded, size: 110, color: p.gold),
                  ),
                )
              else
                const Spacer(),
              Text(
                title,
                textAlign: tall ? TextAlign.center : TextAlign.start,
                style: glmText(GlmType.display, fontWeight: FontWeight.w800, height: 1.25, color: p.text),
              ),
              const SizedBox(height: 4),
              Text(
                lead,
                textAlign: tall ? TextAlign.center : TextAlign.start,
                style: glmText(GlmType.body, color: p.textSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pitch extends CustomPainter {
  _Pitch({required this.fade, this.box = true});

  final Color fade;
  final bool box;

  @override
  void paint(Canvas canvas, Size s) {
    final p = glmNight;
    canvas.clipRect(Offset.zero & s);
    canvas.drawRect(Offset.zero & s, Paint()..color = p.pitchDark);
    final stripe = Paint()..color = p.pitch;
    final w = s.width / 6;
    for (var i = 0; i < 6; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * w, 0, w, s.height), stripe);
    }
    final line = Paint()
      ..color = p.text.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final c = Offset(s.width / 2, s.height * .86);
    if (box) canvas.drawRect(Rect.fromLTRB(-10, s.height * .11, s.width + 10, s.height + 40), line);
    canvas.drawLine(Offset(-10, c.dy), Offset(s.width + 10, c.dy), line);
    canvas.drawCircle(c, 58, line);
    if (box) canvas.drawRect(Rect.fromCenter(center: Offset(s.width / 2, s.height * .11 + 31), width: 160, height: 62), line);
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fade.withValues(alpha: .15), fade],
          stops: const [.2, 1],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_Pitch old) => old.fade != fade || old.box != box;
}

/// The two ivory tabs: sign in, a new account.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab});

  final AuthTab tab;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    Widget one(AuthTab t, String label, String path) {
      final on = t == tab;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: Material(
            // [Sprint 50] The site's tabs (UiTabs): the chosen one gold.
            color: on ? p.gold : Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              onTap: on
                  ? null
                  : () {
                      GameSounds.play(Sfx.tap);
                      context.go(path);
                    },
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    label,
                    style: glmText(GlmType.body, fontWeight: FontWeight.w700, color: on ? p.onGold : p.textSoft),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.glm.day ? p.surfaceSunk : p.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: p.surfaceRaised),
      ),
      child: Row(
        children: [one(AuthTab.signIn, l.signIn, '/login'), const SizedBox(width: 4), one(AuthTab.register, l.createAccount, '/register')],
      ),
    );
  }
}
