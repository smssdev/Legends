$ flutter test test/guard_bad_test.dart
00:00 +0: loading test/guard_bad_test.dart
00:00 +0: a screen with raw values is caught
00:00 +0 -1: a screen with raw values is caught [E]
  Expected: empty
    Actual: [
              'test/fixtures/hurried_screen.dart:8: a raw colour',
              'test/fixtures/hurried_screen.dart:9: a raw spacing',
              'test/fixtures/hurried_screen.dart:12: a raw colour',
              'test/fixtures/hurried_screen.dart:12: a raw font size'
            ]
