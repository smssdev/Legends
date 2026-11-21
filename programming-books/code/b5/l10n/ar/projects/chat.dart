import 'package:material_ui/material_ui.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ar'),
      home: ChatPage(),
    ),
  );
}

const messages = [
  (mine: true, text: 'هل اللاتيه جاهز؟'),
  (mine: false, text: 'دقيقتان!'),
  (mine: true, text: 'شكراً'),
  (mine: false, text: 'على الرحب والسعة'),
];

class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const round = Radius.circular(18);
    const tail = Radius.circular(4);
    // النهاية لرسائلي، والبداية لرسائلهم: صحيح في الاتجاهين.
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: EdgeInsetsDirectional.only(
          start: mine ? 64 : 12,
          end: mine ? 12 : 64,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surfaceContainerHighest,
          // الزاوية الصغيرة تشير إلى من كتب الرسالة.
          borderRadius: BorderRadiusDirectional.only(
            topStart: round,
            topEnd: round,
            bottomStart: mine ? round : tail,
            bottomEnd: mine ? tail : round,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: mine ? colors.onPrimary : colors.onSurface),
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('بِت')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final m in messages) Bubble(text: m.text, mine: m.mine),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 24),
        child: Row(
          children: [
            const Expanded(
              child: TextField(decoration: InputDecoration(hintText: 'رسالة')),
            ),
            IconButton(
              tooltip: 'أرسل',
              onPressed: () {},
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
