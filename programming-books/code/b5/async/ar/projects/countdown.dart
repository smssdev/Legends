// قيمة كل ثانية، من الرقم المعطى نزولاً إلى 1.
Stream<int> countdown(int from) async* {
  for (var i = from; i >= 1; i--) {
    yield i;
    await Future.delayed(Duration(milliseconds: 1000));
  }
}

Future<void> main() async {
  await for (var n in countdown(5)) {
    print(n);
  }
  print('انطلق!');
}
