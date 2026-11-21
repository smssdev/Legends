void main() {
  print('one');
  Future.delayed(Duration(milliseconds: 100), () => print('three'));
  print('two');
}
