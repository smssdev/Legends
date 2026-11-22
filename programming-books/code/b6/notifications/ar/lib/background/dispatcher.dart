import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:workmanager/workmanager.dart';

import 'orders_api.dart';

// يجب أن تكون دالة في أعلى الملف، يُبقيها المترجم ليناديها النظام.
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
  // Android يشغّل العمل الدوري كل 15 دقيقة على الأكثر، حين يختار النظام.
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
      title: 'اللاتيه جاهز',
      body: 'الطلب 42 ينتظرك عند المنضدة.',
      payload: '/orders/$id',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders',
          'الطلبات',
          channelDescription: 'حين يجهز طلبك',
          importance: Importance.high,
        ),
      ),
    );
    debugPrint('notified order $id');
  }
}
