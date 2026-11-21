void main() {
  // A Set keeps each value once, whatever happens.
  var tags = <String>{'sweet', 'hot'};
  tags.add('sweet');
  tags.add('vegan');
  print(tags);
  print(tags.length);

  var cakeTags = {'sweet', 'cold'};
  print(tags.intersection(cakeTags));
  print(tags.union(cakeTags));
  print(tags.difference(cakeTags));

  var orders = ['Latte', 'Tea', 'Latte', 'Cake', 'Tea'];
  print(orders.toSet());
}
