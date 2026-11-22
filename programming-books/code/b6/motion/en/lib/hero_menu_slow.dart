import 'package:flutter/scheduler.dart';

import 'hero_menu.dart' as app;

// Slowed down for the book's filmstrips: every animation takes ten times longer.
void main() {
  timeDilation = 10;
  app.main();
}
