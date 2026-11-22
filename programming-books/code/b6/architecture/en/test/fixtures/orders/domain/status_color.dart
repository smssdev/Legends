import 'package:material_ui/material_ui.dart';

import 'order.dart';

Color statusColor(OrderStatus s) =>
    s == OrderStatus.ready ? Colors.green : Colors.grey;
