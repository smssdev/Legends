import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const CallBackForm()),
  );
}

class CallBackForm extends StatefulWidget {
  const CallBackForm({super.key});

  @override
  State<CallBackForm> createState() => _CallBackFormState();
}

class _CallBackFormState extends State<CallBackForm> {
  // The key gives us the form, to check every field at once.
  final formKey = GlobalKey<FormState>();
  var mode = AutovalidateMode.disabled;

  void send() {
    if (formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you, we will call you')),
      );
    } else {
      // After the first try, check as the person types.
      setState(() => mode = AutovalidateMode.onUserInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bit Café')),
      body: Form(
        key: formKey,
        autovalidateMode: mode,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Your name'),
              // A validator returns an error message, or null when the value is fine.
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your name'
                  : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              validator: (value) => RegExp(r'^[0-9]{11}$').hasMatch(value ?? '')
                  ? null
                  : 'A phone number has 11 digits',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value ?? '').contains('@')
                  ? null
                  : 'This does not look like an email address',
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: send, child: const Text('Send')),
          ],
        ),
      ),
    );
  }
}
