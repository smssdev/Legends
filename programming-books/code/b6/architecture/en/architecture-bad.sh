$ flutter test test/architecture_bad_test.dart
00:00 +0: loading test/architecture_bad_test.dart
00:00 +0: a domain file that imports Flutter is caught
00:00 +0 -1: a domain file that imports Flutter is caught [E]
  Expected: empty
    Actual: [
              'test/fixtures/orders/domain/status_color.dart: import \'package:material_ui/material_ui.dart\';'
            ]
