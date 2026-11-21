import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const SignUpPage()),
  );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account created')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v ?? '').contains('@')
                  ? null
                  : 'This does not look like an email address',
            ),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'At least 8 characters' : null,
            ),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (v) =>
                  v == password.text ? null : 'The passwords do not match',
            ),
            FormField<bool>(
              initialValue: false,
              validator: (v) => v == true ? null : 'Please accept the terms',
              builder: (field) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I accept the terms'),
                value: field.value,
                onChanged: field.didChange,
                subtitle: field.hasError
                    ? Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: submit,
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
