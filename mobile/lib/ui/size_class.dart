import 'package:flutter/widgets.dart';

/// [Sprint 72 R2] The one place a screen asks how much room it has. The game is landscape only, so the height is the
/// tight side: Android's commonest phones are 360 high (the reference shots were 390 only, and screens broke on 360).
/// A screen never compares a width or a height with a number of its own (tool/design.dart refuses it): it asks here.
enum GlmWidth {
  /// Under 560: one column (a narrow pane, a small window).
  narrow,

  /// 560 to under 840: two columns.
  regular,

  /// 840 and over: room for a third.
  wide,
}

enum GlmHeight {
  /// Under 340: the dock's icons without their names.
  tiny,

  /// Under 400: a phone held sideways (360 mostly). The dense layout.
  short,

  /// 400 and over: a large phone, a tablet.
  tall,
}

abstract final class GlmFit {
  static const narrowUnder = 560.0;
  static const wideFrom = 840.0;

  /// A pane with room to spare (a second column of cards, a list beside its detail): 700 and over.
  static const roomyFrom = 700.0;

  /// A pane too low for a hero and what follows it: under 300.
  static const crampedUnder = 300.0;

  /// A row with room for its extras (a bar beside its figure): 200 and over.
  static const rowExtrasFrom = 200.0;
  static const tinyUnder = 340.0;
  static const shortUnder = 400.0;

  /// The width class of a pane [w] wide (a LayoutBuilder's maxWidth).
  static GlmWidth width(double w) => w < narrowUnder ? GlmWidth.narrow : (w < wideFrom ? GlmWidth.regular : GlmWidth.wide);

  /// The height class of a pane [h] high.
  static GlmHeight height(double h) => h < tinyUnder ? GlmHeight.tiny : (h < shortUnder ? GlmHeight.short : GlmHeight.tall);

  static bool isNarrow(double w) => width(w) == GlmWidth.narrow;
  static bool isRoomy(double w) => w >= roomyFrom;
  static bool isCramped(double h) => h < crampedUnder;
  static bool hasRowExtras(double w) => w >= rowExtrasFrom;
  static bool isWide(double w) => width(w) == GlmWidth.wide;

  /// The whole screen's classes.
  static GlmWidth widthOf(BuildContext context) => width(MediaQuery.sizeOf(context).width);
  static GlmHeight heightOf(BuildContext context) => height(MediaQuery.sizeOf(context).height);

  /// A phone held sideways (not a large phone or a tablet): the dense layout.
  static bool shortOf(BuildContext context) => heightOf(context) != GlmHeight.tall;

  /// [Sprint 72 R7] A tablet (its shorter side 600 or more): the whole game drawn larger, by this much.
  static double scaleOf(Size screen) {
    final short = screen.shortestSide;
    return short >= 840 ? 1.5 : (short >= 600 ? 1.3 : 1);
  }
}

/// [Sprint 72 R7] The whole game drawn larger on a tablet (a phone's layout stretched over 1280×800 left half the
/// screen empty and the text phone sized): the screens are laid out on a smaller canvas (the screen ÷ the scale) and
/// shown filling it, touches included. On a phone it is the child itself.
class GlmScale extends StatelessWidget {
  const GlmScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final k = GlmFit.scaleOf(mq.size);
    if (k == 1) return child;
    final size = mq.size / k;
    return MediaQuery(
      data: mq.copyWith(
        size: size,
        devicePixelRatio: mq.devicePixelRatio * k,
        padding: mq.padding / k,
        viewPadding: mq.viewPadding / k,
        viewInsets: mq.viewInsets / k,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    );
  }
}
