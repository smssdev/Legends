import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:workmanager/workmanager.dart';

import 'orders_api.dart';

// Must be a top-level function, kept by the compiler for the system to call.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    // A real app would build its OrdersApi and Seen here, from its own HTTP client and storage,
    // then: return await syncOrders(api, seen, LocalNotify()) >= 0;
    return true;
  });
}

Future<void> scheduleSync() async {
  await Workmanager().initialize(callbackDispatcher);
  // Android runs periodic work at most every 15 minutes, when the system chooses.
  await Workmanager().registerPeriodicTask(
    'orders-sync',
    'syncOrders',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

class LocalNotify implements Notify {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> orderReady(String id) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin.show(
      id: int.parse(id),
      title: 'Your latte is ready',
      body: 'Order 42 is waiting at the counter.',
      payload: '/orders/$id',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders',
          'Orders',
          channelDescription: 'When your order is ready',
          importance: Importance.high,
        ),
      ),
    );
    debugPrint('notified order $id');
  }
}
