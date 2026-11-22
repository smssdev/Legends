import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'auth.dart';
import 'data.dart';
import 'routes.dart';

class TabsScaffold extends StatelessWidget {
  const TabsScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // goBranch تنتقل بين الألسنة وتُبقي كومة كل لسان؛ ولمس اللسان الحالي من جديد يعود إلى صفحته الأولى.
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe), label: 'القائمة'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'الطلبات',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'الحساب'),
        ],
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, this.max});

  final int? max;

  @override
  Widget build(BuildContext context) {
    final shown = drinks.entries.where(
      (e) => max == null || e.value.$2 <= max!,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: ListView(
        children: [
          // الفلتر يعيش في العنوان: شاركه، واحفظه، واضغط رجوع.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('أي سعر'),
                  selected: max == null,
                  onSelected: (_) => context.go(Routes.menu),
                ),
                for (final limit in [30, 50])
                  ChoiceChip(
                    label: Text('حتى $limit'),
                    selected: max == limit,
                    onSelected: (_) => context.go(Routes.menuUpTo(limit)),
                  ),
              ],
            ),
          ),
          for (final MapEntry(key: id, value: (name, price)) in shown)
            ListTile(
              title: Text(name),
              subtitle: Text('$price جنيه'),
              trailing: const Icon(Icons.chevron_right),
              // go: غيّر العنوان. والموجّه يبني له الكومة الصحيحة.
              onTap: () => context.go(Routes.drink(id)),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final drink = drinks[id];
    return Scaffold(
      appBar: AppBar(title: Text(drink?.$1 ?? id)),
      body: Center(
        child: drink == null
            ? Text('لا مشروب باسم "$id"')
            : Text(
                '${drink.$2} جنيه',
                style: Theme.of(context).textTheme.displaySmall,
              ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      body: ListView(
        children: [
          for (final MapEntry(key: id, value: items) in orders.entries)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('الطلب $id'),
              subtitle: Text('القطع: $items'),
              onTap: () => context.go(Routes.order(id)),
            ),
        ],
      ),
    );
  }
}

class OrderPage extends StatelessWidget {
  const OrderPage({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final items = orders[id];
    return Scaffold(
      appBar: AppBar(title: Text('الطلب ${id ?? '?'}')),
      body: Center(
        child: Text(
          items == null ? 'لا طلب برقم ${id ?? '?'}' : 'القطع: $items',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.auth});

  final Auth auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحساب')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('أنت مسجّل الدخول.'),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('عدّل الاسم'),
            onTap: () => context.go(Routes.edit),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('سجّل الخروج'),
            onTap: auth.signOut,
          ),
        ],
      ),
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, required this.auth, required this.from});

  final Auth auth;
  final String from;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            Text('سجّل الدخول لتتابع إلى'),
            Text(
              from,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FilledButton(
              onPressed: auth.signIn,
              child: const Text('سجّل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(Icons.explore_off, size: 64),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('$uri', textDirection: TextDirection.ltr),
            FilledButton(
              onPressed: () => context.go(Routes.menu),
              child: const Text('عُد إلى القائمة'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditNamePage extends StatefulWidget {
  const EditNamePage({super.key});

  static var unsaved = false;

  static Future<bool> confirmLeave(BuildContext context) async {
    if (!unsaved) {
      return true;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغادر دون حفظ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ابقَ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تجاهل'),
          ),
        ],
      ),
    );
    if (leave ?? false) {
      unsaved = false;
    }
    return leave ?? false;
  }

  @override
  State<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<EditNamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عدّل الاسم')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(labelText: 'الاسم'),
          onChanged: (_) => EditNamePage.unsaved = true,
        ),
      ),
    );
  }
}
