import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const TasksPage(),
    ),
  );
}

class TaskTile extends StatefulWidget {
  const TaskTile({super.key, required this.task});

  final String task;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  var done = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.task),
      subtitle: done ? const Text('done') : null,
      value: done,
      onChanged: (v) => setState(() => done = v ?? false),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final tasks = ['Write tests', 'Fix the bug', 'Ship it'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: ReorderableListView(
        onReorderItem: (from, to) =>
            setState(() => tasks.insert(to, tasks.removeAt(from))),
        children: [
          // ValueKey(task): the State follows the task when it moves.
          for (final task in tasks) TaskTile(key: ValueKey(task), task: task),
        ],
      ),
    );
  }
}
