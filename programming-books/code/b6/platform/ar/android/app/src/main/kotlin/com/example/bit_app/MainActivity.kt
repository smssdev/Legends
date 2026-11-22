package com.example.bit_app

import android.app.ActivityManager
import android.content.Context
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val device = AndroidDevice(this)

        // القناة نفسها باليد، بـ Kotlin.
        MethodChannel(messenger, "bitcafe/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> device.info().let {
                    result.success(mapOf("system" to it.system, "version" to it.version, "memoryMb" to it.memoryMb))
                }
                else -> result.notImplemented()
            }
        }

        DeviceApi.setUp(messenger, device)
    }
}

// واجهة Pigeon بـ Kotlin: المترجم يطابقها مع الواجهة المولَّدة.
class AndroidDevice(private val context: Context) : DeviceApi {
    override fun info(): DeviceInfo {
        val memory = ActivityManager.MemoryInfo()
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memory)
        return DeviceInfo(system = "Android", version = Build.VERSION.RELEASE, memoryMb = memory.totalMem / (1024 * 1024))
    }

    override fun batteryLevel(): Long {
        val battery = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        if (level <= 0) {
            throw FlutterError("UNAVAILABLE", "This device has no battery.", null)
        }
        return level.toLong()
    }
}
