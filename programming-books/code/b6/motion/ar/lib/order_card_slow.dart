import 'package:flutter/scheduler.dart';

import 'order_card.dart' as app;

// مبطَّأة لأشرطة صور الكتاب: كل حركة تأخذ عشرة أضعاف وقتها.
void main() {
  timeDilation = 10;
  app.main();
}
