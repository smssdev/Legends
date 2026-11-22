import 'package:material_ui/material_ui.dart';

import 'device/device_source.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,

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
      appBar: AppBar(title: const Text('This device')),
      body: FutureBuilder(
        future: readDevice(source),
        builder: (context, snapshot) {
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('Reading the device'));
          }
          final info = report.info;
          if (info == null) {
            return Center(
              child: Text('No native side here (${report.problem})'),
            );
          }
          final battery = switch (report) {
            DeviceReport(:final int battery) => '$battery%',
            DeviceReport(problem: 'UNAVAILABLE') => 'No battery',
            DeviceReport(:final problem) => '$problem',
          };
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.computer),
                title: const Text('System'),
                subtitle: Text(info.system),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                // A version is left-to-right text: isolate it (U+2066 ... U+2069) inside any line.
                subtitle: Text('\u2066${info.version}\u2069'),
              ),
              ListTile(
                leading: const Icon(Icons.memory),
                title: const Text('Memory'),
                subtitle: Text('${info.memoryMb} MB'),
              ),
              ListTile(
                leading: const Icon(Icons.battery_unknown),
                title: const Text('Battery'),
                subtitle: Text(battery),
              ),
            ],
          );
        },
      ),
    );
  }
}
