// ChangeNotifier: البيانات، والقواعد، وطريقة لإخبار المستمعين بأنها تغيّرت.
import 'package:material_ui/material_ui.dart';

class Basket extends ChangeNotifier {
  final Map<String, int> _counts = {};
  final Map<String, int> _prices = {};

  // نوافذ للقراءة فقط: يستطيع الخارج أن ينظر، لا أن يلمس.
  Map<String, int> get counts => Map.unmodifiable(_counts);
  int get count => _counts.values.fold(0, (a, b) => a + b);
  int get total =>
      _counts.entries.fold(0, (sum, e) => sum + e.value * _prices[e.key]!);

  void add(String name, int price) {
    _counts.update(name, (n) => n + 1, ifAbsent: () => 1);
    _prices[name] = price;
    // كل تغيير ينتهي بـ notifyListeners().
    notifyListeners();
  }

  void remove(String name) {
    final n = _counts[name];
    if (n == null) return;
    if (n == 1) {
      _counts.remove(name);
    } else {
      _counts[name] = n - 1;
    }
    notifyListeners();
  }
}
