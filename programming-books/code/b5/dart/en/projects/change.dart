const notes = [200, 100, 50, 20, 10, 5, 1];

String change({required int price, required int paid}) {
  // Paid less than the price? Say so, and stop.
  if (paid < price)
    return 'Not enough: {0} more needed.'.replaceFirst(
      '{0}',
      '${price - paid}',
    );
  var left = paid - price;
  if (left == 0) return 'no change';
  var parts = <String>[];
  // From the largest note down: how many of each fit, and what is left.
  for (var note in notes) {
    var count = left ~/ note;
    left = left % note;
    if (count > 0) parts.add('$count × $note');
  }
  return parts.join(' + ');
}

void main() {
  print('Change: ${change(price: 137, paid: 500)}');
  print('Change: ${change(price: 45, paid: 50)}');
  print('Change: ${change(price: 80, paid: 80)}');
  print('Change: ${change(price: 120, paid: 100)}');
}
