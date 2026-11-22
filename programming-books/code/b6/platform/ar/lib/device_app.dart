import 'package:material_ui/material_ui.dart';

import 'device/device_source.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),

    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: DevicePage(source: PigeonDevice()),
  ),
);

class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.source});

  final DeviceSource source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('هذا الجهاز')),
      body: FutureBuilder(
        future: readDevice(source),
        builder: (context, snapshot) {
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('نقرأ الجهاز'));
          }
          final info = report.info;
          if (info == null) {
            return Center(
              child: Text('لا جانب أصلياً هنا (${report.problem})'),
            );
          }
          final battery = switch (report) {
            DeviceReport(:final int battery) => '$battery%',
            DeviceReport(problem: 'UNAVAILABLE') => 'لا بطارية',
            DeviceReport(:final problem) => '$problem',
          };
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.computer),
                title: const Text('النظام'),
                subtitle: Text(info.system),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('الإصدار'),
                // رقم الإصدار نص من اليسار إلى اليمين: اعزله (U+2066 ... U+2069) داخل أي سطر.
                subtitle: Text('\u2066${info.version}\u2069'),
              ),
              ListTile(
                leading: const Icon(Icons.memory),
                title: const Text('الذاكرة'),
                subtitle: Text('${info.memoryMb} ميغابايت'),
              ),
              ListTile(
                leading: const Icon(Icons.battery_unknown),
                title: const Text('البطارية'),
                subtitle: Text(battery),
              ),
            ],
          );
        },
      ),
    );
  }
}
