import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const KeyboardsPage(),
    ),
  );
}

class KeyboardsPage extends StatefulWidget {
  const KeyboardsPage({super.key});

  @override
  State<KeyboardsPage> createState() => _KeyboardsPageState();
}

class _KeyboardsPageState extends State<KeyboardsPage> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          // keyboardType تختار لوحة المفاتيح: أرقام للهاتف، و@ للبريد.
          // textInputAction: المفتاح في زاوية اللوحة يقول «التالي» ثم «تم».
          const TextField(
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'الهاتف',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          // obscureText تخفي ما يُكتب؛ وزر العين يُظهره.
          TextField(
            obscureText: hidden,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                tooltip: hidden ? 'أظهر كلمة المرور' : 'أخفِ كلمة المرور',
                icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => hidden = !hidden),
              ),
            ),
          ),
          // maxLength: حد أقصى، مع عدّاد تحت المربع.
          const TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 2,
            decoration: InputDecoration(
              labelText: 'الأكواب',
              prefixIcon: Icon(Icons.local_cafe),
            ),
          ),
        ],
      ),
    );
  }
}
