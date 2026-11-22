import 'models.dart';

// التطبيق يعتمد على هذه؛ ويقدّم كلٌّ من العرض والاختبارات والخادم الحقيقي واحدة.
abstract interface class CafeApi {
  Future<List<Drink>> menu();
  Future<Order> place(Map<String, int> lines);
  Future<Order> order(String id);
}

class DemoApi implements CafeApi {
  final _placed = <String, DateTime>{};

  @override
  Future<List<Drink>> menu() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      Drink('latte', 'لاتيه', 'إسبريسو وحليب مبخّر', 45),
      Drink('tea', 'شاي بالنعناع', 'نعناع طازج، محلّى قليلاً', 30),
      Drink('cake', 'كيك الكرز', 'مخبوز هذا الصباح', 55),
      Drink('juice', 'عصير برتقال', 'يُعصر عند الطلب', 40),
    ];
  }

  @override
  Future<Order> place(Map<String, int> lines) async {
    final id = '${41 + _placed.length}';
    _placed[id] = DateTime.now();
    return Order(id, OrderStatus.received);
  }

  @override
  Future<Order> order(String id) async {
    final seconds = DateTime.now()
        .difference(_placed[id] ?? DateTime.now())
        .inSeconds;
    return Order(id, seconds < 2 ? OrderStatus.preparing : OrderStatus.ready);
  }
}
