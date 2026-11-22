import 'package:material_ui/material_ui.dart';

const drinks = [
  ('لاتيه', 'إسبريسو وحليب مبخّر', 45),
  ('شاي بالنعناع', 'نعناع طازج، محلّى قليلاً', 30),
  ('كيك الكرز', 'مخبوز هذا الصباح', 55),
];

// النص بالحجم الذي اختاره الشخص؛ واللقطات تستخدم 2 لتُظهر النص الكبير.
Widget cafe(Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  // العربية لغة التطبيق: فيصير التخطيط وترتيب القراءة كلاهما من اليمين (القسم 11.4).
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: ThemeData(colorSchemeSeed: Colors.brown),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);
