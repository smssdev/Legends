import 'package:material_ui/material_ui.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: ChatPage(),
    ),
  );
}

const messages = [
  (mine: true, text: 'Is my latte ready?'),
  (mine: false, text: 'Two minutes!'),
  (mine: true, text: 'Thank you'),
  (mine: false, text: 'You are welcome'),
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
    // End for my messages, start for theirs: correct in both directions.
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
          // The small corner points to the person who wrote it.
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
      appBar: AppBar(leading: const BackButton(), title: const Text('Bit')),
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
              child: TextField(
                decoration: InputDecoration(hintText: 'Message'),
              ),
            ),
            IconButton(
              tooltip: 'Send',
              onPressed: () {},
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
