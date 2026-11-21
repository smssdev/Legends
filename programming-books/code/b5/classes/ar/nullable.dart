void main() {
  // String? قد يحمل نصاً، أو null: لا شيء على الإطلاق.
  String? nickname;
  print(nickname);

  // ?? تعطي القيمة التي على يمينها حين يكون ما على يسارها null.
  print(nickname ?? 'زائر');

  // ?. تسأل فقط حين يوجد ما يُسأل: والـ null يبقى null.
  print(nickname?.length);

  // ??= تضع قيمة فقط إن لم تكن هناك قيمة بعد.
  nickname ??= 'بيتو';
  print(nickname);

  String? other;
  // داخل هذا الـ if تعرف Dart أن nickname ليس null.
  if (other != null) {
    print(other.length);
  } else {
    print('لا لقب');
  }
}
