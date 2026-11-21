import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: const TipPage()));
}

class TipPage extends StatefulWidget {
  const TipPage({super.key});

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  final bill = TextEditingController();
  double tip = 10;
  int people = 2;

  @override
  void dispose() {
    bill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(bill.text) ?? 0;
    final each = amount * (1 + tip / 100) / people;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          TextField(
            controller: bill,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Bill',
              suffixText: 'EGP',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Tip: ${tip.round()}%'),
          Slider(
            value: tip,
            max: 25,
            divisions: 5,
            label: '${tip.round()}%',
            onChanged: (v) => setState(() => tip = v),
          ),
          Row(
            children: [
              Text('Each of $people people'),
              const Spacer(),
              IconButton(
                onPressed: people > 1 ? () => setState(() => people--) : null,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: () => setState(() => people++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('Each pays', textAlign: TextAlign.center),
          Text(
            '${each.toStringAsFixed(2)} EGP',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }
}
