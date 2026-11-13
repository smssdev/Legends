import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_error.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/async_view.dart';

Future<void> show(WidgetTester t, AsyncValue<List<int>> value) => t.pumpWidget(
  MaterialApp(
    theme: glmTheme(day: false),
    locale: const Locale('ar'),
    supportedLocales: L.supportedLocales,
    localizationsDelegates: const [
      L.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: GlmAsync<List<int>>(value: value, isEmpty: (v) => v.isEmpty, data: (_) => const Text('data')),
    ),
  ),
);

String? art(WidgetTester t) => t.widgetList<GlmStateArt>(find.byType(GlmStateArt)).firstOrNull?.state;

void main() {
  testWidgets('[Sprint 63 G9] the mascot in the screen\'s state: empty, worried at an error, asleep with no connection', (t) async {
    await show(t, const AsyncData([]));
    expect(art(t), 'empty');
    await show(t, const AsyncError(ApiError('refused', status: 500), StackTrace.empty));
    expect(art(t), 'error');
    final offline = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );
    await show(t, AsyncError(ApiError.from(offline), StackTrace.empty));
    expect(art(t), 'offline');
    await show(t, const AsyncData([1]));
    expect(art(t), isNull);
  });
}
