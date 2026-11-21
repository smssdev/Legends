import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      home: const ChoicesPage(),
    ),
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
  String? milk = 'كامل الدسم';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        children: [
          // SegmentedButton: اختيار واحد من قليل، كلها ظاهرة.
          SegmentedButton<Size>(
            segments: const [
              ButtonSegment(value: Size.small, label: Text('صغير')),
              ButtonSegment(value: Size.medium, label: Text('وسط')),
              ButtonSegment(value: Size.large, label: Text('كبير')),
            ],
            selected: {size},
            onSelectionChanged: (s) => setState(() => size = s.first),
          ),
          // CheckboxListTile: نعم أو لا لكل إضافة، كل منها مستقل.
          CheckboxListTile(
            title: const Text('حليب الشوفان'),
            value: oat,
            onChanged: (v) => setState(() => oat = v!),
          ),
          CheckboxListTile(
            title: const Text('جرعة إضافية'),
            value: extra,
            onChanged: (v) => setState(() => extra = v!),
          ),
          // Slider: رقم ضمن مدى، بالسحب.
          ListTile(title: Text('السكر: ${sugar.round()}')),
          Slider(
            value: sugar,
            max: 4,
            divisions: 4,
            label: '${sugar.round()}',
            onChanged: (v) => setState(() => sugar = v),
          ),
          // DropdownMenu: اختيار واحد من قائمة أطول، تظهر عند الطلب.
          DropdownMenu<String>(
            label: const Text('الحليب'),
            initialSelection: milk,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => milk = v),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'كامل الدسم', label: 'كامل الدسم'),
              DropdownMenuEntry(value: 'خالي الدسم', label: 'خالي الدسم'),
              DropdownMenuEntry(value: 'حليب الشوفان', label: 'حليب الشوفان'),
              DropdownMenuEntry(value: 'بلا حليب', label: 'بلا حليب'),
            ],
          ),
        ],
      ),
    );
  }
}
