void main() {
  // Map: كل مفتاح (اسم) يقود إلى قيمة واحدة (كمية).
  var stock = <String, int>{'سكر': 40, 'حليب': 12, 'أكواب': 200};
  print(stock['حليب']);
  print(stock['بُن']);

  // البحث بمفتاح يعطي int?: فقد لا يكون المفتاح موجوداً.
  int beans = stock['بُن'] ?? 0;
  print(beans);

  stock['بُن'] = 5;
  // update تغيّر قيمة؛ وifAbsent تقول ماذا تفعل حين يغيب المفتاح.
  stock.update('حليب', (n) => n - 2);
  stock.update('مياه', (n) => n + 6, ifAbsent: () => 6);
  print(stock.length);
  print(stock.containsKey('سكر'));

  for (var entry in stock.entries) {
    print('${entry.key}: ${entry.value}');
  }
  stock.remove('أكواب');
  print(stock.keys.toList());
}
