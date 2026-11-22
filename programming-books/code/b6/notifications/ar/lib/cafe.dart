import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'push/message.dart';
import 'push/push_source.dart';

class CafeApp extends StatefulWidget {
  const CafeApp({super.key, required this.push});

  final PushSource push;

  @override
  State<CafeApp> createState() => _CafeAppState();
}

class _CafeAppState extends State<CafeApp> {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  late final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomePage(push: widget.push),
        routes: [
          GoRoute(
            path: 'orders/:id',
            builder: (context, state) =>
                OrderPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  final subscriptions = <StreamSubscription<PushMessage>>[];

  @override
  void initState() {
    super.initState();
    subscriptions
      ..add(widget.push.foreground.listen(showBanner))
      ..add(widget.push.opened.listen((message) => router.go(message.route)));
    widget.push.initial().then((message) {
      if (message != null) {
        router.go(message.route);
      }
    });
  }

  // في المقدمة لا يعرض النظام شيئاً: التطبيق يعرض شريطه الخاص.
  void showBanner(PushMessage message) {
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(message.title ?? ''),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'اعرض',
          onPressed: () => router.go(message.route),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      scaffoldMessengerKey: messenger,
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      routerConfig: router,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.push});

  final PushSource push;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var ordered = false;
  var asking = false;
  var denied = false;

  Future<void> order() async {
    setState(() => ordered = true);
    // اسأل بعد أول طلب، حين يكون السبب واضحاً، لا عند أول فتح.
    if (await widget.push.permission() == PermissionState.unknown) {
      setState(() => asking = true);
    }
  }

  Future<void> turnOn() async {
    final answer = await widget.push.request();
    setState(() {
      asking = false;
      denied = answer == PermissionState.denied;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: ordered ? null : order,
            icon: const Icon(Icons.local_cafe),
            label: const Text('اطلب لاتيه'),
          ),
          if (ordered)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('تم الطلب! سنخبرك حين يجهز.'),
            ),
          if (asking)
            PermissionCard(
              onTurnOn: turnOn,
              onNotNow: () => setState(() => asking = false),
            ),
          if (denied)
            const Text('الإشعارات مطفأة. يمكنك تفعيلها من الإعدادات.'),
        ],
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.onTurnOn,
    required this.onNotNow,
  });

  final VoidCallback onTurnOn;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              'تريد أن تعرف حين يجهز طلبك؟',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('نرسل تحديثات الطلب فقط، ولا إعلانات ليلاً.'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onNotNow, child: const Text('ليس الآن')),
                FilledButton(onPressed: onTurnOn, child: const Text('فعّل')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderPage extends StatelessWidget {
  const OrderPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الطلب $id')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(Icons.check_circle, size: 96),
            Text('جاهز عند المنضدة'),
          ],
        ),
      ),
    );
  }
}
