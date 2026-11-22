import 'package:material_ui/material_ui.dart';

import 'observe/crashes.dart';

class PrintSink implements ReportSink {
  @override
  Future<void> send(Map<String, Object?> report) async =>
      debugPrint('report: $report');
}

void main() {
  final crashes = Crashes(PrintSink(), appVersion: '1.4.0+42', platform: 'web')
    ..install();
  // في نسخ الإصدار يعرض الـ Widget المعطل هذا بدل مربع رمادي.
  ErrorWidget.builder = (details) => const FriendlyError();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: MenuPage(crashes: crashes),
    ),
  );
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.crashes});

  final Crashes crashes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            crashes.breadcrumbs.add('open specials');
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SpecialsPage()),
            );
          },
          child: const Text('افتح العروض'),
        ),
      ),
    );
  }
}

class SpecialsPage extends StatelessWidget {
  const SpecialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final specials = <String>[];
    return Scaffold(appBar: AppBar(), body: Text(specials.first));
  }
}

class FriendlyError extends StatelessWidget {
  const FriendlyError({super.key});

  @override
  Widget build(BuildContext context) {
    // إنه يحل محل الصفحة المعطلة كلها، فيحضر Material خاصاً به لأنماط النص.
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.sentiment_dissatisfied, size: 64),
              Text(
                'حدث خطأ في هذه الشاشة.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const Text(
                'وصلنا البلاغ، ويمكنك الرجوع.',
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
