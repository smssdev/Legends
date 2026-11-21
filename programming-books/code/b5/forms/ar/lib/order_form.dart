import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const OrderForm(),
    ),
  );
}

enum Size {
  small(35, 'صغير'),
  medium(45, 'وسط'),
  large(55, 'كبير');

  final int price;
  final String label;
  const Size(this.price, this.label);
}

class OrderForm extends StatefulWidget {
  const OrderForm({super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final notes = TextEditingController();
  var size = Size.medium;
  var extraShot = false;
  var cups = 1;

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    super.dispose();
  }

  // السعر يتبع كل اختيار: يُحسب في build، ولا يُحفظ أبداً.
  int get total => (size.price + (extraShot ? 10 : 0)) * cups;

  Future<void> place() async {
    if (!formKey.currentState!.validate()) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('طلب باسم ${name.text.trim()}'),
        content: Text(
          '$cups × ${size.label}${extraShot ? ' + جرعة إضافية' : ''}\nالإجمالي: $total جنيه',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبك')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسمك',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'من فضلك اكتب اسمك' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<Size>(
              segments: const [
                ButtonSegment(value: Size.small, label: Text('صغير')),
                ButtonSegment(value: Size.medium, label: Text('وسط')),
                ButtonSegment(value: Size.large, label: Text('كبير')),
              ],
              selected: {size},
              onSelectionChanged: (s) => setState(() => size = s.first),
            ),
            SwitchListTile(
              title: const Text('جرعة إضافية (+10)'),
              value: extraShot,
              onChanged: (v) => setState(() => extraShot = v),
            ),
            ListTile(
              title: const Text('الأكواب'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: cups > 1 ? () => setState(() => cups--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$cups', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () => setState(() => cups++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات للنادل',
                hintText: 'بلا رغوة من فضلك…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: place,
              child: Text('أرسل الطلب · $total جنيه'),
            ),
          ],
        ),
      ),
    );
  }
}
