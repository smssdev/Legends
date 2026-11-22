import 'dart:convert';

import 'package:http/http.dart' as http;

import 'orders_source.dart';

// The same repository, with a real HTTP source: the domain does not change.
class HttpOrdersSource implements OrdersSource {
  HttpOrdersSource(this.client, {this.base = 'https://api.example.com'});

  final http.Client client;
  final String base;

  @override
  Future<Map<String, dynamic>> post(Map<String, int> items) async {
    final response = await client
        .post(
          Uri.parse('$base/orders'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'items': items}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> list() async {
    final response = await client.get(Uri.parse('$base/orders'));
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List)
        .cast<Map<String, dynamic>>();
  }
}
