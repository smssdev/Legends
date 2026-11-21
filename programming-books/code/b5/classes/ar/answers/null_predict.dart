void main() {
  String? a;
  String? b = 'Dart';
  print(a ?? b);
  print(b?.length);
  print(a?.length ?? -1);
  a ??= 'Flutter';
  a ??= 'Kotlin';
  print(a);
}
