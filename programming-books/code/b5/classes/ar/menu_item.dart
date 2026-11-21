class MenuItem {
  // الحقول: ما يعرفه كل صنف في القائمة. final، لأن الصنف لا يتغير أبداً.
  final String name;
  final int price;

  // المُنشئ: this.name تضع المعامل الأول في الحقل مباشرة.
  const MenuItem(this.name, this.price);

  // دالة تابعة (method): دالة تخص الصنف وتستطيع استخدام حقوله.
  int priceFor(int count) => price * count;

  // ما تعرضه print للصنف.
  @override
  String toString() => '$name ($price جنيه)';
}

void main() {
  var latte = const MenuItem('لاتيه', 45);
  var cookie = const MenuItem('كوكيز', 20);
  print(latte);
  print(latte.name);
  print(cookie.priceFor(3));
}
