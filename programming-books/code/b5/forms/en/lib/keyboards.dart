import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const KeyboardsPage()),
  );
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
          // keyboardType chooses the keyboard: digits for a phone, @ for an email.
          // textInputAction: the key at the corner of the keyboard says Next, then Done.
          const TextField(
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          // obscureText hides what is typed; the eye button shows it.
          TextField(
            obscureText: hidden,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                tooltip: hidden ? 'Show password' : 'Hide password',
                icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => hidden = !hidden),
              ),
            ),
          ),
          // maxLength: a limit, with a counter under the field.
          const TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 2,
            decoration: InputDecoration(
              labelText: 'Cups',
              prefixIcon: Icon(Icons.local_cafe),
            ),
          ),
        ],
      ),
    );
  }
}
