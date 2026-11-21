import 'dart:async';

Future<void> main() async {
  // A StreamController: the café decides when to send each value.
  // broadcast: more than one listener may listen.
  var orders = StreamController<String>.broadcast();

  orders.stream.listen((o) => print('screen: $o'));
  orders.stream
      .where((o) => o.contains('Cake'))
      .listen((o) => print('kitchen: $o'));

  orders.add('table 1: Latte');
  orders.add('table 2: Cake');
  orders.add('table 3: Tea, Cake');
  await orders.close();
  print('closed');
}
