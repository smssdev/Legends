$ dart pub global activate native_stack_traces
Activated native_stack_traces 0.7.1.
$ dart pub global run native_stack_traces:decode translate -d build/symbols/app.linux-x64.symbols -i crash.txt | grep '^#' | head -3
#0      new Order.fromJson (lib/crash_app.dart:11:27)
#1      total (lib/crash_app.dart:16:47)
#2      main.<anonymous closure> (lib/crash_app.dart:30:43)
