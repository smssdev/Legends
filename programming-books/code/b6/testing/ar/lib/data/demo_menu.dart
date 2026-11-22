import 'menu.dart';

// لتطبيق العرض: الزيارة الأولى تفشل والثانية تنجح، كما على اتصال سيئ.
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
      Drink('latte', 'لاتيه', 45),
      Drink('tea', 'شاي بالنعناع', 30),
      Drink('cake', 'كيك الكرز', 55),
    ];
  }
}
