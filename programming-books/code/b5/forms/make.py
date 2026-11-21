"""Writes the examples of Book 5, chapter "Forms and Input", in English and Arabic, photographs them after real
typing and taps, and runs their tests.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="", w_egp="EGP", w_cafe="Bit Café",
        w_name="Your name", w_name_hint="As on your cup", w_hello="Hello", w_stranger="stranger",
        w_typed="Sara",
        w_c_controller="A controller holds the text of the field, and can read or change it.",
        w_c_changed="onChanged runs on every key: rebuild, so the greeting follows.",
        w_c_dispose="Controllers must be released when the page goes away.",
        w_clear="Clear",
        w_phone="Phone", w_email="Email", w_password="Password", w_qty="Cups",
        w_show="Show password", w_hide="Hide password",
        w_c_keyboard="keyboardType chooses the keyboard: digits for a phone, @ for an email.",
        w_c_action="textInputAction: the key at the corner of the keyboard says Next, then Done.",
        w_c_obscure="obscureText hides what is typed; the eye button shows it.",
        w_c_length="maxLength: a limit, with a counter under the field.",
        w_c_key="The key gives us the form, to check every field at once.",
        w_c_validator="A validator returns an error message, or null when the value is fine.",
        w_required="Please enter your name", w_phone_bad="A phone number has 11 digits",
        w_email_bad="This does not look like an email address",
        w_send="Send", w_sent="Thank you, we will call you",
        w_c_auto="After the first try, check as the person types.",
        w_t_form="the form refuses empty fields and accepts good ones",
        w_size="Size", w_small="Small", w_medium="Medium", w_large="Large",
        w_oat="Oat milk", w_extra="Extra shot", w_iced="Iced", w_sugar="Sugar",
        w_milk="Milk", w_whole="Whole", w_skimmed="Skimmed", w_none="None",
        w_c_segment="SegmentedButton: one choice of a few, all visible.",
        w_c_check="CheckboxListTile: yes or no for each extra, independently.",
        w_c_slider="Slider: a number in a range, by dragging.",
        w_c_dropdown="DropdownMenu: one choice of a longer list, shown on demand.",
        w_spoons="spoons",
        # The café order form
        w_order="Your order", w_notes="Notes for the barista", w_notes_hint="No foam, please…",
        w_place="Place order", w_summary="Order for", w_total="Total", w_ok="OK",
        w_c_price="The price follows every choice: computed in build, never stored.",
        w_t_order="the order form sums the choices and checks the name",
        w_order_name="Mona",
        # Projects
        w_bill="Bill", w_tip="Tip", w_per="Each of", w_people="people", w_pay="Each pays",
        w_signup="Create account", w_confirm="Confirm password", w_terms="I accept the terms",
        w_pw_short="At least 8 characters", w_pw_match="The passwords do not match",
        w_terms_needed="Please accept the terms", w_welcome="Account created",
        w_t_signup="the sign-up form checks that the passwords match",
        w_search="Search the menu", w_no_results="No drink matches",
        w_drinks="Latte,Cappuccino,Mocha,Mint tea,Green tea,Orange juice,Lemonade,Hot chocolate",
        w_t_search="typing filters the list",
        w_query="tea",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_egp="جنيه", w_cafe="مقهى بِت",
        w_name="اسمك", w_name_hint="كما يُكتب على كوبك", w_hello="أهلاً", w_stranger="يا ضيفنا",
        w_typed="سارة",
        w_c_controller="المتحكم يحمل نص المربع، ويستطيع قراءته أو تغييره.",
        w_c_changed="onChanged تعمل مع كل حرف: أعد البناء، فتتبعه التحية.",
        w_c_dispose="يجب تحرير المتحكمات حين تُزال الصفحة.",
        w_clear="امسح",
        w_phone="الهاتف", w_email="البريد الإلكتروني", w_password="كلمة المرور", w_qty="الأكواب",
        w_show="أظهر كلمة المرور", w_hide="أخفِ كلمة المرور",
        w_c_keyboard="keyboardType تختار لوحة المفاتيح: أرقام للهاتف، و@ للبريد.",
        w_c_action="textInputAction: المفتاح في زاوية اللوحة يقول «التالي» ثم «تم».",
        w_c_obscure="obscureText تخفي ما يُكتب؛ وزر العين يُظهره.",
        w_c_length="maxLength: حد أقصى، مع عدّاد تحت المربع.",
        w_c_key="المفتاح يعطينا النموذج، لنفحص كل المربعات معاً.",
        w_c_validator="دالة التحقق تُرجع رسالة خطأ، أو null حين تكون القيمة سليمة.",
        w_required="من فضلك اكتب اسمك", w_phone_bad="رقم الهاتف من 11 رقماً",
        w_email_bad="لا يبدو هذا عنوان بريد",
        w_send="أرسل", w_sent="شكراً، سنتصل بك",
        w_c_auto="بعد أول محاولة، افحص والشخص يكتب.",
        w_t_form="النموذج يرفض المربعات الفارغة ويقبل السليمة",
        w_size="الحجم", w_small="صغير", w_medium="وسط", w_large="كبير",
        w_oat="حليب الشوفان", w_extra="جرعة إضافية", w_iced="مثلج", w_sugar="السكر",
        w_milk="الحليب", w_whole="كامل الدسم", w_skimmed="خالي الدسم", w_none="بلا حليب",
        w_c_segment="SegmentedButton: اختيار واحد من قليل، كلها ظاهرة.",
        w_c_check="CheckboxListTile: نعم أو لا لكل إضافة، كل منها مستقل.",
        w_c_slider="Slider: رقم ضمن مدى، بالسحب.",
        w_c_dropdown="DropdownMenu: اختيار واحد من قائمة أطول، تظهر عند الطلب.",
        w_spoons="ملاعق",
        w_order="طلبك", w_notes="ملاحظات للنادل", w_notes_hint="بلا رغوة من فضلك…",
        w_place="أرسل الطلب", w_summary="طلب باسم", w_total="الإجمالي", w_ok="حسناً",
        w_c_price="السعر يتبع كل اختيار: يُحسب في build، ولا يُحفظ أبداً.",
        w_t_order="نموذج الطلب يجمع الاختيارات ويفحص الاسم",
        w_order_name="منى",
        w_bill="الحساب", w_tip="البقشيش", w_per="لكل واحد من", w_people="أشخاص", w_pay="يدفع كل واحد",
        w_signup="أنشئ حساباً", w_confirm="أكّد كلمة المرور", w_terms="أوافق على الشروط",
        w_pw_short="8 أحرف على الأقل", w_pw_match="كلمتا المرور غير متطابقتين",
        w_terms_needed="من فضلك وافق على الشروط", w_welcome="أُنشئ الحساب",
        w_t_signup="نموذج التسجيل يتأكد من تطابق كلمتي المرور",
        w_search="ابحث في القائمة", w_no_results="لا مشروب مطابق",
        w_drinks="لاتيه,كابتشينو,موكا,شاي بالنعناع,شاي أخضر,عصير برتقال,ليموناضة,شوكولاتة ساخنة",
        w_t_search="الكتابة تصفّي القائمة",
        w_query="شاي",
    ),
}

FILES = {
    "lib/hello.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const HelloPage()));
}

class HelloPage extends StatefulWidget {
  const HelloPage({super.key});

  @override
  State<HelloPage> createState() => _HelloPageState();
}

class _HelloPageState extends State<HelloPage> {
  // {w_c_controller}
  final name = TextEditingController();

  @override
  void dispose() {
    // {w_c_dispose}
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final who = name.text.isEmpty ? '{w_stranger}' : name.text;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: '{w_name}',
                hintText: '{w_name_hint}',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: '{w_clear}',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(name.clear),
                ),
              ),
              // {w_c_changed}
              onChanged: (_) => setState(() {}),
            ),
            Text('{w_hello} $who!', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/keyboards.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const KeyboardsPage()));
}

class KeyboardsPage extends StatefulWidget {
  const KeyboardsPage({super.key});

  @override
  State<KeyboardsPage> createState() => _KeyboardsPageState();
}

class _KeyboardsPageState extends State<KeyboardsPage> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          // {w_c_keyboard}
          // {w_c_action}
          const TextField(
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: '{w_phone}', prefixIcon: Icon(Icons.phone)),
          ),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(labelText: '{w_email}', prefixIcon: Icon(Icons.email)),
          ),
          // {w_c_obscure}
          TextField(
            obscureText: hidden,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '{w_password}',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                tooltip: hidden ? '{w_show}' : '{w_hide}',
                icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => hidden = !hidden),
              ),
            ),
          ),
          // {w_c_length}
          const TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 2,
            decoration: InputDecoration(labelText: '{w_qty}', prefixIcon: Icon(Icons.local_cafe)),
          ),
        ],
      ),
    );
  }
}
""",
    "lib/form.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const CallBackForm()));
}

class CallBackForm extends StatefulWidget {
  const CallBackForm({super.key});

  @override
  State<CallBackForm> createState() => _CallBackFormState();
}

class _CallBackFormState extends State<CallBackForm> {
  // {w_c_key}
  final formKey = GlobalKey<FormState>();
  var mode = AutovalidateMode.disabled;

  void send() {
    if (formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('{w_sent}')));
    } else {
      // {w_c_auto}
      setState(() => mode = AutovalidateMode.onUserInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_cafe}')),
      body: Form(
        key: formKey,
        autovalidateMode: mode,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: '{w_name}'),
              // {w_c_validator}
              validator: (value) => (value == null || value.trim().isEmpty) ? '{w_required}' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: '{w_phone}'),
              keyboardType: TextInputType.phone,
              validator: (value) => RegExp(r'^[0-9]{11}$').hasMatch(value ?? '') ? null : '{w_phone_bad}',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: '{w_email}'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value ?? '').contains('@') ? null : '{w_email_bad}',
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: send, child: const Text('{w_send}')),
          ],
        ),
      ),
    );
  }
}
""",
    "test/form_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/form.dart';

void main() {
  testWidgets('{w_t_form}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CallBackForm()));

    await tester.tap(find.text('{w_send}'));
    await tester.pump();
    expect(find.text('{w_required}'), findsOneWidget);
    expect(find.text('{w_phone_bad}'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '{w_typed}');
    await tester.enterText(find.byType(TextFormField).at(1), '01001234567');
    await tester.enterText(find.byType(TextFormField).at(2), 'sara@example.com');
    await tester.tap(find.text('{w_send}'));
    await tester.pump();
    expect(find.text('{w_required}'), findsNothing);
    expect(find.text('{w_sent}'), findsOneWidget);
  });
}
""",
    "lib/choices.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const ChoicesPage()));
}

enum Size { small, medium, large }

class ChoicesPage extends StatefulWidget {
  const ChoicesPage({super.key});

  @override
  State<ChoicesPage> createState() => _ChoicesPageState();
}

class _ChoicesPageState extends State<ChoicesPage> {
  var size = Size.medium;
  var oat = false;
  var extra = true;
  var sugar = 1.0;
  String? milk = '{w_whole}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        children: [
          // {w_c_segment}
          SegmentedButton<Size>(
            segments: const [
              ButtonSegment(value: Size.small, label: Text('{w_small}')),
              ButtonSegment(value: Size.medium, label: Text('{w_medium}')),
              ButtonSegment(value: Size.large, label: Text('{w_large}')),
            ],
            selected: {size},
            onSelectionChanged: (s) => setState(() => size = s.first),
          ),
          // {w_c_check}
          CheckboxListTile(
            title: const Text('{w_oat}'),
            value: oat,
            onChanged: (v) => setState(() => oat = v!),
          ),
          CheckboxListTile(
            title: const Text('{w_extra}'),
            value: extra,
            onChanged: (v) => setState(() => extra = v!),
          ),
          // {w_c_slider}
          ListTile(title: Text('{w_sugar}: ${sugar.round()}')),
          Slider(
            value: sugar,
            max: 4,
            divisions: 4,
            label: '${sugar.round()}',
            onChanged: (v) => setState(() => sugar = v),
          ),
          // {w_c_dropdown}
          DropdownMenu<String>(
            label: const Text('{w_milk}'),
            initialSelection: milk,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => milk = v),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: '{w_whole}', label: '{w_whole}'),
              DropdownMenuEntry(value: '{w_skimmed}', label: '{w_skimmed}'),
              DropdownMenuEntry(value: '{w_oat}', label: '{w_oat}'),
              DropdownMenuEntry(value: '{w_none}', label: '{w_none}'),
            ],
          ),
        ],
      ),
    );
  }
}
""",
    "lib/order_form.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const OrderForm()));
}

enum Size {
  small(35, '{w_small}'),
  medium(45, '{w_medium}'),
  large(55, '{w_large}');

  final int price;
  final String label;
  const Size(this.price, this.label);
}

class OrderForm extends StatefulWidget {
  const OrderForm({super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final notes = TextEditingController();
  var size = Size.medium;
  var extraShot = false;
  var cups = 1;

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    super.dispose();
  }

  // {w_c_price}
  int get total => (size.price + (extraShot ? 10 : 0)) * cups;

  Future<void> place() async {
    if (!formKey.currentState!.validate()) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('{w_summary} ${name.text.trim()}'),
        content: Text('$cups × ${size.label}${extraShot ? ' + {w_extra}' : ''}\\n{w_total}: $total {w_egp}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('{w_ok}'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_order}')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '{w_name}', border: OutlineInputBorder()),
              validator: (v) => (v ?? '').trim().isEmpty ? '{w_required}' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<Size>(
              segments: const [
                ButtonSegment(value: Size.small, label: Text('{w_small}')),
                ButtonSegment(value: Size.medium, label: Text('{w_medium}')),
                ButtonSegment(value: Size.large, label: Text('{w_large}')),
              ],
              selected: {size},
              onSelectionChanged: (s) => setState(() => size = s.first),
            ),
            SwitchListTile(
              title: const Text('{w_extra} (+10)'),
              value: extraShot,
              onChanged: (v) => setState(() => extraShot = v),
            ),
            ListTile(
              title: const Text('{w_qty}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: cups > 1 ? () => setState(() => cups--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$cups', style: const TextStyle(fontSize: 18)),
                  IconButton(onPressed: () => setState(() => cups++), icon: const Icon(Icons.add)),
                ],
              ),
            ),
            TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '{w_notes}',
                hintText: '{w_notes_hint}',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: place, child: Text('{w_place} · $total {w_egp}')),
          ],
        ),
      ),
    );
  }
}
""",
    "test/order_form_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_form.dart';

void main() {
  testWidgets('{w_t_order}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderForm()));
    expect(find.text('{w_place} · 45 {w_egp}'), findsOneWidget);

    await tester.tap(find.text('{w_large}'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('{w_place} · 130 {w_egp}'), findsOneWidget);

    await tester.tap(find.text('{w_place} · 130 {w_egp}'));
    await tester.pump();
    expect(find.text('{w_required}'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '{w_order_name}');
    await tester.tap(find.text('{w_place} · 130 {w_egp}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_summary} {w_order_name}'), findsOneWidget);
  });
}
""",
    # Projects
    "projects/tip.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const TipPage()));
}

class TipPage extends StatefulWidget {
  const TipPage({super.key});

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  final bill = TextEditingController();
  double tip = 10;
  int people = 2;

  @override
  void dispose() {
    bill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(bill.text) ?? 0;
    final each = amount * (1 + tip / 100) / people;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          TextField(
            controller: bill,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '{w_bill}', suffixText: '{w_egp}', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('{w_tip}: ${tip.round()}%'),
          Slider(value: tip, max: 25, divisions: 5, label: '${tip.round()}%', onChanged: (v) => setState(() => tip = v)),
          Row(
            children: [
              Text('{w_per} $people {w_people}'),
              const Spacer(),
              IconButton(onPressed: people > 1 ? () => setState(() => people--) : null, icon: const Icon(Icons.remove)),
              IconButton(onPressed: () => setState(() => people++), icon: const Icon(Icons.add)),
            ],
          ),
          const Divider(height: 32),
          Text('{w_pay}', textAlign: TextAlign.center),
          Text(
            '${each.toStringAsFixed(2)} {w_egp}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }
}
""",
    "projects/signup.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const SignUpPage()));
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('{w_welcome}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_signup}')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: '{w_email}'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v ?? '').contains('@') ? null : '{w_email_bad}',
            ),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: '{w_password}'),
              validator: (v) => (v ?? '').length < 8 ? '{w_pw_short}' : null,
            ),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: '{w_confirm}'),
              validator: (v) => v == password.text ? null : '{w_pw_match}',
            ),
            FormField<bool>(
              initialValue: false,
              validator: (v) => v == true ? null : '{w_terms_needed}',
              builder: (field) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('{w_terms}'),
                value: field.value,
                onChanged: field.didChange,
                subtitle: field.hasError
                    ? Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: submit, child: const Text('{w_signup}')),
          ],
        ),
      ),
    );
  }
}
""",
    "test/signup_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_signup.dart';

void main() {
  testWidgets('{w_t_signup}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'sara@example.com');
    await tester.enterText(fields.at(1), 'coffee2026');
    await tester.enterText(fields.at(2), 'coffee2025');
    await tester.tap(find.widgetWithText(FilledButton, '{w_signup}'));
    await tester.pump();
    expect(find.text('{w_pw_match}'), findsOneWidget);
    expect(find.text('{w_terms_needed}'), findsOneWidget);

    await tester.enterText(fields.at(2), 'coffee2026');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.widgetWithText(FilledButton, '{w_signup}'));
    await tester.pump();
    expect(find.text('{w_welcome}'), findsOneWidget);
  });
}
""",
    "projects/search.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const SearchPage()));
}

final drinks = '{w_drinks}'.split(',');

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = query.text.trim().toLowerCase();
    final found = [for (final d in drinks) if (d.toLowerCase().contains(words)) d];
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '{w_search}',
            border: InputBorder.none,
            suffixIcon: query.text.isEmpty
                ? null
                : IconButton(tooltip: '{w_clear}', icon: const Icon(Icons.clear), onPressed: () => setState(query.clear)),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: found.isEmpty
          ? const Center(child: Text('{w_no_results}'))
          : ListView(children: [for (final d in found) ListTile(leading: const Icon(Icons.local_cafe), title: Text(d))]),
    );
  }
}
""",
    "test/search_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_search.dart';

void main() {
  testWidgets('{w_t_search}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    expect(find.byType(ListTile), findsNWidgets(drinks.length));

    await tester.enterText(find.byType(TextField), '{w_query}');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('{w_no_results}'), findsOneWidget);
  });
}
""",
}

SHOTS = [
    ("hello-empty.png", "lib/hello.dart", ""),
    ("hello-typed.png", "lib/hello.dart", "type={w_name}=>{w_typed}"),
    ("keyboards.png", "lib/keyboards.dart", "type={w_password}=>coffee2026|button={w_show}"),
    ("form-errors.png", "lib/form.dart", "button={w_send}"),
    ("choices.png", "lib/choices.dart", ""),
    ("order-form.png", "lib/order_form.dart", "type={w_name}=>{w_order_name}|button={w_large}"),
    ("order-summary.png", "lib/order_form.dart", "type={w_name}=>{w_order_name}|button={w_large}|button={w_place} · 55 {w_egp}"),
    ("tip.png", "projects/tip.dart", "at=150,76|keys=360"),
    ("signup.png", "projects/signup.dart", "button={w_signup}"),
    ("search.png", "projects/search.dart", "type={w_search}=>{w_query}"),
]

TESTS = [
    ("form-test.sh", "test/form_test.dart"),
    ("order-form-test.sh", "test/order_form_test.dart"),
    ("projects/signup-test.sh", "test/signup_test.dart"),
    ("projects/search-test.sh", "test/search_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)


if __name__ == "__main__":
    main()
