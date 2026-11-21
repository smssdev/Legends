import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const SignUpPage(),
    ),
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
          .showSnackBar(const SnackBar(content: Text('أُنشئ الحساب')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أنشئ حساباً')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v ?? '').contains('@') ? null : 'لا يبدو هذا عنوان بريد',
            ),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              validator: (v) =>
                  (v ?? '').length < 8 ? '8 أحرف على الأقل' : null,
            ),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'أكّد كلمة المرور'),
              validator: (v) =>
                  v == password.text ? null : 'كلمتا المرور غير متطابقتين',
            ),
            FormField<bool>(
              initialValue: false,
              validator: (v) => v == true ? null : 'من فضلك وافق على الشروط',
              builder: (field) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('أوافق على الشروط'),
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
            FilledButton(onPressed: submit, child: const Text('أنشئ حساباً')),
          ],
        ),
      ),
    );
  }
}
