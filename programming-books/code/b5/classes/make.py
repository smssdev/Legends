"""Writes the examples of Book 5, chapter "Classes, Null Safety and Collections", in English and Arabic,
and runs every one of them.
Run: python3 make.py   (needs Dart 3.14, which comes with Flutter 3.50.1)

Bit's café gets a shape: menu items as classes, sizes as an enum, orders as lists and maps. Each example is
one file run with `dart run`; its output, or the compiler's (or the runtime's) real message for the files
that show a mistake, is saved next to it as file.sh. Projects in projects/, exercise answers in answers/.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import dart_examples  # noqa: E402

T = {
    "en": dict(
        w_latte="Latte", w_cookie="Cookie", w_cake="Cake", w_tea="Tea", w_water="water", w_egp="EGP", w_comma=",",
        w_c_fields="Fields: what every menu item knows. final, because an item never changes.",
        w_c_ctor="The constructor: this.name puts the first argument straight into the field.",
        w_c_method="A method: a function that belongs to the item and can use its fields.",
        w_c_tostring="What print shows for an item.",
        w_c_named="Named parameters, as in Chapter 2: the call says which value is which.",
        w_c_getter="A getter: looks like a field, but is calculated each time.",
        w_c_private="_lines starts with _: private, only this file can touch it.",
        w_c_add="Add one line to the order; the quantity starts at 1.",
        w_items="items", w_total="Total",
        w_nick="Bito", w_c_nullable="String? may hold a String, or null: nothing at all.",
        w_c_promote="Inside this if, Dart knows nickname is not null.",
        w_c_qq="?? gives the value on its right when the left is null.",
        w_c_qdot="?. asks only when there is something to ask: null stays null.",
        w_c_qqeq="??= sets a value only if there is none yet.",
        w_guest="Guest", w_no_nick="no nickname",
        w_c_bang="! says: trust me, this is not null. Here it is.",
        w_c_enum="Each size knows how much it adds to the price.",
        w_c_enum_switch="The switch covers every size: the compiler checks it.",
        w_small="small cup", w_medium="medium cup", w_large="large cup",
        w_c_list="A List<int>: only ints may go in.",
        w_c_spread="... spreads one list inside another; if and for work inside a list too.",
        w_c_fold="fold carries a running total through the list.",
        w_c_map="A Map: each key (a name) leads to one value (a quantity).",
        w_c_lookup="Looking up a key gives int?: the key may not be there.",
        w_c_update="update changes a value; ifAbsent says what to do when the key is missing.",
        w_sugar="sugar", w_milk="milk", w_cups="cups", w_beans="beans", w_missing="not in stock",
        w_c_set="A Set keeps each value once, whatever happens.",
        w_sweet="sweet", w_hot="hot", w_cold="cold", w_vegan="vegan",
        w_c_record="A record: two values travel together, no class needed.",
        w_c_destructure="A pattern takes the record apart into two variables.",
        w_cheapest="cheapest", w_dearest="most expensive",
        w_c_menu="The menu: a const list of const items, built once.",
        w_c_order="An order: how many of each item. A Map, because each item appears once.",
        w_c_lines="One line per item, sorted by name, built with a for inside the list.",
        w_order="Order", w_table="table",
        # Projects
        w_sara="Sara", w_omar="Omar", w_mona="Mona", w_no_phone="no phone",
        w_c_contact="phone is optional: some contacts have none.",
        w_text="the cat sat on the mat and the cat slept on the mat while the dog sat on the floor",
        w_words="words", w_different="different", w_top="most used",
        w_c_count="Count every word: start at 0 the first time it is seen.",
        w_c_sort="Sort the entries from the most used down.",
        w_circle="circle", w_rect="rectangle", w_square="square", w_area="area",
        w_c_sealed="sealed: these three are the only kinds of Shape, so a switch can cover them all.",
        w_largest="largest",
        # Answers
        w_c_copy="copyWith: a new item like this one, with some fields changed.",
        w_apple="apple", w_avocado="avocado", w_banana="banana", w_cherry="cherry", w_blueberry="blueberry",
        w_saturday="Saturday", w_sunday="Sunday", w_friday="Friday",
        w_weekend="weekend", w_workday="workday",
    ),
    "ar": dict(
        w_latte="لاتيه", w_cookie="كوكيز", w_cake="كيك", w_tea="شاي", w_water="مياه", w_egp="جنيه", w_comma="،",
        w_c_fields="الحقول: ما يعرفه كل صنف في القائمة. final، لأن الصنف لا يتغير أبداً.",
        w_c_ctor="المُنشئ: this.name تضع المعامل الأول في الحقل مباشرة.",
        w_c_method="دالة تابعة (method): دالة تخص الصنف وتستطيع استخدام حقوله.",
        w_c_tostring="ما تعرضه print للصنف.",
        w_c_named="معاملات مسماة كما في الفصل 2: الاستدعاء يقول أي قيمة لأي حقل.",
        w_c_getter="getter: يبدو كحقل، لكنه يُحسب في كل مرة.",
        w_c_private="_lines تبدأ بـ _: خاصة، لا يلمسها إلا هذا الملف.",
        w_c_add="أضف سطراً إلى الطلب؛ والكمية تبدأ بـ 1.",
        w_items="قطع", w_total="الإجمالي",
        w_nick="بيتو", w_c_nullable="String? قد يحمل نصاً، أو null: لا شيء على الإطلاق.",
        w_c_promote="داخل هذا الـ if تعرف Dart أن nickname ليس null.",
        w_c_qq="?? تعطي القيمة التي على يمينها حين يكون ما على يسارها null.",
        w_c_qdot="?. تسأل فقط حين يوجد ما يُسأل: والـ null يبقى null.",
        w_c_qqeq="??= تضع قيمة فقط إن لم تكن هناك قيمة بعد.",
        w_guest="زائر", w_no_nick="لا لقب",
        w_c_bang="! تقول: ثق بي، هذا ليس null. وهو هنا null.",
        w_c_enum="كل حجم يعرف كم يضيف إلى السعر.",
        w_c_enum_switch="الـ switch يغطي كل الأحجام: والمترجم يتحقق من ذلك.",
        w_small="كوب صغير", w_medium="كوب وسط", w_large="كوب كبير",
        w_c_list="List<int>: لا يدخلها إلا int.",
        w_c_spread="... تفرد قائمة داخل أخرى؛ وif وfor تعملان داخل القائمة أيضاً.",
        w_c_fold="fold تحمل مجموعاً متراكماً عبر القائمة.",
        w_c_map="Map: كل مفتاح (اسم) يقود إلى قيمة واحدة (كمية).",
        w_c_lookup="البحث بمفتاح يعطي int?: فقد لا يكون المفتاح موجوداً.",
        w_c_update="update تغيّر قيمة؛ وifAbsent تقول ماذا تفعل حين يغيب المفتاح.",
        w_sugar="سكر", w_milk="حليب", w_cups="أكواب", w_beans="بُن", w_missing="غير متوفر",
        w_c_set="Set تحفظ كل قيمة مرة واحدة، مهما حدث.",
        w_sweet="حلو", w_hot="ساخن", w_cold="بارد", w_vegan="نباتي",
        w_c_record="Record: قيمتان تسافران معاً، بلا حاجة إلى صنف.",
        w_c_destructure="نمط يفكّ الـ Record إلى متغيرين.",
        w_cheapest="الأرخص", w_dearest="الأغلى",
        w_c_menu="القائمة: قائمة const من أصناف const، تُبنى مرة واحدة.",
        w_c_order="الطلب: كم قطعة من كل صنف. Map، لأن كل صنف يظهر مرة واحدة.",
        w_c_lines="سطر لكل صنف، مرتبة بالاسم، تبنيها for داخل القائمة.",
        w_order="طلب", w_table="طاولة",
        w_sara="سارة", w_omar="عمر", w_mona="منى", w_no_phone="لا هاتف",
        w_c_contact="الهاتف اختياري: بعض جهات الاتصال بلا هاتف.",
        w_text="قال بِت إن القهوة جيدة ثم قال بِت إن الشاي جيد ثم قال إن الكيك جيد جداً",
        w_words="كلمة", w_different="مختلفة", w_top="الأكثر استخداماً",
        w_c_count="عُدّ كل كلمة: ابدأ من 0 أول مرة تظهر فيها.",
        w_c_sort="رتّب المدخلات من الأكثر استخداماً نزولاً.",
        w_circle="دائرة", w_rect="مستطيل", w_square="مربع", w_area="المساحة",
        w_c_sealed="sealed: هذه الثلاثة هي كل أنواع Shape، فيستطيع switch أن يغطيها كلها.",
        w_largest="الأكبر",
        w_c_copy="copyWith: صنف جديد مثل هذا، مع تغيير بعض الحقول.",
        w_apple="تفاح", w_avocado="توت", w_banana="موز", w_cherry="كرز", w_blueberry="مانجو",
        w_saturday="السبت", w_sunday="الأحد", w_friday="الجمعة",
        w_weekend="عطلة", w_workday="يوم عمل",
    ),
}

FILES = {
    "menu_item.dart": """class MenuItem {
  // {w_c_fields}
  final String name;
  final int price;

  // {w_c_ctor}
  const MenuItem(this.name, this.price);

  // {w_c_method}
  int priceFor(int count) => price * count;

  // {w_c_tostring}
  @override
  String toString() => '$name ($price {w_egp})';
}

void main() {
  var latte = const MenuItem('{w_latte}', 45);
  var cookie = const MenuItem('{w_cookie}', 20);
  print(latte);
  print(latte.name);
  print(cookie.priceFor(3));
}
""",
    "order.dart": """class MenuItem {
  final String name;
  final int price;
  // {w_c_named}
  const MenuItem({required this.name, required this.price});

  // {w_c_getter}
  bool get isExpensive => price >= 50;
}

class Order {
  // {w_c_private}
  final List<MenuItem> _lines = [];

  // {w_c_add}
  void add(MenuItem item, [int count = 1]) {
    for (var i = 0; i < count; i++) {
      _lines.add(item);
    }
  }

  int get count => _lines.length;
  int get total => _lines.fold(0, (sum, item) => sum + item.price);
}

void main() {
  const latte = MenuItem(name: '{w_latte}', price: 45);
  const cake = MenuItem(name: '{w_cake}', price: 60);
  print(cake.isExpensive);

  var order = Order();
  order.add(latte, 2);
  order.add(cake);
  print('${order.count} {w_items}, {w_total}: ${order.total} {w_egp}');
}
""",
    "nullable.dart": """void main() {
  // {w_c_nullable}
  String? nickname;
  print(nickname);

  // {w_c_qq}
  print(nickname ?? '{w_guest}');

  // {w_c_qdot}
  print(nickname?.length);

  // {w_c_qqeq}
  nickname ??= '{w_nick}';
  print(nickname);

  String? other;
  // {w_c_promote}
  if (other != null) {
    print(other.length);
  } else {
    print('{w_no_nick}');
  }
}
""",
    "null-error.dart": """void main() {
  String? nickname;
  print(nickname.length);
}
""",
    "bang-error.dart": """void main() {
  String? nickname;
  // {w_c_bang}
  print(nickname!.length);
}
""",
    "sizes.dart": """// {w_c_enum}
enum CupSize {
  small(0),
  medium(5),
  large(10);

  final int extra;
  const CupSize(this.extra);
}

String label(CupSize size) {
  // {w_c_enum_switch}
  return switch (size) {
    CupSize.small => '{w_small}',
    CupSize.medium => '{w_medium}',
    CupSize.large => '{w_large}',
  };
}

void main() {
  for (var size in CupSize.values) {
    print('${size.name}: ${label(size)}, +${size.extra} {w_egp}');
  }
  print(45 + CupSize.large.extra);
}
""",
    "enum-missing.dart": """enum CupSize { small, medium, large }

String label(CupSize size) {
  return switch (size) {
    CupSize.small => '{w_small}',
    CupSize.medium => '{w_medium}',
  };
}

void main() {
  print(label(CupSize.large));
}
""",
    "lists.dart": """void main() {
  // {w_c_list}
  var prices = <int>[45, 20, 60];
  prices.add(15);
  print(prices);
  print(prices[0]);
  print(prices.length);
  print(prices.contains(60));

  prices.remove(20);
  prices.sort();
  print(prices);

  // {w_c_spread}
  var isFriday = true;
  var extras = [5, 10];
  var all = [
    ...prices,
    ...extras,
    if (isFriday) 0,
    for (var p in prices) p * 2,
  ];
  print(all);

  // {w_c_fold}
  var total = prices.fold(0, (sum, p) => sum + p);
  print(total);
  print(prices.where((p) => p > 20).map((p) => '$p {w_egp}').toList());
}
""",
    "maps.dart": """void main() {
  // {w_c_map}
  var stock = <String, int>{'{w_sugar}': 40, '{w_milk}': 12, '{w_cups}': 200};
  print(stock['{w_milk}']);
  print(stock['{w_beans}']);

  // {w_c_lookup}
  int beans = stock['{w_beans}'] ?? 0;
  print(beans);

  stock['{w_beans}'] = 5;
  // {w_c_update}
  stock.update('{w_milk}', (n) => n - 2);
  stock.update('{w_water}', (n) => n + 6, ifAbsent: () => 6);
  print(stock.length);
  print(stock.containsKey('{w_sugar}'));

  for (var entry in stock.entries) {
    print('${entry.key}: ${entry.value}');
  }
  stock.remove('{w_cups}');
  print(stock.keys.toList());
}
""",
    "map-error.dart": """void main() {
  var stock = <String, int>{'{w_milk}': 12};
  int milk = stock['{w_milk}'];
  print(milk);
}
""",
    "sets.dart": """void main() {
  // {w_c_set}
  var tags = <String>{'{w_sweet}', '{w_hot}'};
  tags.add('{w_sweet}');
  tags.add('{w_vegan}');
  print(tags);
  print(tags.length);

  var cakeTags = {'{w_sweet}', '{w_cold}'};
  print(tags.intersection(cakeTags));
  print(tags.union(cakeTags));
  print(tags.difference(cakeTags));

  var orders = ['{w_latte}', '{w_tea}', '{w_latte}', '{w_cake}', '{w_tea}'];
  print(orders.toSet());
}
""",
    "records.dart": """// {w_c_record}
(int, int) cheapestAndDearest(List<int> prices) {
  var sorted = [...prices]..sort();
  return (sorted.first, sorted.last);
}

({String name, int price}) special() => (name: '{w_cake}', price: 50);

void main() {
  var prices = [45, 20, 60, 15];
  var result = cheapestAndDearest(prices);
  print(result);
  print(result.$1);

  // {w_c_destructure}
  var (low, high) = cheapestAndDearest(prices);
  print('{w_cheapest}: $low, {w_dearest}: $high');

  var today = special();
  print('${today.name}: ${today.price}');
}
""",
    "cafe.dart": """enum Category { drink, food }

class MenuItem {
  final String name;
  final int price;
  final Category category;
  const MenuItem(this.name, this.price, this.category);
}

// {w_c_menu}
const menu = [
  MenuItem('{w_latte}', 45, Category.drink),
  MenuItem('{w_tea}', 15, Category.drink),
  MenuItem('{w_cookie}', 20, Category.food),
  MenuItem('{w_cake}', 60, Category.food),
];

class Order {
  final int table;
  // {w_c_order}
  final Map<MenuItem, int> _counts = {};

  Order(this.table);

  void add(MenuItem item, {int count = 1}) {
    _counts.update(item, (n) => n + count, ifAbsent: () => count);
  }

  int get total {
    var sum = 0;
    _counts.forEach((item, n) => sum += item.price * n);
    return sum;
  }

  Set<Category> get categories => {for (var item in _counts.keys) item.category};

  // {w_c_lines}
  List<String> get lines {
    var items = _counts.keys.toList()..sort((a, b) => a.name.compareTo(b.name));
    return [for (var item in items) '${_counts[item]} × ${item.name}'];
  }
}

void main() {
  var order = Order(4);
  order.add(menu[0], count: 2);
  order.add(menu[3]);
  order.add(menu[0]);
  order.add(menu[2], count: 3);

  print('{w_order}{w_comma} {w_table} ${order.table}');
  for (var line in order.lines) {
    print('  $line');
  }
  print('{w_total}: ${order.total} {w_egp}');
  print(order.categories.map((c) => c.name).toList());
}
""",
}

ERRORS = {"null-error.dart", "bang-error.dart", "enum-missing.dart", "map-error.dart"}

PROJECTS = {
    "projects/contacts.dart": """class Contact {
  final String name;
  // {w_c_contact}
  final String? phone;
  const Contact(this.name, {this.phone});

  String describe() => '$name: ${phone ?? '{w_no_phone}'}';
}

void main() {
  var contacts = [
    const Contact('{w_sara}', phone: '0100 123 4567'),
    const Contact('{w_omar}'),
    const Contact('{w_mona}', phone: '0122 765 4321'),
  ];
  for (var c in contacts) {
    print(c.describe());
  }
  var withPhone = contacts.where((c) => c.phone != null).length;
  print('$withPhone / ${contacts.length}');
  print(contacts.map((c) => c.phone?.replaceAll(' ', '')).toList());
}
""",
    "projects/words.dart": """const text = '{w_text}';

void main() {
  var words = text.split(' ');
  // {w_c_count}
  var counts = <String, int>{};
  for (var w in words) {
    counts[w] = (counts[w] ?? 0) + 1;
  }
  print('${words.length} {w_words}{w_comma} ${counts.length} {w_different}');

  // {w_c_sort}
  var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  print('{w_top}:');
  for (var e in sorted.take(3)) {
    print('  ${e.key}: ${e.value}');
  }
  print(words.toSet().length == counts.length);
}
""",
    "projects/shapes.dart": """import 'dart:math' as math;

// {w_c_sealed}
sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double radius;
  const Circle(this.radius);
}

class Rect extends Shape {
  final double width, height;
  const Rect(this.width, this.height);
}

class Square extends Shape {
  final double side;
  const Square(this.side);
}

double area(Shape s) => switch (s) {
  Circle(radius: var r) => math.pi * r * r,
  Rect(width: var w, height: var h) => w * h,
  Square(side: var a) => a * a,
};

String name(Shape s) => switch (s) {
  Circle() => '{w_circle}',
  Rect() => '{w_rect}',
  Square() => '{w_square}',
};

void main() {
  var shapes = <Shape>[const Circle(1.5), const Rect(2, 3.5), const Square(2.5)];
  shapes.sort((a, b) => area(a).compareTo(area(b)));
  for (var s in shapes) {
    print('${name(s).padRight(10)} {w_area} ${area(s).toStringAsFixed(2)}');
  }
  var total = shapes.fold(0.0, (sum, s) => sum + area(s));
  print('{w_total}: ${total.toStringAsFixed(2)}');
  print('{w_largest}: ${name(shapes.last)}');
}
""",
}

ANSWERS = {
    "answers/null_predict.dart": """void main() {
  String? a;
  String? b = 'Dart';
  print(a ?? b);
  print(b?.length);
  print(a?.length ?? -1);
  a ??= 'Flutter';
  a ??= 'Kotlin';
  print(a);
}
""",
    "answers/copy_with.dart": """class MenuItem {
  final String name;
  final int price;
  const MenuItem({required this.name, required this.price});

  // {w_c_copy}
  MenuItem copyWith({String? name, int? price}) =>
      MenuItem(name: name ?? this.name, price: price ?? this.price);

  @override
  String toString() => '$name ($price)';
}

void main() {
  const latte = MenuItem(name: '{w_latte}', price: 45);
  var friday = latte.copyWith(price: 36);
  print(latte);
  print(friday);
  print(latte.copyWith(name: '{w_tea}', price: 15));
}
""",
    "answers/group.dart": """void main() {
  var words = ['{w_apple}', '{w_avocado}', '{w_banana}', '{w_cherry}', '{w_blueberry}'];
  var groups = <String, List<String>>{};
  for (var w in words) {
    groups.putIfAbsent(w[0], () => []).add(w);
  }
  print(groups);
}
""",
    "answers/weekday.dart": """enum Day {
  saturday('{w_saturday}'),
  sunday('{w_sunday}'),
  friday('{w_friday}');

  final String label;
  const Day(this.label);

  bool get isWeekend => this == Day.friday || this == Day.saturday;
}

void main() {
  for (var d in Day.values) {
    print('${d.label}: ${d.isWeekend ? '{w_weekend}' : '{w_workday}'}');
  }
}
""",
}


def keep(name, lines):
    """A runtime error ends with the stack of calls that led to it: keep the message and the reader's own
    line (#0), without the machine's paths."""
    if name != "bang-error.dart":
        return lines
    out = []
    for line in lines:
        if line.startswith("#1"):
            break
        out.append(line.replace("file://", ""))
    return out


def main():
    dart_examples(HERE, T, {**FILES, **PROJECTS, **ANSWERS}, ERRORS, keep)


if __name__ == "__main__":
    main()
