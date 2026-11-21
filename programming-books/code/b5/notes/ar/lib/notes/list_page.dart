import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'edit_page.dart';
import 'model.dart';
import 'note.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final model = context.watch<NotesModel>();
    final notes = model.visible;
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: l.search,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: context.read<NotesModel>().search,
            ),
          ),
          Expanded(
            child: switch (model) {
              // أول إطار: ما زالت الملاحظات تُقرأ.
              NotesModel(loading: true) => const Center(
                child: CircularProgressIndicator(),
              ),
              NotesModel(all: []) => _Message(
                icon: Icons.note_alt_outlined,
                text: l.empty,
              ),
              _ when notes.isEmpty => _Message(
                icon: Icons.search_off,
                text: l.noMatch,
              ),
              _ => ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: notes.length,
                itemBuilder: (context, i) => _NoteTile(note: notes[i]),
              ),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEditor(context),
        icon: const Icon(Icons.edit),
        label: Text(l.newNote),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final Note note;

  Future<void> delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final model = context.read<NotesModel>();
    final messenger = ScaffoldMessenger.of(context);
    final index = await model.remove(note);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.deleted),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () => model.restore(note, index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // اسحب للحذف؛ و«تراجع» تعيدها.
    return Dismissible(
      key: ValueKey(note.id),
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        child: const Icon(Icons.delete),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => delete(context),
      child: ListTile(
        title: Text(note.title),
        subtitle: Text(
          note.body.isEmpty
              ? l.edited(note.edited)
              : '${l.edited(note.edited)} · ${note.body}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: note.pinned ? l.unpin(note.title) : l.pin(note.title),
          icon: note.pinned
              ? Icon(
                  Icons.push_pin,
                  color: Theme.of(context).colorScheme.primary,
                )
              : const Icon(Icons.push_pin_outlined),
          onPressed: () => context.read<NotesModel>().togglePin(note),
        ),
        onTap: () => openEditor(context, note),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(icon, size: 64),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
