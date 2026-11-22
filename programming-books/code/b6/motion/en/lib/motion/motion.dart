import 'package:material_ui/material_ui.dart';

// Motion tokens: three durations and three curves, like the spacing scale of Chapter 7.
abstract final class Motion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);

  // Things that arrive slow down at the end; things that leave speed up.
  static const enter = Easing.emphasizedDecelerate;
  static const exit = Easing.emphasizedAccelerate;
  static const move = Easing.standard;
}

// People who turn on reduced motion get the result at once.
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
