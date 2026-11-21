"""Writes the examples of Book 5, chapter "Dart Basics", in English and Arabic, and runs every one of them.
Run: python3 make.py   (needs Dart 3.14, which comes with Flutter 3.50.1)

Each example is a single file run with `dart run file.dart`; what it printed (or the compiler's real message,
for the files that show a mistake) is saved next to it as file.sh, which the book prints as a terminal.
The practice projects' solutions are in projects/.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import dart_examples  # noqa: E402

T = {
    "en": dict(
        w_hello="Hello, Dart!", w_egp="EGP", w_comma=",", w_sara="Sara", w_omar="Omar", w_ten="ten",
        w_c_infer="Dart works out the type from the first value: score is an int, for ever.",
        w_c_typed="Or write the type yourself.",
        w_c_final="final: set once, when the program runs.",
        w_c_const="const: known before the program runs, and never changes.",
        w_c_div="/ always gives a double; ~/ divides and drops what is after the point.",
        w_c_parse="Text from a user or a file becomes a number with parse.",
        w_c_round="Two digits after the point, as text, ready to show.",
        w_price="Price", w_items="items", w_total="Total", w_welcome="Welcome back",
        w_c_interp="$name puts a variable in the text; ${...} any expression.",
        w_c_multi="Three quotes: text over several lines.",
        w_poem="Roses are red,\n  Dart is too,\n  every value has a type,\n  and so should you.",
        w_spaces="  bit café  ",
        w_c_inc="score += 5 is a short way to write score = score + 5.",
        w_age="Age", w_pays="pays", w_free="enters free", w_child="Child", w_adult="Adult",
        w_c_ternary="condition ? if true : if false, for small choices.",
        w_member="member", w_guest="guest",
        w_c_switch="No break needed: Dart never runs into the next case.",
        w_small="Small cup", w_medium="Medium cup", w_large="Large cup", w_unknown="Unknown size",
        w_c_expr="A switch expression produces a value. The first pattern that matches wins.",
        w_weekend="Weekend", w_workday="Workday",
        w_c_rel=">= 90 is a pattern: it matches any value that is at least 90.",
        w_c_wild="_ matches anything: the case for everyone else.",
        w_c_for="Count from 1 to 3.", w_c_forin="for-in: every item of a list, in order.",
        w_c_while="while: repeat as long as the condition is true.",
        w_c_break="continue skips to the next round; break leaves the loop.",
        w_round="Round", w_tea="tea", w_coffee="coffee", w_juice="juice", w_cup="Cup",
        w_c_arrow="One expression? The arrow => replaces { return ...; }.",
        w_c_named="Named parameters are written with their names; required ones must be given.",
        w_c_default="Optional, with a default value.",
        w_c_positional="Optional positional parameters go in square brackets.",
        w_greet="Hello", w_morning="Good morning",
        w_c_value="A function is a value: it can be stored in a variable and passed to another function.",
        w_c_anon="A function without a name, written where it is needed.",
        # The café receipt
        w_cafe="BIT CAFÉ", w_latte="Latte", w_cookie="Cookie", w_cake="Cake",
        w_subtotal="Subtotal", w_discount="Discount", w_service="Service 12%", w_pay="To pay",
        w_c_menu="Prices in whole pounds; Chapter 3 keeps them in a class.",
        w_c_day="The day decides the discount: 20% on Fridays, 10% on Saturdays.",
        w_c_line="One line of the receipt: name on the left, amount on the right.",
        w_c_service="Service is rounded to the nearest pound.",
        w_friday="friday", w_saturday="saturday", w_monday="monday",
        # Projects
        w_cold="cold", w_mild="mild", w_warm="warm", w_hot="hot",
        w_weak="weak", w_fair="fair", w_strong="strong",
        w_c_check="Look at every character once, and count what we need.",
        w_c_score="One point for each thing the password has.",
        w_not_enough="Not enough: {0} more needed.", w_change="Change", w_none="no change",
        w_c_notes="From the largest note down: how many of each fit, and what is left.",
        w_note="note", w_coin="coin",
        w_c_paid="Paid less than the price? Say so, and stop.",
    ),
    "ar": dict(
        w_hello="مرحباً يا Dart!", w_egp="جنيه", w_comma="،", w_sara="سارة", w_omar="عمر", w_ten="عشرة",
        w_c_infer="تستنتج Dart النوع من أول قيمة: score من النوع int إلى الأبد.",
        w_c_typed="أو اكتب النوع بنفسك.",
        w_c_final="final: تُضبط مرة واحدة، عند تشغيل البرنامج.",
        w_c_const="const: معروفة قبل تشغيل البرنامج، ولا تتغير أبداً.",
        w_c_div="/ تعطي double دائماً؛ و~/ تقسم وتحذف ما بعد الفاصلة.",
        w_c_parse="النص القادم من المستخدم أو من ملف يصير رقماً بـ parse.",
        w_c_round="رقمان بعد الفاصلة، نصاً جاهزاً للعرض.",
        w_price="السعر", w_items="قطع", w_total="الإجمالي", w_welcome="أهلاً بعودتك",
        w_c_interp="$name تضع متغيراً في النص؛ و${...} أي تعبير.",
        w_c_multi="ثلاث علامات تنصيص: نص على عدة أسطر.",
        w_poem="الورد أحمر،\n  وDart كذلك،\n  لكل قيمة نوع،\n  فاعرف نوعك.",
        w_spaces="  مقهى بِت  ",
        w_c_inc="score += 5 طريقة مختصرة لكتابة score = score + 5.",
        w_age="العمر", w_pays="يدفع", w_free="يدخل مجاناً", w_child="طفل", w_adult="بالغ",
        w_c_ternary="الشرط ? إن تحقق : إن لم يتحقق، للاختيارات الصغيرة.",
        w_member="عضو", w_guest="زائر",
        w_c_switch="لا حاجة إلى break: لا تنتقل Dart أبداً إلى الحالة التالية.",
        w_small="كوب صغير", w_medium="كوب وسط", w_large="كوب كبير", w_unknown="حجم غير معروف",
        w_c_expr="تعبير switch ينتج قيمة. وأول نمط يطابق هو الذي يفوز.",
        w_weekend="عطلة", w_workday="يوم عمل",
        w_c_rel=">= 90 نمط: يطابق أي قيمة لا تقل عن 90.",
        w_c_wild="_ يطابق أي شيء: الحالة لكل ما عدا ذلك.",
        w_c_for="عُدّ من 1 إلى 3.", w_c_forin="for-in: كل عنصر في القائمة، بالترتيب.",
        w_c_while="while: كرّر ما دام الشرط صحيحاً.",
        w_c_break="continue تقفز إلى الدورة التالية؛ وbreak تخرج من الحلقة.",
        w_round="الدورة", w_tea="شاي", w_coffee="قهوة", w_juice="عصير", w_cup="الكوب",
        w_c_arrow="تعبير واحد؟ السهم => يحل محل { return ...; }.",
        w_c_named="المعاملات المسماة تُكتب بأسمائها؛ والمطلوب منها لا بد أن يُعطى.",
        w_c_default="اختياري، بقيمة افتراضية.",
        w_c_positional="المعاملات الموضعية الاختيارية بين قوسين مربعين.",
        w_greet="مرحباً", w_morning="صباح الخير",
        w_c_value="الدالة قيمة: يمكن حفظها في متغير وتمريرها إلى دالة أخرى.",
        w_c_anon="دالة بلا اسم، تُكتب حيث نحتاجها.",
        w_cafe="مقهى بِت", w_latte="لاتيه", w_cookie="كوكيز", w_cake="كيك",
        w_subtotal="المجموع", w_discount="الخصم", w_service="الخدمة 12%", w_pay="المطلوب",
        w_c_menu="الأسعار بالجنيه الكامل؛ والفصل 3 يضعها في صنف.",
        w_c_day="اليوم يحدد الخصم: 20% يوم الجمعة، و10% يوم السبت.",
        w_c_line="سطر واحد من الفاتورة: الاسم في جهة، والمبلغ في الأخرى.",
        w_c_service="تُقرّب الخدمة إلى أقرب جنيه.",
        w_friday="الجمعة", w_saturday="السبت", w_monday="الاثنين",
        w_cold="بارد", w_mild="معتدل", w_warm="دافئ", w_hot="حار",
        w_weak="ضعيفة", w_fair="مقبولة", w_strong="قوية",
        w_c_check="انظر إلى كل حرف مرة واحدة، وعُدّ ما نحتاجه.",
        w_c_score="نقطة لكل شيء موجود في كلمة المرور.",
        w_not_enough="المبلغ لا يكفي: ينقص {0}.", w_change="الباقي", w_none="لا باقي",
        w_c_notes="من أكبر ورقة نزولاً: كم واحدة تدخل، وكم يبقى.",
        w_note="ورقة", w_coin="عملة",
        w_c_paid="دفع أقل من السعر؟ قل ذلك، وتوقف.",
    ),
}

# name -> (source, shows a mistake?)
FILES = {
    "hello.dart": """void main() {
  print('{w_hello}');
}
""",
    "variables.dart": """void main() {
  // {w_c_infer}
  var score = 0;
  score = score + 10;
  print(score);

  // {w_c_typed}
  String name = '{w_sara}';
  print(name);

  // {w_c_final}
  final joined = DateTime.now().year;
  print(joined > 2000);

  // {w_c_const}
  const maxPlayers = 4;
  print(maxPlayers);
}
""",
    "type-error.dart": """void main() {
  var score = 0;
  score = '{w_ten}';
  print(score);
}
""",
    "final-error.dart": """void main() {
  final name = '{w_sara}';
  name = '{w_omar}';
  print(name);
}
""",
    "numbers.dart": """void main() {
  int cups = 7;
  double price = 12.5;
  num anything = 3;
  bool open = true;
  print(cups);
  print(price);
  print(anything);
  print(open);

  // {w_c_div}
  print(7 / 2);
  print(7 ~/ 2);
  print(7 % 2);

  // {w_c_parse}
  int age = int.parse('34');
  double weight = double.parse('2.75');
  print(age + 1);
  print(weight * 2);

  // {w_c_round}
  print((10 / 3).toStringAsFixed(2));
  print(age.toString() + '!');
}
""",
    "strings.dart": """void main() {
  var name = '{w_sara}';
  var items = 3;
  var price = 12.5;

  // {w_c_interp}
  print('{w_welcome}{w_comma} $name!');
  print('$items {w_items} × $price = ${items * price}');
  print('{w_price}: ${price.toStringAsFixed(2)}');

  // {w_c_multi}
  var poem = '''{w_poem}''';
  print(poem);

  var raw = '{w_spaces}';
  print('[${raw.trim()}]');
  print(raw.trim().toUpperCase());
  print(name.length);
  print(name.contains('{w_sara}'));
  print('7'.padLeft(3, '0'));
}
""",
    "operators.dart": """void main() {
  var score = 10;
  // {w_c_inc}
  score += 5;
  score++;
  print(score);

  print(score == 16);
  print(score != 16);
  print(score > 10 && score < 20);
  print(score < 10 || score > 15);
  print(!(score > 10));

  print(5 == 5.0);
  print('5' == 5);
}
""",
    "ticket.dart": """void main() {
  var age = 9;
  var isMember = true;

  int price;
  if (age < 4) {
    price = 0;
  } else if (age < 13 || age >= 65) {
    price = 6;
  } else {
    price = 10;
  }

  if (isMember) {
    price = price ~/ 2;
  }

  // {w_c_ternary}
  var kind = age < 18 ? '{w_child}' : '{w_adult}';
  var who = isMember ? '{w_member}' : '{w_guest}';
  print('{w_age} $age ($kind{w_comma} $who) {w_pays} $price');
}
""",
    "switch.dart": """void main() {
  var size = 'M';

  // {w_c_switch}
  switch (size) {
    case 'S':
      print('{w_small}');
    case 'M':
      print('{w_medium}');
    case 'L':
      print('{w_large}');
    default:
      print('{w_unknown}');
  }

  // {w_c_expr}
  var day = '{w_friday}';
  var kind = switch (day) {
    '{w_friday}' || '{w_saturday}' => '{w_weekend}',
    _ => '{w_workday}',
  };
  print(kind);

  for (var score in [95, 83, 71, 40]) {
    var grade = switch (score) {
      // {w_c_rel}
      >= 90 => 'A',
      >= 80 => 'B',
      >= 70 => 'C',
      >= 50 => 'D',
      // {w_c_wild}
      _ => 'F',
    };
    print('$score -> $grade');
  }
}
""",
    "loops.dart": """void main() {
  // {w_c_for}
  for (var i = 1; i <= 3; i++) {
    print('{w_round} $i');
  }

  // {w_c_forin}
  var drinks = ['{w_tea}', '{w_coffee}', '{w_juice}'];
  for (var drink in drinks) {
    print(drink);
  }

  // {w_c_while}
  var cups = 3;
  while (cups > 0) {
    print('{w_cup} $cups');
    cups--;
  }

  // {w_c_break}
  for (var n = 1; n <= 10; n++) {
    if (n % 2 == 0) continue;
    if (n > 7) break;
    print(n);
  }
}
""",
    "functions.dart": """int square(int n) {
  return n * n;
}

// {w_c_arrow}
int cube(int n) => n * n * n;

// {w_c_named}
double price({required int cups, double each = 12.5}) => cups * each;

// {w_c_positional}
String greet(String name, [String greeting = '{w_greet}']) => '$greeting{w_comma} $name!';

void main() {
  print(square(4));
  print(cube(3));
  print(price(cups: 2));
  print(price(each: 20, cups: 3));
  print(greet('{w_sara}'));
  print(greet('{w_omar}', '{w_morning}'));
}
""",
    "named-error.dart": """double price({required int cups, double each = 12.5}) => cups * each;

void main() {
  print(price(each: 20));
}
""",
    "values.dart": """int twice(int n) => n * 2;

void main() {
  // {w_c_value}
  var change = twice;
  print(change(21));

  // {w_c_anon}
  var prices = [12, 30, 8, 45];
  var cheap = prices.where((p) => p < 20).toList();
  var doubled = prices.map(twice).toList();
  print(cheap);
  print(doubled);

  prices.forEach((p) {
    print('${p.toString().padLeft(3)} {w_egp}');
  });
}
""",
    "receipt.dart": """// {w_c_menu}
const latte = 45;
const cookie = 20;
const cake = 60;
const width = 26;

// {w_c_day}
int discountPercent(String day) => switch (day) {
      '{w_friday}' => 20,
      '{w_saturday}' => 10,
      _ => 0,
    };

// {w_c_line}
String line(String name, int amount) =>
    name.padRight(width - 8) + amount.toString().padLeft(8);

void printReceipt({required String day, int lattes = 0, int cookies = 0, int cakes = 0}) {
  var subtotal = lattes * latte + cookies * cookie + cakes * cake;
  var discount = subtotal * discountPercent(day) ~/ 100;
  // {w_c_service}
  var service = ((subtotal - discount) * 0.12).round();
  var total = subtotal - discount + service;

  print('=' * width);
  print('{w_cafe} · $day');
  print('-' * width);
  if (lattes > 0) print(line('$lattes × {w_latte}', lattes * latte));
  if (cookies > 0) print(line('$cookies × {w_cookie}', cookies * cookie));
  if (cakes > 0) print(line('$cakes × {w_cake}', cakes * cake));
  print('-' * width);
  print(line('{w_subtotal}', subtotal));
  if (discount > 0) print(line('{w_discount}', -discount));
  print(line('{w_service}', service));
  print(line('{w_pay}', total));
  print('=' * width);
}

void main() {
  printReceipt(day: '{w_friday}', lattes: 2, cookies: 3);
  printReceipt(day: '{w_monday}', cakes: 1, lattes: 1);
}
""",
}

ERRORS = {"type-error.dart", "final-error.dart", "named-error.dart"}

PROJECTS = {
    "projects/temperatures.dart": """double toFahrenheit(double c) => c * 9 / 5 + 32;

String feel(double c) => switch (c) {
      < 10 => '{w_cold}',
      < 20 => '{w_mild}',
      < 30 => '{w_warm}',
      _ => '{w_hot}',
    };

void main() {
  for (var c = -10; c <= 40; c += 10) {
    var f = toFahrenheit(c.toDouble());
    print('${c.toString().padLeft(4)} °C = ${f.toStringAsFixed(1).padLeft(5)} °F  ${feel(c.toDouble())}');
  }
}
""",
    "projects/password.dart": """String strength(String password, {int minLength = 8}) {
  var digits = 0, upper = 0, lower = 0, other = 0;
  // {w_c_check}
  for (var ch in password.split('')) {
    if ('0123456789'.contains(ch)) {
      digits++;
    } else if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
      upper++;
    } else if (ch.toLowerCase() == ch && ch.toUpperCase() != ch) {
      lower++;
    } else {
      other++;
    }
  }
  // {w_c_score}
  var points = 0;
  if (password.length >= minLength) points++;
  if (digits > 0) points++;
  if (upper > 0 && lower > 0) points++;
  if (other > 0) points++;
  return switch (points) {
    4 => '{w_strong}',
    2 || 3 => '{w_fair}',
    _ => '{w_weak}',
  };
}

void main() {
  for (var p in ['cairo', 'cairo2026', 'Cairo2026', 'Cairo#2026', 'Ab#1']) {
    print('${p.padRight(12)} ${strength(p)}');
  }
  print('Ab#1 (minLength: 4) ${strength('Ab#1', minLength: 4)}');
}
""",
    "projects/change.dart": """const notes = [200, 100, 50, 20, 10, 5, 1];

String change({required int price, required int paid}) {
  // {w_c_paid}
  if (paid < price) return '{w_not_enough}'.replaceFirst('{0}', '${price - paid}');
  var left = paid - price;
  if (left == 0) return '{w_none}';
  var parts = <String>[];
  // {w_c_notes}
  for (var note in notes) {
    var count = left ~/ note;
    left = left % note;
    if (count > 0) parts.add('$count × $note');
  }
  return parts.join(' + ');
}

void main() {
  print('{w_change}: ${change(price: 137, paid: 500)}');
  print('{w_change}: ${change(price: 45, paid: 50)}');
  print('{w_change}: ${change(price: 80, paid: 80)}');
  print('{w_change}: ${change(price: 120, paid: 100)}');
}
""",
}

ANSWERS = {
    "answers/predict.dart": """void main() {
  print(10 ~/ 3);
  print(10 % 3);
  print(10 / 4);
  print('ab' * 3);
  print('Dart'.length);
}
""",
    "answers/ticket_switch.dart": """void main() {
  var age = 9;
  var isMember = true;

  var price = switch (age) {
    < 4 => 0,
    < 13 || >= 65 => 6,
    _ => 10,
  };
  if (isMember) price = price ~/ 2;
  print('{w_age} $age {w_pays} $price');
}
""",
    # Arabic counts in more forms than English (one, two, a few, many), so its exercise differs.
    "answers/plural.dart": {"en": """String plural(int count, String word, {String many = ''}) {
  if (count == 1) return '$count $word';
  return '$count ${many.isEmpty ? '${word}s' : many}';
}

void main() {
  print(plural(1, 'cup'));
  print(plural(2, 'cup'));
  print(plural(0, 'cup'));
  print(plural(2, 'child', many: 'children'));
}
""", "ar": """String plural(int count,
    {required String one, required String two, required String few, required String many}) {
  var rest = count % 100;
  return switch (count) {
    0 => 'لا $few',
    1 => '$one واحد',
    2 => two,
    _ when rest >= 3 && rest <= 10 => '$count $few',
    _ when rest >= 11 => '$count $many',
    _ => '$count $one',
  };
}

void main() {
  for (var n in [0, 1, 2, 3, 10, 11, 99, 100, 103]) {
    print(plural(n, one: 'كوب', two: 'كوبان', few: 'أكواب', many: 'كوباً'));
  }
}
"""},
    "answers/table.dart": """void main() {
  for (var row = 1; row <= 9; row++) {
    var line = StringBuffer();
    for (var col = 1; col <= 9; col++) {
      line.write((row * col).toString().padLeft(4));
    }
    print(line);
  }
}
""",
}


def main():
    dart_examples(HERE, T, {**FILES, **PROJECTS, **ANSWERS}, ERRORS)


if __name__ == "__main__":
    main()
