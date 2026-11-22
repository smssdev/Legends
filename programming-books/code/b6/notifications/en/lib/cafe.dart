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

  // In the foreground the system shows nothing: the app shows its own banner.
  void showBanner(PushMessage message) {
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(message.title ?? ''),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'View',
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
    // Ask after the first order, when the reason is obvious, not at the first launch.
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
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: ordered ? null : order,
            icon: const Icon(Icons.local_cafe),
            label: const Text('Order a latte'),
          ),
          if (ordered)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Ordered! We will tell you when it is ready.'),
            ),
          if (asking)
            PermissionCard(
              onTurnOn: turnOn,
              onNotNow: () => setState(() => asking = false),
            ),
          if (denied)
            const Text(
              'Notifications are off. You can turn them on in Settings.',
            ),
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
              'Know when your order is ready?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('We only send order updates, never ads at night.'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onNotNow, child: const Text('Not now')),
                FilledButton(onPressed: onTurnOn, child: const Text('Turn on')),
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
      appBar: AppBar(title: Text('Order $id')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(Icons.check_circle, size: 96),
            Text('Ready at the counter'),
          ],
        ),
      ),
    );
  }
}
