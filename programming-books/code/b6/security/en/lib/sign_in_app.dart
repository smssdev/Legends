import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'security/tokens.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,

    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: const SignInPage(),
  ),
);

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  var signedIn = false;

  Future<void> signIn() async {
    // The server's answer, in this demo.
    const access = 'eyJhbGciOiJIUzI1NiJ9.demo-access.sig';
    const refresh = 'rt-demo-7f3a91c4';
    // Convenient, and readable by anything that can read the app's files.
    await SharedPreferencesAsync().setString('token', access);
    await TokenStore(DeviceSecureStore()).signedIn(
      access: access,
      lifetime: const Duration(minutes: 15),
      refresh: refresh,
    );
    setState(() => signedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bit Café')),
      body: Center(
        child: signedIn
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Signed in. Your session is saved on this device.',
                  textAlign: TextAlign.center,
                ),
              )
            : FilledButton(onPressed: signIn, child: const Text('Sign in')),
      ),
    );
  }
}
