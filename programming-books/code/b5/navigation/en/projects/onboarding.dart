import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const Onboarding()),
  );
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final controller = PageController();
  int page = 0;

  static const pages = [
    (Icons.phone_iphone, 'Order ahead', 'Choose your drink before you arrive.'),
    (
      Icons.directions_walk,
      'Skip the queue',
      'Your cup is ready when you walk in.',
    ),
    (Icons.card_giftcard, 'Collect points', 'Every tenth coffee is on us.'),
  ];

  void finish() {
    // pushReplacement: the onboarding is gone; back does not return to it.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const Scaffold(body: Center(child: Text('Welcome to Bit Café'))),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: finish, child: const Text('Skip')),
            ),
            // PageView: full pages, swiped sideways; the controller moves it by code.
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  for (final (icon, title, text) in pages)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 12,
                        children: [
                          Icon(icon, size: 120, color: Colors.brown),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(text, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? Colors.brown : Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? finish
                      : () => controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                  child: Text(last ? 'Start' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
