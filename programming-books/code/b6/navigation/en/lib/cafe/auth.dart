import 'package:material_ui/material_ui.dart';

// Who is signed in. The router listens to it, and redirects when it changes.
class Auth extends ChangeNotifier {
  var signedIn = false;

  void signIn() {
    signedIn = true;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    notifyListeners();
  }
}
