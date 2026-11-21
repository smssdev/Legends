import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: CounterPage(counter: Counter()),
    ),
  );
}

class Counter extends ChangeNotifier {
  int _value = 0;
  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }

  void reset() {
    _value = 0;
    notifyListeners();
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key, required this.counter});

  final Counter counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أكواب اليوم'),
        actions: [
          IconButton(
            tooltip: 'صفّر',
            onPressed: counter.reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: counter,
          builder: (context, child) => Text(
            '${counter.value}',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: counter.increment,
        icon: const Icon(Icons.local_cafe),
        label: const Text('كوب آخر'),
      ),
    );
  }
}
