import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemeApp());
}

class ThemeApp extends StatelessWidget {
  const ThemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      // الألوان وأحجام النص تأتي من السمة، لا من كل Widget.
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقهى بِت'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أهلاً بعودتك', style: theme.textTheme.headlineMedium),
            Text(
              'لديك 120 نقطة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () {}, child: const Text('اطلب الآن')),
          ],
        ),
      ),
    );
  }
}
