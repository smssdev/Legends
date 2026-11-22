import 'package:flutter/scheduler.dart';

import 'hero_menu.dart' as app;

// مبطَّأة لأشرطة صور الكتاب: كل حركة تأخذ عشرة أضعاف وقتها.
void main() {
  timeDilation = 10;
  app.main();
}
