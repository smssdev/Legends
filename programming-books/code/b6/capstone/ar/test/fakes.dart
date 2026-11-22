import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/data/cafe_api.dart';
import 'package:bit_app/data/models.dart';

class FakeApi implements CafeApi {
  var placed = <Map<String, int>>[];

  @override
  Future<List<Drink>> menu() async => const [
    Drink('latte', 'Latte', 'Espresso and steamed milk', 45),
    Drink('cake', 'Cherry cake', 'Baked this morning', 55),
  ];

  @override
  Future<Order> place(Map<String, int> lines) async {
    placed.add(lines);
    return const Order('41', OrderStatus.received);
  }

  @override
  Future<Order> order(String id) async => Order(id, OrderStatus.ready);
}

SharedPreferencesAsync memoryPrefs() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  return SharedPreferencesAsync();
}
