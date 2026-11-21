Future<void> main() async {
  print('A');
  Future(() => print('B'));
  Future.delayed(Duration(milliseconds: 50), () => print('C'));
  print('D');
  await Future.delayed(Duration(milliseconds: 100));
  print('E');
}
