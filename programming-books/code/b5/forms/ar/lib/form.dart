import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const CallBackForm(),
    ),
  );
}

class CallBackForm extends StatefulWidget {
  const CallBackForm({super.key});

  @override
  State<CallBackForm> createState() => _CallBackFormState();
}

class _CallBackFormState extends State<CallBackForm> {
  // المفتاح يعطينا النموذج، لنفحص كل المربعات معاً.
  final formKey = GlobalKey<FormState>();
  var mode = AutovalidateMode.disabled;

  void send() {
    if (formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('شكراً، سنتصل بك')));
    } else {
      // بعد أول محاولة، افحص والشخص يكتب.
      setState(() => mode = AutovalidateMode.onUserInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقهى بِت')),
      body: Form(
        key: formKey,
        autovalidateMode: mode,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'اسمك'),
              // دالة التحقق تُرجع رسالة خطأ، أو null حين تكون القيمة سليمة.
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'من فضلك اكتب اسمك'
                  : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'الهاتف'),
              keyboardType: TextInputType.phone,
              validator: (value) => RegExp(r'^[0-9]{11}$').hasMatch(value ?? '')
                  ? null
                  : 'رقم الهاتف من 11 رقماً',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  (value ?? '').contains('@') ? null : 'لا يبدو هذا عنوان بريد',
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: send, child: const Text('أرسل')),
          ],
        ),
      ),
    );
  }
}
