import 'package:flutter/scheduler.dart';

import 'order_card.dart' as app;

// Slowed down for the book's filmstrips: every animation takes ten times longer.
void main() {
  timeDilation = 10;
  app.main();
}
