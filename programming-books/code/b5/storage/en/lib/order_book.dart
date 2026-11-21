import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Order {
  const Order(this.name, this.total);

  factory Order.fromJson(Map<String, dynamic> json) =>
      Order(json['name'] as String, json['total'] as int);

  final String name;
  final int total;

  Map<String, Object> toJson() => {'name': name, 'total': total};
}

// The order history, in one JSON file in the app's own folder.
class OrderBook {
  // The folder is given, so tests can give a temporary one.
  OrderBook({Future<Directory> Function()? folder})
    : folder = folder ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() folder;

  Future<File> get _file async => File('${(await folder()).path}/orders.json');

  Future<List<Order>> load() async {
    final file = await _file;
    // The first time there is no file yet: an empty history, not an error.
    if (!await file.exists()) {
      return [];
    }
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return [
      for (final item in list) Order.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> add(Order order) async {
    final all = [...await load(), order];
    final file = await _file;
    // Write a new file, then swap it in: a crash halfway never leaves half a file.
    final next = File('${file.path}.new');
    await next.writeAsString(jsonEncode([for (final o in all) o.toJson()]));
    await next.rename(file.path);
  }
}
