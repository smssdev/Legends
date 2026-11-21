$ flutter test test/overflow_test.dart
00:00 +0: loading test/overflow_test.dart
00:00 +0: a long name in a row
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 2008 pixels on the right.

…
════════════════════════════════════════════════════════════════════════════════════════════════════
00:00 +0 -1: a long name in a row [E]
  Test failed. See exception logs above.
  The test description was: a long name in a row
  
00:00 +0 -1: Some tests failed.

Failing tests:
  test/overflow_test.dart: a long name in a row
