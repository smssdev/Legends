Future<int> price(String item) async => item.length * 10;

Future<int> withService(int p) async => p + p ~/ 10;

void withThen() {
  price('latte').then(withService).then((total) => print('then: $total'));
}

Future<void> withAwait() async {
  var p = await price('latte');
  var total = await withService(p);
  print('await: $total');
}

Future<void> main() async {
  withThen();
  await withAwait();
}
