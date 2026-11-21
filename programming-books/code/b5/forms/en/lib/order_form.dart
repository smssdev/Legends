import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const OrderForm()),
  );
}

enum Size {
  small(35, 'Small'),
  medium(45, 'Medium'),
  large(55, 'Large');

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

  // The price follows every choice: computed in build, never stored.
  int get total => (size.price + (extraShot ? 10 : 0)) * cups;

  Future<void> place() async {
    if (!formKey.currentState!.validate()) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order for ${name.text.trim()}'),
        content: Text(
          '$cups × ${size.label}${extraShot ? ' + Extra shot' : ''}\nTotal: $total EGP',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your order')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<Size>(
              segments: const [
                ButtonSegment(value: Size.small, label: Text('Small')),
                ButtonSegment(value: Size.medium, label: Text('Medium')),
                ButtonSegment(value: Size.large, label: Text('Large')),
              ],
              selected: {size},
              onSelectionChanged: (s) => setState(() => size = s.first),
            ),
            SwitchListTile(
              title: const Text('Extra shot (+10)'),
              value: extraShot,
              onChanged: (v) => setState(() => extraShot = v),
            ),
            ListTile(
              title: const Text('Cups'),
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
                labelText: 'Notes for the barista',
                hintText: 'No foam, please…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: place,
              child: Text('Place order · $total EGP'),
            ),
          ],
        ),
      ),
    );
  }
}
