import 'package:material_ui/material_ui.dart';

// من سجّل الدخول. والموجّه يستمع إليه، ويحوّل حين يتغير.
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
