void main() {
  // Set تحفظ كل قيمة مرة واحدة، مهما حدث.
  var tags = <String>{'حلو', 'ساخن'};
  tags.add('حلو');
  tags.add('نباتي');
  print(tags);
  print(tags.length);

  var cakeTags = {'حلو', 'بارد'};
  print(tags.intersection(cakeTags));
  print(tags.union(cakeTags));
  print(tags.difference(cakeTags));

  var orders = ['لاتيه', 'شاي', 'لاتيه', 'كيك', 'شاي'];
  print(orders.toSet());
}
