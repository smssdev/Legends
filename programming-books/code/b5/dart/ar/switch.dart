void main() {
  var size = 'M';

  // لا حاجة إلى break: لا تنتقل Dart أبداً إلى الحالة التالية.
  switch (size) {
    case 'S':
      print('كوب صغير');
    case 'M':
      print('كوب وسط');
    case 'L':
      print('كوب كبير');
    default:
      print('حجم غير معروف');
  }

  // تعبير switch ينتج قيمة. وأول نمط يطابق هو الذي يفوز.
  var day = 'الجمعة';
  var kind = switch (day) {
    'الجمعة' || 'السبت' => 'عطلة',
    _ => 'يوم عمل',
  };
  print(kind);

  for (var score in [95, 83, 71, 40]) {
    var grade = switch (score) {
      // >= 90 نمط: يطابق أي قيمة لا تقل عن 90.
      >= 90 => 'A',
      >= 80 => 'B',
      >= 70 => 'C',
      >= 50 => 'D',
      // _ يطابق أي شيء: الحالة لكل ما عدا ذلك.
      _ => 'F',
    };
    print('$score -> $grade');
  }
}
