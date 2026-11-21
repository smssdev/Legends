int twice(int n) => n * 2;

void main() {
  // الدالة قيمة: يمكن حفظها في متغير وتمريرها إلى دالة أخرى.
  var change = twice;
  print(change(21));

  // دالة بلا اسم، تُكتب حيث نحتاجها.
  var prices = [12, 30, 8, 45];
  var cheap = prices.where((p) => p < 20).toList();
  var doubled = prices.map(twice).toList();
  print(cheap);
  print(doubled);

  prices.forEach((p) {
    print('${p.toString().padLeft(3)} جنيه');
  });
}
