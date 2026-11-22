import 'package:material_ui/material_ui.dart';

// رموز الحركة: ثلاث مدد وثلاثة منحنيات، مثل مقياس المسافات في الفصل 7.
abstract final class Motion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);

  // ما يصل يبطئ في النهاية؛ وما يغادر يسرع.
  static const enter = Easing.emphasizedDecelerate;
  static const exit = Easing.emphasizedAccelerate;
  static const move = Easing.standard;
}

// من يفعّل «تقليل الحركة» يحصل على النتيجة فوراً.
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
