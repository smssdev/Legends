import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/size_class.dart';
import 'package:glm/ui/widgets/glm_button.dart';
import 'package:glm/ui/widgets/player_name.dart';

/// [Sprint 72] The one place a screen asks how much room it has, and the two labels that never break inside a word.
void main() {
  test('[R2] the classes by width and by height (the tight side in landscape)', () {
    expect(GlmFit.width(559), GlmWidth.narrow);
    expect(GlmFit.width(560), GlmWidth.regular);
    expect(GlmFit.width(840), GlmWidth.wide);
    expect(GlmFit.height(339), GlmHeight.tiny);
    expect(GlmFit.height(360), GlmHeight.short);
    expect(GlmFit.height(412), GlmHeight.tall);
  });

  test('[R7] a tablet is drawn larger, a phone as it is', () {
    expect(GlmFit.scaleOf(const Size(800, 360)), 1);
    expect(GlmFit.scaleOf(const Size(915, 412)), 1);
    expect(GlmFit.scaleOf(const Size(1280, 800)), 1.3);
    expect(GlmFit.scaleOf(const Size(1366, 1024)), 1.5);
  });

  test('[R6] a name tries its whole, then an initial, then the last name', () {
    expect(PlayerName.forms('Giorgi Mamardashvili'), ['Giorgi Mamardashvili', 'G. Mamardashvili', 'Mamardashvili']);
    expect(PlayerName.forms('Virgil van Dijk'), ['Virgil van Dijk', 'V. van Dijk', 'Dijk']);
    expect(PlayerName.forms('Alisson'), ['Alisson']);
  });

  Future<void> pump(WidgetTester t, double width, Widget child) => t.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Center(child: SizedBox(width: width, child: child)),
    ),
  );

  testWidgets('[R6] a name too long for its row shortens instead of breaking', (t) async {
    await pump(t, 400, const PlayerName('Giorgi Mamardashvili'));
    expect(find.text('Giorgi Mamardashvili'), findsOneWidget);
    await pump(t, 150, const PlayerName('Giorgi Mamardashvili', style: TextStyle(fontSize: 10)));
    expect(find.text('Giorgi Mamardashvili'), findsNothing);
    expect(t.widget<Text>(find.byType(Text)).maxLines, 1);
  });

  testWidgets('[R6] a label steps its size down before a word would break', (t) async {
    await pump(t, 300, const FitLabel('تقرير الخصم', style: TextStyle(fontSize: 16)));
    expect(t.widget<Text>(find.byType(Text)).style!.fontSize, 16);
    await pump(t, 60, const FitLabel('التكتيك', style: TextStyle(fontSize: 16)));
    expect(t.widget<Text>(find.byType(Text)).style!.fontSize, lessThan(16));
  });
}
