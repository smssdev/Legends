import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class Order {
  Order(this.items);

  factory Order.fromJson(Map<String, Object?> json) =>
      Order((json['items']! as List).cast<String>());

  final List<String> items;
}

int total(Map<String, Object?> json) => Order.fromJson(json).items.length * 45;

// The release app below crashes on purpose a second after it starts.
void main() {
  PlatformDispatcher.instance.onError = (error, stack) {
    stdout.writeln('crash: $error');
    stdout.writeln(stack);
    exit(1);
  };
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Bit Café'))),
    ),
  );
  Timer(const Duration(seconds: 1), () => total({'customer': 'Layla'}));
}
