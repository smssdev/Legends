$ flutter test integration_test/prefs_test.dart -d linux
00:00 +0: loading integration_test/prefs_test.dart
Building Linux application...                                   
✓ Built build/linux/x64/debug/bundle/bit_app
00:00 +0: أين تحفظ shared_preferences رمزاً على Linux
saved in ~/.local/share/com.example.bit_app
00:00 +1: (tearDownAll)
00:00 +1: All tests passed!
$ cat ~/.local/share/com.example.bit_app/shared_preferences.json; echo
{"token":"eyJhbGciOiJIUzI1NiJ9.demo-access.sig"}
