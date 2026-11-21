import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const ChoicesPage()),
  );
}

enum Size { small, medium, large }

class ChoicesPage extends StatefulWidget {
  const ChoicesPage({super.key});

  @override
  State<ChoicesPage> createState() => _ChoicesPageState();
}

class _ChoicesPageState extends State<ChoicesPage> {
  var size = Size.medium;
  var oat = false;
  var extra = true;
  var sugar = 1.0;
  String? milk = 'Whole';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        children: [
          // SegmentedButton: one choice of a few, all visible.
          SegmentedButton<Size>(
            segments: const [
              ButtonSegment(value: Size.small, label: Text('Small')),
              ButtonSegment(value: Size.medium, label: Text('Medium')),
              ButtonSegment(value: Size.large, label: Text('Large')),
            ],
            selected: {size},
            onSelectionChanged: (s) => setState(() => size = s.first),
          ),
          // CheckboxListTile: yes or no for each extra, independently.
          CheckboxListTile(
            title: const Text('Oat milk'),
            value: oat,
            onChanged: (v) => setState(() => oat = v!),
          ),
          CheckboxListTile(
            title: const Text('Extra shot'),
            value: extra,
            onChanged: (v) => setState(() => extra = v!),
          ),
          // Slider: a number in a range, by dragging.
          ListTile(title: Text('Sugar: ${sugar.round()}')),
          Slider(
            value: sugar,
            max: 4,
            divisions: 4,
            label: '${sugar.round()}',
            onChanged: (v) => setState(() => sugar = v),
          ),
          // DropdownMenu: one choice of a longer list, shown on demand.
          DropdownMenu<String>(
            label: const Text('Milk'),
            initialSelection: milk,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => milk = v),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'Whole', label: 'Whole'),
              DropdownMenuEntry(value: 'Skimmed', label: 'Skimmed'),
              DropdownMenuEntry(value: 'Oat milk', label: 'Oat milk'),
              DropdownMenuEntry(value: 'None', label: 'None'),
            ],
          ),
        ],
      ),
    );
  }
}
