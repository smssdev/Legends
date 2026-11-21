import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: SendOrderPage(api: CafeApi(http.Client())),
    ),
  );
}

class SendOrderPage extends StatefulWidget {
  const SendOrderPage({super.key, required this.api});

  final CafeApi api;

  @override
  State<SendOrderPage> createState() => _SendOrderPageState();
}

class _SendOrderPageState extends State<SendOrderPage> {
  final name = TextEditingController();
  bool sending = false;
  String? message;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> send() async {
    setState(() {
      sending = true;
      message = null;
    });
    try {
      final total = await widget.api.order(name.text, [1, 4]);
      message = 'أُرسل الطلب: $total جنيه';
    } on ApiException catch (e) {
      message = e.message;
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اطلب')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'اسمك'),
          ),
          const SizedBox(height: 16),
          const Text('1 × لاتيه, 1 × كيك الكرز'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sending ? null : send,
            child: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('أرسل الطلب'),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(message!),
            ),
        ],
      ),
    );
  }
}
