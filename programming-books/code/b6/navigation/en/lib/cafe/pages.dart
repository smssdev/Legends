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
        // goBranch switches tab and keeps each tab's stack; tapping the current tab again goes to its first page.
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe), label: 'Menu'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
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
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          // The filter lives in the address: share it, bookmark it, press back.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Any price'),
                  selected: max == null,
                  onSelected: (_) => context.go(Routes.menu),
                ),
                for (final limit in [30, 50])
                  ChoiceChip(
                    label: Text('Up to $limit'),
                    selected: max == limit,
                    onSelected: (_) => context.go(Routes.menuUpTo(limit)),
                  ),
              ],
            ),
          ),
          for (final MapEntry(key: id, value: (name, price)) in shown)
            ListTile(
              title: Text(name),
              subtitle: Text('$price EGP'),
              trailing: const Icon(Icons.chevron_right),
              // go: change the address. The router builds the right stack for it.
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
            ? Text('No drink called "$id"')
            : Text(
                '${drink.$2} EGP',
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
      appBar: AppBar(title: const Text('Orders')),
      body: ListView(
        children: [
          for (final MapEntry(key: id, value: items) in orders.entries)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Order $id'),
              subtitle: Text('Items: $items'),
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
      appBar: AppBar(title: Text('Order ${id ?? '?'}')),
      body: Center(
        child: Text(
          items == null ? 'No order number ${id ?? '?'}' : 'Items: $items',
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
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('You are signed in.'),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit name'),
            onTap: () => context.go(Routes.edit),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
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
            Text('Sign in to continue to'),
            Text(
              from,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FilledButton(onPressed: auth.signIn, child: const Text('Sign in')),
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
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('$uri', textDirection: TextDirection.ltr),
            FilledButton(
              onPressed: () => context.go(Routes.menu),
              child: const Text('Back to the menu'),
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
        title: const Text('Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
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
      appBar: AppBar(title: const Text('Edit name')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (_) => EditNamePage.unsaved = true,
        ),
      ),
    );
  }
}
