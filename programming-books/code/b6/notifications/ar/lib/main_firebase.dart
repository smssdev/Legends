import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'background/dispatcher.dart';
import 'cafe.dart';
import 'push/firebase_source.dart';

// The real entry point, for Android and iOS. It needs the project's Firebase configuration (see the text).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await scheduleSync();
  runApp(CafeApp(push: FirebasePushSource()));
}
