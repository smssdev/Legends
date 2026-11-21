// Our own error, with a message for people.
class OutOfMilk implements Exception {
  final String drink;
  OutOfMilk(this.drink);

  @override
  String toString() => 'No milk left ($drink)';
}

Future<String> brew(String drink) async {
  await Future.delayed(Duration(milliseconds: 100));
  if (drink == 'Latte') throw OutOfMilk(drink);
  return '$drink ready';
}

Future<void> serve(String drink) async {
  // An error in a future arrives at the await, so try catches it.
  try {
    var cup = await brew(drink);
    print(cup);
  } on OutOfMilk catch (e) {
    print('Sorry: $e');
  } finally {
    // finally runs either way: clean the machine.
    print('  machine cleaned');
  }
}

Future<void> main() async {
  await serve('Tea');
  await serve('Latte');
}
