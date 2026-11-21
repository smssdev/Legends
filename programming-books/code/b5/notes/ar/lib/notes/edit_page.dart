import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'model.dart';
import 'note.dart';

// الصفحة نفسها تضيف وتعدّل: مع ملاحظة، تعدّلها.
Future<void> openEditor(BuildContext context, [Note? note]) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (context) => EditPage(note: note)));

class EditPage extends StatefulWidget {
  const EditPage({super.key, this.note});

  final Note? note;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.note?.title);
  late final body = TextEditingController(text: widget.note?.body);

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    final model = context.read<NotesModel>();
    final note = widget.note;
    if (note == null) {
      await model.add(title.text.trim(), body.text.trim());
    } else {
      await model.update(
        note,
        title: title.text.trim(),
        body: body.text.trim(),
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? l.newNote : l.editNote),
        actions: [TextButton(onPressed: save, child: Text(l.save))],
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: title,
              autofocus: widget.note == null,
              decoration: InputDecoration(labelText: l.title),
              textInputAction: TextInputAction.next,
              // النموذج يرفض ملاحظة بلا عنوان.
              validator: (v) => (v ?? '').trim().isEmpty ? l.titleNeeded : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: body,
              decoration: InputDecoration(
                labelText: l.body,
                alignLabelWithHint: true,
              ),
              minLines: 6,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
