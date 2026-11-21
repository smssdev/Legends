$ sh tool/release.sh
1. No problems in the code
Analyzing bit_notes...                                          
No issues found! (ran in 1.0s)
2. Every test passes
00:00 +0: loading test/app_test.dart
00:00 +0: test/app_test.dart: a note is written, swiped away, and brought back
00:00 +1: test/app_test.dart: a note is written, swiped away, and brought back
00:01 +2: All tests passed!
3. A signed bundle
Running Gradle task 'bundleRelease'...                          
Running Gradle task 'bundleRelease'...                             13.6s
✓ Built build/app/outputs/bundle/release/app-release.aab (50.1MB)
4. Signed with our key?
Owner: CN=Bit Cafe, O=Bit Cafe, C=EG
