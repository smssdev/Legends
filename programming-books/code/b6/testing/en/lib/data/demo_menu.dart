import 'menu.dart';

// For the demo app: the first visit fails, the second works, as on a bad connection.
class DemoMenu implements MenuRepository {
  var calls = 0;

  @override
  Future<List<Drink>> menu() async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (calls == 1) {
      throw const MenuException('timeout');
    }
    return const [
      Drink('latte', 'Latte', 45),
      Drink('tea', 'Mint tea', 30),
      Drink('cake', 'Cherry cake', 55),
    ];
  }
}
