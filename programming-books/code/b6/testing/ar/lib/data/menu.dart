import 'dart:convert';

import 'package:http/http.dart' as http;

class Drink {
  const Drink(this.id, this.name, this.price);

  factory Drink.fromJson(Map<String, dynamic> json) =>
      Drink(json['id'] as String, json['name'] as String, json['price'] as int);

  final String id;
  final String name;
  final int price;
}

class MenuException implements Exception {
  const MenuException(this.reason);

  final String reason;

  @override
  String toString() => 'MenuException: $reason';
}

// الشاشة تحتاج قائمة، لا HTTP: أي صنف فيه هذه الدالة يكفي.
abstract interface class MenuRepository {
  Future<List<Drink>> menu();
}

class MenuApi implements MenuRepository {
  MenuApi(this.client, {this.base = 'https://api.bitcafe.online'});

  final http.Client client;
  final String base;

  @override
  Future<List<Drink>> menu() async {
    final response = await client.get(Uri.parse('$base/menu'));
    // أي شيء غير 200 فشل تستطيع الشاشة عرضه.
    if (response.statusCode != 200) {
      throw MenuException('status ${response.statusCode}');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return [
      for (final item in items) Drink.fromJson(item as Map<String, dynamic>),
    ];
  }
}
