# Run the tests that came with the template
$ flutter test
00:00 +0: loading test/widget_test.dart
00:00 +0 -1: loading test/widget_test.dart [E]
  Failed to load "test/widget_test.dart":
  Compilation failed for testPath=test/widget_test.dart: test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.
      await tester.pumpWidget(const MyApp());
                                    ^^^^^
  .
00:00 +0 -1: Some tests failed.

Failing tests:
  test/widget_test.dart: loading test/widget_test.dart
test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.
    await tester.pumpWidget(const MyApp());
                                  ^^^^^
