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
  // In release builds, a broken widget shows this instead of a grey box.
  ErrorWidget.builder = (details) => const FriendlyError();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

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
      appBar: AppBar(title: const Text('Menu')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            crashes.breadcrumbs.add('open specials');
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SpecialsPage()),
            );
          },
          child: const Text('Open the specials'),
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
    // It replaces the whole broken page, so it brings its own Material for text styles.
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
                'Something went wrong on this screen.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const Text(
                'We have been told, and you can go back.',
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
