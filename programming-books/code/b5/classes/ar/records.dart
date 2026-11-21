// Record: قيمتان تسافران معاً، بلا حاجة إلى صنف.
(int, int) cheapestAndDearest(List<int> prices) {
  var sorted = [...prices]..sort();
  return (sorted.first, sorted.last);
}

({String name, int price}) special() => (name: 'كيك', price: 50);

void main() {
  var prices = [45, 20, 60, 15];
  var result = cheapestAndDearest(prices);
  print(result);
  print(result.$1);

  // نمط يفكّ الـ Record إلى متغيرين.
  var (low, high) = cheapestAndDearest(prices);
  print('الأرخص: $low, الأغلى: $high');

  var today = special();
  print('${today.name}: ${today.price}');
}
