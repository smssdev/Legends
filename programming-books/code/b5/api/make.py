"""Writes the examples of Book 5, chapter "Talking to an API", in English and Arabic: a small café server in
plain Dart (server/server.dart), and apps that talk to it with the http package. For each language the server
really runs while the screenshots and the curl sessions are recorded; the tests use MockClient, because
widget tests never reach a network.
Run: python3 make.py   (needs Flutter 3.50.1, curl, Node.js and Playwright's Chromium; downloads http and
provider once)
"""
import os
import shutil
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import WORK, Session, fill, flutter_gallery, popen, sh, write  # noqa: E402

PICTURES = HERE.parent / "lists" / "assets" / "images"

T = {
    "en": dict(
        w_rtl="", w_egp="EGP", w_menu="Menu", w_comma=",",
        w_latte="Latte", w_tea="Mint tea", w_juice="Orange juice", w_cake="Cherry cake", w_cookie="Cookie",
        w_muffin="Muffin",
        w_serving="Serving the café on", w_no_drink="No drink", w_no_name="A name is needed",
        w_no_items="The order is empty", w_broken="The kitchen is on fire", w_not_found="Not found",
        w_c_server="A whole server in one file of plain Dart: run it with dart run server.dart.",
        w_c_slow="A real network is never instant: wait half a second.",
        w_c_cors="Let pages from other addresses (the app in a browser) read the answers.",
        w_c_check="Never trust what arrives: check it, and say what is wrong.",
        w_c_fromjson="One drink from its JSON: a named constructor, as in Chapter 3.",
        w_c_api="Everything about the server in one class; the client is given, so tests can give a fake one.",
        w_c_status="Anything but 200 is a failure, with the server's own message.",
        w_c_model="The screen asks the model; the model asks the API.",
        w_c_states="Three states, one at a time: loading, ready, failed.",
        w_c_future="FutureBuilder shows each moment of a Future: waiting, an error, or the data.",
        w_loading="Loading the menu…", w_failed="Could not load the menu", w_retry="Try again",
        w_order="Order", w_placed="Order placed", w_t_api="the menu is parsed, and a failure says why",
        w_t_app="the menu loads, and a failure offers to try again",
        w_c_refresh="Pull down to load again.",
        w_c_imgerr="A picture that fails to load leaves the plain circle, not an error.",
        # Projects
        w_special="Drink of the day", w_t_post="the message from the server is shown",
        w_your_name="Your name", w_send="Send order",
        w_search="Search the menu", w_t_search="the search waits until typing stops",
        w_c_debounce="Wait 400 milliseconds after the last key before asking the server.",
        w_none="No drink matches",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_egp="جنيه", w_menu="القائمة", w_comma="،",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_juice="عصير برتقال", w_cake="كيك الكرز", w_cookie="كوكيز",
        w_muffin="مافن",
        w_serving="يخدم المقهى على", w_no_drink="لا مشروب برقم", w_no_name="الاسم مطلوب",
        w_no_items="الطلب فارغ", w_broken="المطبخ يحترق", w_not_found="غير موجود",
        w_c_server="خادم كامل في ملف واحد من Dart الخالصة: شغّله بـ dart run server.dart.",
        w_c_slow="الشبكة الحقيقية ليست فورية أبداً: انتظر نصف ثانية.",
        w_c_cors="اسمح للصفحات من عناوين أخرى (التطبيق في المتصفح) بقراءة الإجابات.",
        w_c_check="لا تثق أبداً بما يصل: افحصه، وقل ما الخطأ فيه.",
        w_c_fromjson="مشروب واحد من الـ JSON الخاص به: مُنشئ مسمى، كما في الفصل 3.",
        w_c_api="كل ما يخص الخادم في صنف واحد؛ والعميل يُعطى له، لتعطيه الاختبارات عميلاً مزيفاً.",
        w_c_status="كل ما عدا 200 فشل، برسالة الخادم نفسه.",
        w_c_model="الشاشة تسأل النموذج؛ والنموذج يسأل الواجهة البرمجية.",
        w_c_states="ثلاث حالات، واحدة في كل مرة: تحميل، وجاهز، وفشل.",
        w_c_future="FutureBuilder تعرض كل لحظة من Future: الانتظار، أو الخطأ، أو البيانات.",
        w_loading="جارٍ تحميل القائمة…", w_failed="تعذّر تحميل القائمة", w_retry="أعد المحاولة",
        w_order="اطلب", w_placed="أُرسل الطلب", w_t_api="القائمة تُحلَّل، والفشل يقول لماذا",
        w_t_app="القائمة تُحمَّل، والفشل يعرض إعادة المحاولة",
        w_c_refresh="اسحب إلى الأسفل لتحمّل من جديد.",
        w_c_imgerr="الصورة التي يفشل تحميلها تترك الدائرة فارغة، لا خطأ.",
        w_special="مشروب اليوم", w_t_post="تُعرض رسالة الخادم",
        w_your_name="اسمك", w_send="أرسل الطلب",
        w_search="ابحث في القائمة", w_t_search="البحث ينتظر حتى تتوقف الكتابة",
        w_c_debounce="انتظر 400 جزء من الثانية بعد آخر حرف قبل أن تسأل الخادم.",
        w_none="لا مشروب مطابق",
    ),
}

SERVER = """import 'dart:convert';
import 'dart:io';

// {w_c_server}
const menu = [
  {'id': 1, 'name': '{w_latte}', 'price': 45, 'image': 'latte'},
  {'id': 2, 'name': '{w_tea}', 'price': 25, 'image': 'tea'},
  {'id': 3, 'name': '{w_juice}', 'price': 40, 'image': 'juice'},
  {'id': 4, 'name': '{w_cake}', 'price': 60, 'image': 'cake'},
  {'id': 5, 'name': '{w_cookie}', 'price': 20, 'image': 'cookie'},
  {'id': 6, 'name': '{w_muffin}', 'price': 35, 'image': 'muffin'},
];

var nextOrder = 1;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('{w_serving} http://localhost:${server.port}');
  await for (final request in server) {
    await handle(request);
    print('${request.method} ${request.uri} -> ${request.response.statusCode}');
  }
}

Future<void> handle(HttpRequest request) async {
  final response = request.response;
  // {w_c_cors}
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
  final path = request.uri.path;
  final parts = path.split('/');

  if (request.method == 'OPTIONS') {
    await response.close();
  } else if (path.startsWith('/images/')) {
    final file = File('images/${parts.last}');
    if (await file.exists()) {
      response.headers.contentType = ContentType('image', 'png');
      await response.addStream(file.openRead());
      await response.close();
    } else {
      await send(response, 404, {'error': '{w_not_found}'});
    }
  } else if (request.method == 'GET' && path == '/menu') {
    // {w_c_slow}
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final q = (request.uri.queryParameters['q'] ?? '').toLowerCase();
    await send(response, 200, [
      for (final d in menu)
        if ((d['name'] as String).toLowerCase().contains(q)) d,
    ]);
  } else if (request.method == 'GET' && parts.length == 3 && parts[1] == 'menu') {
    final id = int.tryParse(parts[2]);
    final found = menu.where((d) => d['id'] == id);
    if (found.isEmpty) {
      await send(response, 404, {'error': '{w_no_drink} ${parts[2]}'});
    } else {
      await send(response, 200, found.first);
    }
  } else if (request.method == 'POST' && path == '/orders') {
    final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, Object?>;
    final name = (body['name'] as String? ?? '').trim();
    final items = (body['items'] as List<Object?>? ?? []).cast<int>();
    // {w_c_check}
    if (name.isEmpty) {
      await send(response, 400, {'error': '{w_no_name}'});
    } else if (items.isEmpty) {
      await send(response, 400, {'error': '{w_no_items}'});
    } else {
      final total = items.fold(0, (sum, id) => sum + (menu.firstWhere((d) => d['id'] == id)['price'] as int));
      await send(response, 201, {'id': nextOrder++, 'name': name, 'total': total});
    }
  } else if (path.startsWith('/broken')) {
    await send(response, 500, {'error': '{w_broken}'});
  } else {
    await send(response, 404, {'error': '{w_not_found}'});
  }
}

Future<void> send(HttpResponse response, int status, Object body) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(const JsonEncoder.withIndent('  ').convert(body));
  await response.close();
}
"""

FILES = {
    "lib/fetch.dart": """import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const MenuPage()));
}

Future<List<Map<String, dynamic>>> fetchMenu() async {
  final response = await http.get(Uri.parse('http://localhost:8080/menu'));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }
  return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final Future<List<Map<String, dynamic>>> menu = fetchMenu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      // {w_c_future}
      body: FutureBuilder(
        future: menu,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return ListView(
            children: [
              for (final drink in snapshot.data!)
                ListTile(title: Text(drink['name'] as String), trailing: Text('${drink['price']} {w_egp}')),
            ],
          );
        },
      ),
    );
  }
}
""",
    "lib/cafe_api.dart": """import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

class Drink {
  const Drink({required this.id, required this.name, required this.price, required this.image});

  // {w_c_fromjson}
  factory Drink.fromJson(Map<String, dynamic> json) => Drink(
    id: json['id'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    image: json['image'] as String,
  );

  final int id;
  final String name;
  final int price;
  final String image;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

// {w_c_api}
class CafeApi {
  CafeApi(this.client, {this.base = 'http://localhost:8080'});

  final http.Client client;
  final String base;

  String imageUrl(Drink d) => '$base/images/${d.image}.png';

  Future<List<Drink>> menu({String query = ''}) async {
    final uri = Uri.parse('$base/menu').replace(queryParameters: query.isEmpty ? null : {'q': query});
    final list = await _send(client.get(uri)) as List<dynamic>;
    return [for (final item in list) Drink.fromJson(item as Map<String, dynamic>)];
  }

  Future<Drink> drink(int id) async =>
      Drink.fromJson(await _send(client.get(Uri.parse('$base/menu/$id'))) as Map<String, dynamic>);

  Future<int> order(String name, List<int> items) async {
    final reply = await _send(
      client.post(
        Uri.parse('$base/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'items': items}),
      ),
    );
    return (reply as Map<String, dynamic>)['total'] as int;
  }

  Future<Object?> _send(Future<http.Response> request) async {
    final response = await request.timeout(const Duration(seconds: 10));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    // {w_c_status}
    if (response.statusCode >= 300) {
      throw ApiException((body as Map<String, dynamic>)['error'] as String? ?? 'HTTP ${response.statusCode}');
    }
    return body;
  }
}

enum Status { loading, ready, failed }

// {w_c_model}
class MenuModel extends ChangeNotifier {
  MenuModel(this.api);

  final CafeApi api;
  // {w_c_states}
  var status = Status.loading;
  var drinks = <Drink>[];
  String? error;

  Future<void> load() async {
    status = Status.loading;
    notifyListeners();
    try {
      drinks = await api.menu();
      status = Status.ready;
    } on Exception catch (e) {
      error = '$e';
      status = Status.failed;
    }
    notifyListeners();
  }
}
""",
    "lib/menu_app.dart": """import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'cafe_api.dart';

void main() => runApp(CafeApp(api: CafeApi(http.Client())));

class CafeApp extends StatelessWidget {
  const CafeApp({super.key, required this.api});

  final CafeApi api;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MenuModel(api)..load(),
      child: MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: const MenuPage()),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<void> order(BuildContext context, Drink drink) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final total = await context.read<MenuModel>().api.order('Bit', [drink.id]);
      messenger.showSnackBar(SnackBar(content: Text('{w_placed}: ${drink.name}{w_comma} $total {w_egp}')));
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MenuModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: switch (model.status) {
        Status.loading => const Center(child: CircularProgressIndicator()),
        Status.failed => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.cloud_off, size: 64),
              const Text('{w_failed}'),
              Text(model.error ?? ''),
              FilledButton(onPressed: model.load, child: const Text('{w_retry}')),
            ],
          ),
        ),
        // {w_c_refresh}
        Status.ready => RefreshIndicator(
          onRefresh: model.load,
          child: ListView(
            children: [
              for (final drink in model.drinks)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(model.api.imageUrl(drink)),
                    // {w_c_imgerr}
                    onBackgroundImageError: (error, stack) {},
                  ),
                  title: Text(drink.name),
                  subtitle: Text('${drink.price} {w_egp}'),
                  trailing: IconButton(
                    tooltip: '{w_order} ${drink.name}',
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () => order(context, drink),
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}
""",
    "lib/broken_app.dart": """import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';
import 'menu_app.dart';

// The same app, pointed at an address where the server answers 500.
void main() => runApp(CafeApp(api: CafeApi(http.Client(), base: 'http://localhost:8080/broken')));
""",
    "test/api_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/cafe_api.dart';

void main() {
  test('{w_t_api}', () async {
    final good = MockClient((request) async {
      expect(request.url.path, '/menu');
      return http.Response('[{"id": 1, "name": "{w_latte}", "price": 45, "image": "latte"}]', 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final drinks = await CafeApi(good).menu();
    expect(drinks.single.name, '{w_latte}');
    expect(drinks.single.price, 45);

    final bad = MockClient((request) async => http.Response('{"error": "{w_broken}"}', 500,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    expect(() => CafeApi(bad).menu(), throwsA(isA<ApiException>()));
  });
}
""",
    "test/menu_app_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_api.dart';
import 'package:bit_app/menu_app.dart';

void main() {
  testWidgets('{w_t_app}', (tester) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response('{"error": "{w_broken}"}', 500, headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return http.Response('[{"id": 2, "name": "{w_tea}", "price": 25, "image": "tea"}]', 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    await tester.pumpWidget(CafeApp(api: CafeApi(client)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('{w_broken}'), findsOneWidget);

    await tester.tap(find.text('{w_retry}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_tea}'), findsOneWidget);
  });
}
""",
    # Projects
    "projects/special.dart": """import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: SpecialPage(api: CafeApi(http.Client()))));
}

class SpecialPage extends StatefulWidget {
  const SpecialPage({super.key, required this.api, this.id = 3});

  final CafeApi api;
  final int id;

  @override
  State<SpecialPage> createState() => _SpecialPageState();
}

class _SpecialPageState extends State<SpecialPage> {
  late final Future<Drink> special = widget.api.drink(widget.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_special}')),
      body: Center(
        child: FutureBuilder(
          future: special,
          builder: (context, snapshot) => switch (snapshot) {
            AsyncSnapshot(:final error?) => Text('$error'),
            AsyncSnapshot(:final data?) => Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(widget.api.imageUrl(data), height: 200, fit: BoxFit.cover),
                  ListTile(
                    title: Text(data.name, style: Theme.of(context).textTheme.titleLarge),
                    trailing: Text('${data.price} {w_egp}'),
                  ),
                ],
              ),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
}
""",
    "projects/send_order.dart": """import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: SendOrderPage(api: CafeApi(http.Client()))));
}

class SendOrderPage extends StatefulWidget {
  const SendOrderPage({super.key, required this.api});

  final CafeApi api;

  @override
  State<SendOrderPage> createState() => _SendOrderPageState();
}

class _SendOrderPageState extends State<SendOrderPage> {
  final name = TextEditingController();
  bool sending = false;
  String? message;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> send() async {
    setState(() {
      sending = true;
      message = null;
    });
    try {
      final total = await widget.api.order(name.text, [1, 4]);
      message = '{w_placed}: $total {w_egp}';
    } on ApiException catch (e) {
      message = e.message;
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_order}')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: '{w_your_name}')),
          const SizedBox(height: 16),
          const Text('1 × {w_latte}, 1 × {w_cake}'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sending ? null : send,
            child: sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('{w_send}'),
          ),
          if (message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(message!)),
        ],
      ),
    );
  }
}
""",
    "test/send_order_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_api.dart';
import 'package:bit_app/projects_send_order.dart';

void main() {
  testWidgets('{w_t_post}', (tester) async {
    final client = MockClient((request) async =>
        http.Response('{"error": "{w_no_name}"}', 400, headers: {'content-type': 'application/json; charset=utf-8'}));
    await tester.pumpWidget(MaterialApp(home: SendOrderPage(api: CafeApi(client))));
    await tester.tap(find.text('{w_send}'));
    await tester.pumpAndSettle();
    expect(find.text('{w_no_name}'), findsOneWidget);
  });
}
""",
    "projects/live_search.dart": """import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';

void main() {
  runApp(MaterialApp({w_rtl}debugShowCheckedModeBanner: false, home: SearchPage(api: CafeApi(http.Client()))));
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.api});

  final CafeApi api;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? wait;
  List<Drink>? results;
  int asked = 0;

  void changed(String text) {
    // {w_c_debounce}
    wait?.cancel();
    wait = Timer(const Duration(milliseconds: 400), () async {
      asked++;
      final found = await widget.api.menu(query: text.trim());
      if (mounted) setState(() => results = found);
    });
  }

  @override
  void dispose() {
    wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: changed,
          decoration: const InputDecoration(hintText: '{w_search}', border: InputBorder.none),
        ),
      ),
      body: found == null
          ? const SizedBox()
          : found.isEmpty
          ? const Center(child: Text('{w_none}'))
          : ListView(children: [for (final d in found) ListTile(title: Text(d.name), trailing: Text('${d.price} {w_egp}'))]),
    );
  }
}
""",
    "test/live_search_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_api.dart';
import 'package:bit_app/projects_live_search.dart';

void main() {
  testWidgets('{w_t_search}', (tester) async {
    final asked = <String>[];
    final client = MockClient((request) async {
      asked.add(request.url.queryParameters['q'] ?? '');
      return http.Response('[{"id": 2, "name": "{w_tea}", "price": 25, "image": "tea"}]', 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    await tester.pumpWidget(MaterialApp(home: SearchPage(api: CafeApi(client))));

    for (final text in ['{w_q1}', '{w_q2}', '{w_query}']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(asked, isEmpty);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(asked, ['{w_query}']);
    expect(find.text('{w_tea}'), findsOneWidget);
  });
}
""",
}

SHOTS = [
    ("fetch.png", "lib/fetch.dart", ""),
    ("menu.png", "lib/menu_app.dart", ""),
    ("ordered.png", "lib/menu_app.dart", "button={w_order} {w_juice}"),
    ("failed.png", "lib/broken_app.dart", ""),
    ("special.png", "projects/special.dart", ""),
    ("send-order.png", "projects/send_order.dart", "button={w_send}"),
    ("search.png", "projects/live_search.dart", "at=200,28|keys={w_query}|wait=1500"),
]
T["en"]["w_query"] = "tea"
T["ar"]["w_query"] = "شاي"
T["en"].update(w_q1="t", w_q2="te")
T["ar"].update(w_q1="ش", w_q2="شا")

TESTS = [
    ("api-test.sh", "test/api_test.dart"),
    ("menu-app-test.sh", "test/menu_app_test.dart"),
    ("projects/send-order-test.sh", "test/send_order_test.dart"),
    ("projects/live-search-test.sh", "test/live_search_test.dart"),
]

CURL = [
    ("curl -s localhost:8080/menu/1", None),
    ("curl -s localhost:8080/menu/9 -w '\\nHTTP %{http_code}\\n'", None),
    ("curl -s -X POST localhost:8080/orders -H 'Content-Type: application/json' "
     "-d '{\"name\": \"Sara\", \"items\": [1, 4]}' -w '\\nHTTP %{http_code}\\n'", None),
    ("curl -s -X POST localhost:8080/orders -H 'Content-Type: application/json' "
     "-d '{\"name\": \"\", \"items\": [1]}' -w '\\nHTTP %{http_code}\\n'", None),
]


def start_server(folder):
    proc = popen("dart run server.dart", folder, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                 start_new_session=True)
    for _ in range(200):
        try:
            socket.create_connection(("127.0.0.1", 8080), timeout=0.2).close()
            return proc
        except OSError:
            time.sleep(0.2)
    raise RuntimeError("the server did not start")


def main():
    for lang, words in T.items():
        folder = WORK / "api-server" / lang
        shutil.rmtree(folder, ignore_errors=True)
        write(folder, {"server.dart": fill(SERVER, words)})
        shutil.copytree(PICTURES, folder / "images")
        text, code = sh("dart format server.dart && dart analyze server.dart", folder)
        if code:
            raise RuntimeError(text)
        server = start_server(folder)
        try:
            flutter_gallery(HERE, {lang: words}, FILES, SHOTS, TESTS, packages=["http", "provider"])
            s = Session(folder)
            for cmd, _ in CURL:
                s.run(cmd)
            s.save(HERE / lang / "curl.sh")
        finally:
            os.killpg(server.pid, signal.SIGTERM)
            out = server.communicate(timeout=10)[0]
        # The server's first line, as the reader sees it when starting it.
        (HERE / lang / "server-run.sh").write_text("$ dart run server.dart\n" + out.splitlines()[0] + "\n")
        out_server = HERE / lang / "server"
        out_server.mkdir(parents=True, exist_ok=True)
        (out_server / "server.dart").write_text((folder / "server.dart").read_text())
        print("server ok", lang)


if __name__ == "__main__":
    main()
