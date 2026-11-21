Future<String> fetchName() async => 'Bit';

Future<void> main() async {
  var name = fetchName();
  print(name);
  print(await fetchName());
}
