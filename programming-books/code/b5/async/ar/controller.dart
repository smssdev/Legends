import 'dart:async';

Future<void> main() async {
  // StreamController: المقهى يقرر متى يرسل كل قيمة.
  // broadcast: يمكن لأكثر من مستمع أن يستمع.
  var orders = StreamController<String>.broadcast();

  orders.stream.listen((o) => print('الشاشة: $o'));
  orders.stream
      .where((o) => o.contains('كيك'))
      .listen((o) => print('المطبخ: $o'));

  orders.add('طاولة 1: لاتيه');
  orders.add('طاولة 2: كيك');
  orders.add('طاولة 3: شاي، كيك');
  await orders.close();
  print('أُغلق');
}
