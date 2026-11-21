"""Writes the examples of Book 5, chapter "Everything Is a Widget", in English and Arabic, photographs them,
and runs their tests.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; takes a few minutes)

Every example is a small app with its own main(), as the reader writes it in lib/main.dart. Screenshots are
release builds in a browser at phone size, after real taps where the caption says so (see kit.flutter_gallery).
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_cafe="Bit Café", w_open="Open every day", w_hours="8:00 to 22:00",
        w_c_tree="A Column puts its children one under the other.",
        w_title="Special of the day", w_desc="A latte with oat milk and a slice of honey cake, served all day long at the counter or at your table.",
        w_c_style="Size, weight and colour: everything a text looks like is in its TextStyle.",
        w_c_overflow="Two lines at most, then three dots.",
        w_price="45 EGP",
        w_c_container="A Container: size, space inside and out, and a decoration.",
        w_c_deco="Rounded corners, a border and a soft shadow.",
        w_box="A box with style", w_inside="padding inside, margin outside",
        w_order="Order now", w_menu="See the menu", w_later="Maybe later", w_soon="Coming soon",
        w_c_disabled="onPressed: null turns a button off: it is drawn greyed out.",
        w_c_row="A Row puts its children side by side.",
        w_c_own="Our own widget: an icon and a text, used three times.",
        w_phone="0100 123 4567", w_email="hello@bitcafe.example", w_address="12 Nile Street, Cairo",
        w_contact="Contact us",
        w_c_stateful="A StatefulWidget: the widget, and a State object that remembers.",
        w_c_setstate="setState: change the value, then Flutter calls build again.",
        w_likes="likes", w_like="Like",
        w_c_theme="Colours and text sizes come from the theme, not from each widget.",
        w_welcome="Welcome back", w_points="You have 120 points",
        w_t_like="tapping the heart adds a like",
        # The café card
        w_latte="Latte", w_latte_desc="Espresso with steamed milk", w_c_qty="How many the customer wants: starts at 1.",
        w_add="Add to order", w_total="Total",
        w_c_minus="The minus button is off at 1: no zero or negative cups.",
        w_t_card="the quantity changes the total",
        # Projects
        w_name="Sara Ahmed", w_job="Flutter developer", w_city="Cairo, Egypt",
        w_c_card="Card: a surface with rounded corners and a shadow.",
        w_light="Traffic light", w_next="Next", w_stop="Stop", w_ready="Get ready", w_go="Go",
        w_c_lights="The three lamps, in order; the one that is on is bright.",
        w_t_light="the button moves to the next light",
        w_rate="Rate your coffee", w_c_star="One star widget per value, 1 to 5.",
        w_c_callback="The widget tells its parent about a new rating through onChanged.",
        w_of5="out of 5", w_no_rating="Tap a star", w_t_stars="tapping the fourth star gives 4",
        # Answers
        w_cups="cups",
        w_rtl="",
    ),
    "ar": dict(
        w_cafe="مقهى بِت", w_open="مفتوح كل يوم", w_hours="من 8:00 إلى 22:00",
        w_c_tree="Column يضع أبناءه واحداً تحت الآخر.",
        w_title="عرض اليوم", w_desc="لاتيه بحليب الشوفان وقطعة من كيك العسل، تُقدَّم طوال اليوم على المنضدة أو على طاولتك.",
        w_c_style="الحجم والسُّمك واللون: كل ما يخص شكل النص في TextStyle.",
        w_c_overflow="سطران على الأكثر، ثم ثلاث نقاط.",
        w_price="45 جنيهاً",
        w_c_container="Container: الحجم، والمسافة داخله وخارجه، والزخرفة.",
        w_c_deco="زوايا مستديرة، وإطار، وظل خفيف.",
        w_box="صندوق أنيق", w_inside="حشوة في الداخل، وهامش في الخارج",
        w_order="اطلب الآن", w_menu="اعرض القائمة", w_later="ربما لاحقاً", w_soon="قريباً",
        w_c_disabled="onPressed: null تطفئ الزر: فيُرسم باهتاً.",
        w_c_row="Row يضع أبناءه جنباً إلى جنب.",
        w_c_own="Widget من صنعنا: أيقونة ونص، يُستخدم ثلاث مرات.",
        w_phone="01001234567", w_email="hello@bitcafe.example", w_address="12 شارع النيل، القاهرة",
        w_contact="تواصل معنا",
        w_c_stateful="StatefulWidget: الـ Widget، وكائن State يتذكر.",
        w_c_setstate="setState: غيّر القيمة، ثم يستدعي Flutter دالة build من جديد.",
        w_likes="إعجاب", w_like="أعجبني",
        w_c_theme="الألوان وأحجام النص تأتي من السمة، لا من كل Widget.",
        w_welcome="أهلاً بعودتك", w_points="لديك 120 نقطة",
        w_t_like="الضغط على القلب يضيف إعجاباً",
        w_latte="لاتيه", w_latte_desc="إسبريسو بحليب مُبخَّر", w_c_qty="كم كوباً يريد الزبون: يبدأ من 1.",
        w_add="أضف إلى الطلب", w_total="الإجمالي",
        w_c_minus="زر الطرح مطفأ عند 1: لا أكواب صفرية ولا سالبة.",
        w_t_card="الكمية تغيّر الإجمالي",
        w_name="سارة أحمد", w_job="مطوّرة تطبيقات", w_city="القاهرة، مصر",
        w_c_card="Card: سطح بزوايا مستديرة وظل.",
        w_light="إشارة المرور", w_next="التالي", w_stop="قف", w_ready="استعد", w_go="انطلق",
        w_c_lights="المصابيح الثلاثة بالترتيب؛ والمضاء منها ساطع.",
        w_t_light="الزر ينقل إلى الضوء التالي",
        w_rate="قيّم قهوتك", w_c_star="Widget نجمة لكل قيمة، من 1 إلى 5.",
        w_c_callback="يخبر الـ Widget أباه بالتقييم الجديد عبر onChanged.",
        w_of5="من 5", w_no_rating="اضغط نجمة", w_t_stars="الضغط على النجمة الرابعة يعطي 4",
        w_cups="أكواب",
        # Arabic screens start from the right. Chapter 13 shows the complete way (languages, dates, numbers).
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
    ),
}

APP = """
void main() {{
  runApp(const {cls}());
}}
"""

FILES = {
    "lib/tree.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const CafeApp());
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_cafe}')),
        body: const Center(
          // {w_c_tree}
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_cafe, size: 80, color: Colors.brown),
              Text('{w_open}', style: TextStyle(fontSize: 24)),
              Text('{w_hours}'),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "lib/text.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const TextApp());
}

class TextApp extends StatelessWidget {
  const TextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              // {w_c_style}
              Text(
                '{w_title}',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              SizedBox(height: 8),
              // {w_c_overflow}
              Text(
                '{w_desc}',
                style: TextStyle(fontSize: 18, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                '{w_price}',
                style: TextStyle(fontSize: 22, color: Colors.teal, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "lib/box.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const BoxApp());
}

class BoxApp extends StatelessWidget {
  const BoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Center(
          // {w_c_container}
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            // {w_c_deco}
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('{w_box}', style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text('{w_inside}', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
""",
    "lib/buttons.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ButtonsApp());
}

class ButtonsApp extends StatelessWidget {
  const ButtonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              FilledButton(onPressed: () {}, child: const Text('{w_order}')),
              OutlinedButton(onPressed: () {}, child: const Text('{w_menu}')),
              TextButton(onPressed: () {}, child: const Text('{w_later}')),
              // {w_c_disabled}
              const FilledButton(onPressed: null, child: Text('{w_soon}')),
              // {w_c_row}
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
                  IconButton.filled(onPressed: () {}, icon: const Icon(Icons.add)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "lib/contact.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ContactApp());
}

// {w_c_own}
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_contact}')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              InfoRow(icon: Icons.phone, text: '{w_phone}'),
              InfoRow(icon: Icons.email, text: '{w_email}'),
              InfoRow(icon: Icons.place, text: '{w_address}'),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "lib/like.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const LikePage()));
}

// {w_c_stateful}
class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  int likes = 0;

  void like() {
    // {w_c_setstate}
    setState(() {
      likes++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize: 72,
              tooltip: '{w_like}',
              onPressed: like,
              icon: Icon(
                likes > 0 ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
            ),
            Text('$likes {w_likes}', style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
""",
    "test/like_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/like.dart';

void main() {
  testWidgets('{w_t_like}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LikePage()));
    expect(find.text('0 {w_likes}'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.text('1 {w_likes}'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
""",
    "lib/theme.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemeApp());
}

class ThemeApp extends StatelessWidget {
  const ThemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      // {w_c_theme}
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_cafe}'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('{w_welcome}', style: theme.textTheme.headlineMedium),
            Text(
              '{w_points}',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () {}, child: const Text('{w_order}')),
          ],
        ),
      ),
    );
  }
}
""",
    "lib/cafe_card.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: DrinkCard(name: '{w_latte}', description: '{w_latte_desc}', price: 45))),
    ),
  );
}

class DrinkCard extends StatefulWidget {
  const DrinkCard({super.key, required this.name, required this.description, required this.price});

  final String name;
  final String description;
  final int price;

  @override
  State<DrinkCard> createState() => _DrinkCardState();
}

class _DrinkCardState extends State<DrinkCard> {
  // {w_c_qty}
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.coffee, size: 48, color: Colors.brown),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(widget.description),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // {w_c_minus}
                IconButton.outlined(
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$quantity', style: const TextStyle(fontSize: 24)),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => quantity++),
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  '{w_total}: ${widget.price * quantity}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag),
                label: const Text('{w_add}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "test/cafe_card_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_card.dart';

void main() {
  testWidgets('{w_t_card}', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DrinkCard(name: 'X', description: 'Y', price: 45))),
    );
    expect(find.text('{w_total}: 45'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('{w_total}: 135'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('{w_total}: 90'), findsOneWidget);
  });
}
""",
    # Projects
    "projects/business_card.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const BusinessCardApp());
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class BusinessCardApp extends StatelessWidget {
  const BusinessCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: Center(
          // {w_c_card}
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
                  const SizedBox(height: 12),
                  const Text('{w_name}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text('{w_job}', style: TextStyle(color: Colors.grey.shade700)),
                  const Divider(height: 32),
                  const InfoRow(icon: Icons.phone, text: '{w_phone}'),
                  const InfoRow(icon: Icons.email, text: '{w_email}'),
                  const InfoRow(icon: Icons.place, text: '{w_city}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
""",
    "projects/traffic_light.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const TrafficLight()));
}

class TrafficLight extends StatefulWidget {
  const TrafficLight({super.key});

  @override
  State<TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<TrafficLight> {
  int current = 0;

  // {w_c_lights}
  static const colors = [Colors.red, Colors.amber, Colors.green];
  static const labels = ['{w_stop}', '{w_ready}', '{w_go}'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_light}')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == current ? colors[i] : colors[i].withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(labels[current], style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => current = (current + 1) % 3),
              child: const Text('{w_next}'),
            ),
          ],
        ),
      ),
    );
  }
}
""",
    "test/traffic_light_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_traffic_light.dart';

void main() {
  testWidgets('{w_t_light}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrafficLight()));
    expect(find.text('{w_stop}'), findsOneWidget);
    for (final label in ['{w_ready}', '{w_go}', '{w_stop}']) {
      await tester.tap(find.text('{w_next}'));
      await tester.pump();
      expect(find.text(label), findsOneWidget);
    }
  });
}
""",
    "projects/stars.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const RatePage()));
}

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, required this.onChanged});

  final int value;
  // {w_c_callback}
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // {w_c_star}
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: 40,
            onPressed: () => onChanged(i),
            icon: Icon(i <= value ? Icons.star : Icons.star_border, color: Colors.amber),
          ),
      ],
    );
  }
}

class RatePage extends StatefulWidget {
  const RatePage({super.key});

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('{w_rate}', style: TextStyle(fontSize: 24)),
            StarRating(value: rating, onChanged: (v) => setState(() => rating = v)),
            Text(rating == 0 ? '{w_no_rating}' : '$rating {w_of5}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
""",
    "test/stars_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_stars.dart';

void main() {
  testWidgets('{w_t_stars}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RatePage()));
    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pump();
    expect(find.text('4 {w_of5}'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });
}
""",
}

SHOTS = [
    ("tree.png", "lib/tree.dart", ""),
    ("text.png", "lib/text.dart", ""),
    ("box.png", "lib/box.dart", ""),
    ("buttons.png", "lib/buttons.dart", ""),
    ("contact.png", "lib/contact.dart", ""),
    ("like-0.png", "lib/like.dart", ""),
    ("like-3.png", "lib/like.dart", "195,354 195,354 195,354"),
    ("theme.png", "lib/theme.dart", ""),
    ("cafe-card.png", "lib/cafe_card.dart", ""),
    ("business-card.png", "projects/business_card.dart", ""),
    ("traffic-light.png", "projects/traffic_light.dart", ""),
    ("stars.png", "projects/stars.dart", ""),
]

TESTS = [
    ("like-test.sh", "test/like_test.dart"),
    ("cafe-card-test.sh", "test/cafe_card_test.dart"),
    ("projects/traffic-light-test.sh", "test/traffic_light_test.dart"),
    ("projects/stars-test.sh", "test/stars_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)


if __name__ == "__main__":
    main()
