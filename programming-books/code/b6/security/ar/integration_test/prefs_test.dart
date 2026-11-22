import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('أين تحفظ shared_preferences رمزاً على Linux', (tester) async {
    await SharedPreferencesAsync().setString(
      'token',
      'eyJhbGciOiJIUzI1NiJ9.demo-access.sig',
    );
    debugPrint('saved in ${(await getApplicationSupportDirectory()).path}');
  });
}
