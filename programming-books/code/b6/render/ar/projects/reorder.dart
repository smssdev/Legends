import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

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
      subtitle: done ? const Text('تم') : null,
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
  final tasks = ['اكتب الاختبارات', 'أصلح الخطأ', 'انشره'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المهام')),
      body: ReorderableListView(
        onReorderItem: (from, to) =>
            setState(() => tasks.insert(to, tasks.removeAt(from))),
        children: [
          // ValueKey(task): الـ State تتبع المهمة حين تتحرك.
          for (final task in tasks) TaskTile(key: ValueKey(task), task: task),
        ],
      ),
    );
  }
}
