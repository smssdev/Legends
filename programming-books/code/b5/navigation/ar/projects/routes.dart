import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp.router(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      routerConfig: router(),
    ),
  );
}

const names = ['لاتيه', 'شاي بالنعناع', 'عصير برتقال', 'كيك الكرز'];

GoRouter router([String start = '/']) => GoRouter(
  initialLocation: start,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('القائمة')),
        body: ListView(
          children: [
            for (var i = 0; i < names.length; i++)
              ListTile(
                title: Text(names[i]),
                onTap: () => context.go('/drinks/$i'),
              ),
          ],
        ),
      ),
      routes: [
        GoRoute(
          path: 'drinks/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id']!);
            if (id == null || id < 0 || id >= names.length) {
              return const NotFoundPage();
            }
            return Scaffold(
              appBar: AppBar(title: Text(names[id])),
              body: Center(
                child: Text(names[id], style: const TextStyle(fontSize: 32)),
              ),
            );
          },
        ),
      ],
    ),
  ],
  // العنوان الذي لا يطابق شيئاً يحصل على هذه الصفحة.
  errorBuilder: (context, state) => const NotFoundPage(),
);

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(Icons.search_off, size: 96, color: Colors.grey),
            const Text('الصفحة غير موجودة', style: TextStyle(fontSize: 24)),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('العودة إلى القائمة'),
            ),
          ],
        ),
      ),
    );
  }
}
