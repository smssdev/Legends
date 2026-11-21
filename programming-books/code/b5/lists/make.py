"""Writes the examples of Book 5, chapter "Lists, Images and Themes", in English and Arabic, photographs them,
and runs their tests.
Run: python3 draw.py (once, for the pictures), then python3 make.py   (needs Flutter 3.50.1, Node.js and
Playwright's Chromium; takes a few minutes)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="", w_comma=",",
        w_cafe="Bit Café", w_egp="EGP",
        w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake", w_cookie="Cookie", w_juice="Orange juice",
        w_muffin="Muffin",
        w_latte_d="Espresso and steamed milk", w_tea_d="Black tea with fresh mint", w_cake_d="Sponge, jam and cream",
        w_cookie_d="With chocolate chips", w_juice_d="Freshly squeezed", w_muffin_d="Chocolate, baked today",
        w_c_tiles="ListView: a column that scrolls when its children do not fit.",
        w_hours="Opening hours", w_hours_d="Every day, 8:00 to 22:00", w_address="Address",
        w_address_d="12 Nile Street, Cairo", w_wifi="Wi-Fi", w_wifi_d="Free for customers",
        w_order="Order", w_order_no="Order #", w_thousand="1,000 orders", w_c_builder="builder: Flutter asks for item i only when it is about to be seen.",
        w_t_built="only the visible items are built",
        w_c_model="The data: one object per drink, in a const list.",
        w_c_sep="separated: a Divider between two items, never after the last one.",
        w_c_fav="Which drinks the customer likes: a Set, each name once.",
        w_c_asset="A picture from the app itself, declared in pubspec.yaml.",
        w_c_grid="As many columns as fit, each at most 200 pixels wide.",
        w_c_fit="BoxFit.cover fills the box and crops what does not fit.",
        w_c_network="A picture from the internet, with what to show while it loads and if it fails.",
        w_t_network="a picture that cannot load shows the fallback",
        w_c_themes="Two themes from the same seed: one light, one dark.",
        w_dark="Dark mode", w_c_mode="themeMode chooses which of the two is used.",
        w_menu="Menu", w_fav="favourites",
        # Projects
        w_names="Sara Ahmed,Omar Khaled,Mona Adel,Ahmed Samir,Laila Hassan,Youssef Nabil,Hana Mostafa,Karim Fathy",
        w_contacts="Contacts", w_selected="selected", w_photos="Photos",
        w_list="Shopping list", w_items="Milk,Coffee beans,Sugar,Cups,Napkins,Oranges",
        w_removed="removed", w_undo="Undo", w_c_dismiss="Swipe an item away to remove it; the snack bar can bring it back.",
        w_t_swipe="swiping removes an item, and Undo brings it back",
    ),
    "ar": dict(
        w_comma="،",
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_cafe="مقهى بِت", w_egp="جنيه",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز", w_cookie="كوكيز", w_juice="عصير برتقال",
        w_muffin="مافن",
        w_latte_d="إسبريسو وحليب مُبخَّر", w_tea_d="شاي أسود بنعناع طازج", w_cake_d="إسفنج ومربى وكريمة",
        w_cookie_d="بقطع الشوكولاتة", w_juice_d="معصور طازجاً", w_muffin_d="بالشوكولاتة، مخبوز اليوم",
        w_c_tiles="ListView: عمود يتمرر حين لا يتسع لأبنائه.",
        w_hours="مواعيد العمل", w_hours_d="كل يوم، من 8:00 إلى 22:00", w_address="العنوان",
        w_address_d="12 شارع النيل، القاهرة", w_wifi="واي فاي", w_wifi_d="مجاني للزبائن",
        w_order="طلب", w_order_no="طلب رقم ", w_thousand="1000 طلب", w_c_builder="builder: يطلب Flutter العنصر i فقط حين يوشك أن يظهر.",
        w_t_built="لا تُبنى إلا العناصر الظاهرة",
        w_c_model="البيانات: كائن لكل مشروب، في قائمة const.",
        w_c_sep="separated: فاصل بين كل عنصرين، ولا فاصل بعد الأخير.",
        w_c_fav="المشروبات التي يحبها الزبون: Set، كل اسم مرة واحدة.",
        w_c_asset="صورة من التطبيق نفسه، مذكورة في pubspec.yaml.",
        w_c_grid="عدد الأعمدة الذي يتسع، كل منها بعرض 200 بكسل على الأكثر.",
        w_c_fit="BoxFit.cover تملأ الصندوق وتقص ما لا يتسع.",
        w_c_network="صورة من الإنترنت، مع ما يُعرض أثناء تحميلها وإن فشلت.",
        w_t_network="الصورة التي لا تُحمَّل تُظهر البديل",
        w_c_themes="سمتان من البذرة نفسها: فاتحة وداكنة.",
        w_dark="الوضع الداكن", w_c_mode="themeMode تختار أيهما يُستخدم.",
        w_menu="القائمة", w_fav="مفضلة",
        w_names="سارة أحمد,عمر خالد,منى عادل,أحمد سمير,ليلى حسن,يوسف نبيل,هنا مصطفى,كريم فتحي",
        w_contacts="جهات الاتصال", w_selected="محددة", w_photos="الصور",
        w_list="قائمة المشتريات", w_items="حليب,حبوب قهوة,سكر,أكواب,مناديل,برتقال",
        w_removed="حُذف", w_undo="تراجع", w_c_dismiss="اسحب العنصر جانباً لحذفه؛ والشريط السفلي يستطيع إعادته.",
        w_t_swipe="السحب يحذف العنصر، وزر التراجع يعيده",
    ),
}

DRINKS = """
class Drink {
  const Drink(this.name, this.description, this.price, this.image);

  final String name;
  final String description;
  final int price;
  final String image;
}

// {w_c_model}
const drinks = [
  Drink('{w_latte}', '{w_latte_d}', 45, 'assets/images/latte.png'),
  Drink('{w_tea}', '{w_tea_d}', 25, 'assets/images/tea.png'),
  Drink('{w_juice}', '{w_juice_d}', 40, 'assets/images/juice.png'),
  Drink('{w_cake}', '{w_cake_d}', 60, 'assets/images/cake.png'),
  Drink('{w_cookie}', '{w_cookie_d}', 20, 'assets/images/cookie.png'),
  Drink('{w_muffin}', '{w_muffin_d}', 35, 'assets/images/muffin.png'),
];
"""

FILES = {
    "lib/tiles.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_cafe}')),
        // {w_c_tiles}
        body: ListView(
          children: const [
            ListTile(leading: Icon(Icons.schedule), title: Text('{w_hours}'), subtitle: Text('{w_hours_d}')),
            ListTile(leading: Icon(Icons.place), title: Text('{w_address}'), subtitle: Text('{w_address_d}')),
            ListTile(
              leading: Icon(Icons.wifi),
              title: Text('{w_wifi}'),
              subtitle: Text('{w_wifi_d}'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    ),
  );
}
""",
    "lib/builder.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_thousand}')),
        // {w_c_builder}
        body: ListView.builder(
          itemCount: 1000,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('{w_order_no}${i + 1}'),
            subtitle: Text('${(i * 37) % 200 + 20} {w_egp}'),
          ),
        ),
      ),
    ),
  );
}
""",
    "test/builder_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('{w_t_built}', (tester) async {
    final built = <int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, i) {
              built.add(i);
              return ListTile(title: Text('{w_order_no}${i + 1}'));
            },
          ),
        ),
      ),
    );
    debugPrint('built ${built.length} of 1000');

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    debugPrint('after scrolling: built ${built.length} of 1000');
    expect(built.length, lessThan(100));
  });
}
""",
    "lib/menu.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const MenuPage()));
}
""" + DRINKS + """
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // {w_c_fav}
  final favourites = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('{w_menu} · ${favourites.length} {w_fav}')),
      // {w_c_sep}
      body: ListView.separated(
        itemCount: drinks.length,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final drink = drinks[i];
          final liked = favourites.contains(drink.name);
          return ListTile(
            // {w_c_asset}
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(drink.image, width: 64, height: 48, fit: BoxFit.cover),
            ),
            title: Text(drink.name),
            subtitle: Text('${drink.description} · ${drink.price} {w_egp}'),
            trailing: IconButton(
              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              onPressed: () => setState(() {
                liked ? favourites.remove(drink.name) : favourites.add(drink.name);
              }),
            ),
          );
        },
      ),
    );
  }
}
""",
    "lib/grid.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_menu}')),
        // {w_c_grid}
        body: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: drinks.length,
          itemBuilder: (context, i) => Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // {w_c_fit}
                Expanded(child: Image.asset(drinks[i].image, fit: BoxFit.cover)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(drinks[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text('${drinks[i].price} {w_egp}'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
""" + DRINKS,
    "lib/network.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const Scaffold(body: Center(child: Photo()))));
}

class Photo extends StatelessWidget {
  const Photo({super.key, this.url = 'https://example.com/latte.png'});

  final String url;

  @override
  Widget build(BuildContext context) {
    // {w_c_network}
    return Image.network(
      url,
      width: 240,
      height: 180,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SizedBox(width: 240, height: 180, child: Center(child: CircularProgressIndicator())),
      errorBuilder: (context, error, stack) => Container(
        width: 240,
        height: 180,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
""",
    "test/network_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/network.dart';

void main() {
  testWidgets('{w_t_network}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Photo()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
""",
    "lib/themes.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemesApp());
}

class ThemesApp extends StatefulWidget {
  const ThemesApp({super.key});

  @override
  State<ThemesApp> createState() => _ThemesAppState();
}

class _ThemesAppState extends State<ThemesApp> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      {w_rtl}debugShowCheckedModeBanner: false,
      // {w_c_themes}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(colorSchemeSeed: Colors.brown, brightness: Brightness.dark),
      // {w_c_mode}
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_cafe}')),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('{w_dark}'),
              secondary: const Icon(Icons.dark_mode),
              value: dark,
              onChanged: (value) => setState(() => dark = value),
            ),
            const Divider(),
            for (final drink in drinks)
              ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
                title: Text(drink.name),
                trailing: Text('${drink.price} {w_egp}'),
              ),
          ],
        ),
      ),
    );
  }
}
""" + DRINKS,
    # Projects
    "projects/contacts.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const ContactsPage()));
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final names = '{w_names}'.split(',')..sort();
    return Scaffold(
      appBar: AppBar(title: Text('{w_contacts} (${names.length})')),
      body: ListView.separated(
        itemCount: names.length,
        separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.primaries[i % Colors.primaries.length].shade100,
            child: Text(names[i][0]),
          ),
          title: Text(names[i]),
          trailing: const Icon(Icons.call),
        ),
      ),
    );
  }
}
""",
    "projects/gallery.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const GalleryPage()));
}

const photos = ['latte', 'tea', 'juice', 'cake', 'cookie', 'muffin'];

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(selected.isEmpty ? '{w_photos}' : '${selected.length} {w_selected}'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(8),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var i = 0; i < photos.length; i++)
            GestureDetector(
              onTap: () => setState(() => selected.contains(i) ? selected.remove(i) : selected.add(i)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/${photos[i]}.png', fit: BoxFit.cover),
                  ),
                  if (selected.contains(i)) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.primary, width: 4),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primary,
                        child: Icon(Icons.check, size: 18, color: scheme.onPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
""",
    "projects/shopping.dart": """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const ShoppingPage()));
}

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final items = '{w_items}'.split(',');

  // {w_c_dismiss}
  void remove(int index) {
    final item = items[index];
    setState(() => items.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$item {w_removed}'),
        action: SnackBarAction(
          label: '{w_undo}',
          onPressed: () => setState(() => items.insert(index, item)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('{w_list} (${items.length})')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) => Dismissible(
          key: ValueKey(items[i]),
          background: Container(
            color: Colors.red,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => remove(i),
          child: ListTile(leading: const Icon(Icons.shopping_basket), title: Text(items[i])),
        ),
      ),
    );
  }
}
""",
    "test/shopping_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_shopping.dart';

void main() {
  testWidgets('{w_t_swipe}', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShoppingPage()));
    final first = '{w_items}'.split(',').first;
    expect(find.text(first), findsOneWidget);

    await tester.drag(find.text(first), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text(first), findsNothing);

    await tester.tap(find.text('{w_undo}'));
    await tester.pumpAndSettle();
    expect(find.text(first), findsOneWidget);
  });
}
""",
}

SHOTS = [
    ("tiles.png", "lib/tiles.dart", ""),
    ("builder.png", "lib/builder.dart", ""),
    ("menu.png", "lib/menu.dart", "{w_fav_taps}"),
    ("grid-phone.png", "lib/grid.dart", ""),
    ("grid-tablet.png", "lib/grid.dart", "", "820x540"),
    ("themes-light.png", "lib/themes.dart", ""),
    ("themes-dark.png", "lib/themes.dart", "195,88"),
    ("contacts.png", "projects/contacts.dart", ""),
    ("gallery.png", "projects/gallery.dart", "100,160 290,350"),
    ("shopping.png", "projects/shopping.dart", ""),
]
# The heart buttons are at the end of each row: on the right in English, on the left in Arabic.
T["en"]["w_fav_taps"] = "362,92 362,236"
T["ar"]["w_fav_taps"] = "28,88 28,218"

TESTS = [
    ("builder-test.sh", "test/builder_test.dart"),
    ("network-test.sh", "test/network_test.dart"),
    ("projects/shopping-test.sh", "test/shopping_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, assets=HERE / "assets")


if __name__ == "__main__":
    main()
