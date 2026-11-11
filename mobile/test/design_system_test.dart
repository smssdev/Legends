// [Sprint 54 F1-F3] The design system in the app: the type roles reach the theme by the web's names, and the
// components named as the web's (GlmAsync, GlmSkeleton, GlmPageTitle) wait, fail, stay empty and show.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/tokens.g.dart';
import 'package:glm/ui/widgets/async_view.dart';

Future<void> pump(WidgetTester t, Widget child) async {
  await t.pumpWidget(MaterialApp(
    theme: glmTheme(day: false),
    locale: const Locale('ar'),
    supportedLocales: L.supportedLocales,
    localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    home: Scaffold(body: child),
  ));
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('the type roles are the theme\'s text, by the web\'s sizes', (t) async {
    late BuildContext ctx;
    await pump(t, Builder(builder: (c) => (ctx = c, const SizedBox()).$2));
    expect(ctx.type.caption.fontSize, GlmType.caption.size);
    expect(ctx.type.body.fontSize, 14);
    expect(ctx.type.headline.fontWeight, FontWeight.w800);
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontSize, GlmType.body.size);
    expect(Theme.of(ctx).textTheme.titleLarge!.fontSize, GlmType.title.size);
    expect(Theme.of(ctx).textTheme.bodySmall!.fontSize, greaterThanOrEqualTo(12));
  });

  testWidgets('GlmAsync waits in the shape of what comes, then shows or says it is empty', (t) async {
    await pump(t, const GlmAsync<List<int>>(value: AsyncLoading(), data: _list, skeleton: GlmSkeletonKind.row, rows: 3));
    expect(find.byType(GlmSkeleton), findsOneWidget);

    await pump(t, GlmAsync<List<int>>(value: const AsyncData([]), data: _list, isEmpty: (l) => l.isEmpty));
    expect(find.text('لا شيء هنا بعد'), findsOneWidget);

    await pump(t, GlmAsync<List<int>>(value: const AsyncData([7]), data: _list, isEmpty: (l) => l.isEmpty));
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('GlmPageTitle draws the title with its actions', (t) async {
    await pump(t, GlmPageTitle('الكشاف', subtitle: 'ابحث عن لاعب', actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))]));
    expect(find.text('الكشاف'), findsOneWidget);
    expect(find.text('ابحث عن لاعب'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

Widget _list(List<int> l) => Column(children: [for (final n in l) Text('$n')]);
