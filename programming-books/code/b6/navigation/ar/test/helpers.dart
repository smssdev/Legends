import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/router.dart';

Future<GoRouter> pumpCafe(WidgetTester tester, Auth auth) async {
  final router = buildRouter(auth);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

String where(GoRouter router) =>
    '${router.routerDelegate.currentConfiguration.uri}';
