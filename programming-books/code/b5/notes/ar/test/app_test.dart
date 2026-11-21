import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/notes/model.dart';
import 'package:bit_app/notes/store.dart';
import 'package:bit_app/notes_app.dart';

void main() {
  testWidgets('ملاحظة تُكتب، وتُسحب، وتعود', (tester) async {
    final model = NotesModel(MemoryNotesStore())..load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: model, child: const NotesApp()),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No notes yet. Tap New note to write one.'),
      findsOneWidget,
    );

    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('A note needs a title'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Shopping',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);

    await tester.drag(find.text('Shopping'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);
  });
}
