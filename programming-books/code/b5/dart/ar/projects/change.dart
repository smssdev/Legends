const notes = [200, 100, 50, 20, 10, 5, 1];

String change({required int price, required int paid}) {
  // دفع أقل من السعر؟ قل ذلك، وتوقف.
  if (paid < price)
    return 'المبلغ لا يكفي: ينقص {0}.'.replaceFirst('{0}', '${price - paid}');
  var left = paid - price;
  if (left == 0) return 'لا باقي';
  var parts = <String>[];
  // من أكبر ورقة نزولاً: كم واحدة تدخل، وكم يبقى.
  for (var note in notes) {
    var count = left ~/ note;
    left = left % note;
    if (count > 0) parts.add('$count × $note');
  }
  return parts.join(' + ');
}

void main() {
  print('الباقي: ${change(price: 137, paid: 500)}');
  print('الباقي: ${change(price: 45, paid: 50)}');
  print('الباقي: ${change(price: 80, paid: 80)}');
  print('الباقي: ${change(price: 120, paid: 100)}');
}
