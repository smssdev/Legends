void main() {
  // Dart works out the type from the first value: score is an int, for ever.
  var score = 0;
  score = score + 10;
  print(score);

  // Or write the type yourself.
  String name = 'Sara';
  print(name);

  // final: set once, when the program runs.
  final joined = DateTime.now().year;
  print(joined > 2000);

  // const: known before the program runs, and never changes.
  const maxPlayers = 4;
  print(maxPlayers);
}
