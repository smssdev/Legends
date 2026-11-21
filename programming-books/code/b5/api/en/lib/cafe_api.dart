import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

class Drink {
  const Drink({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  // One drink from its JSON: a named constructor, as in Chapter 3.
  factory Drink.fromJson(Map<String, dynamic> json) => Drink(
    id: json['id'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    image: json['image'] as String,
  );

  final int id;
  final String name;
  final int price;
  final String image;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

// Everything about the server in one class; the client is given, so tests can give a fake one.
class CafeApi {
  CafeApi(this.client, {this.base = 'http://localhost:8080'});

  final http.Client client;
  final String base;

  String imageUrl(Drink d) => '$base/images/${d.image}.png';

  Future<List<Drink>> menu({String query = ''}) async {
    final uri = Uri.parse('$base/menu')
        .replace(queryParameters: query.isEmpty ? null : {'q': query});
    final list = await _send(client.get(uri)) as List<dynamic>;
    return [
      for (final item in list) Drink.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Drink> drink(int id) async => Drink.fromJson(
    await _send(client.get(Uri.parse('$base/menu/$id')))
        as Map<String, dynamic>,
  );

  Future<int> order(String name, List<int> items) async {
    final reply = await _send(
      client.post(
        Uri.parse('$base/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'items': items}),
      ),
    );
    return (reply as Map<String, dynamic>)['total'] as int;
  }

  Future<Object?> _send(Future<http.Response> request) async {
    final response = await request.timeout(const Duration(seconds: 10));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    // Anything but 200 is a failure, with the server's own message.
    if (response.statusCode >= 300) {
      throw ApiException(
        (body as Map<String, dynamic>)['error'] as String? ??
            'HTTP ${response.statusCode}',
      );
    }
    return body;
  }
}

enum Status { loading, ready, failed }

// The screen asks the model; the model asks the API.
class MenuModel extends ChangeNotifier {
  MenuModel(this.api);

  final CafeApi api;
  // Three states, one at a time: loading, ready, failed.
  var status = Status.loading;
  var drinks = <Drink>[];
  String? error;

  Future<void> load() async {
    status = Status.loading;
    notifyListeners();
    try {
      drinks = await api.menu();
      status = Status.ready;
    } on Exception catch (e) {
      error = '$e';
      status = Status.failed;
    }
    notifyListeners();
  }
}
