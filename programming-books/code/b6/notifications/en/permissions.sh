$ aapt2 dump permissions build/app/outputs/flutter-apk/app-debug.apk
package: com.example.bit_app
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.WAKE_LOCK'
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
uses-permission: name='android.permission.POST_NOTIFICATIONS'
uses-permission: name='android.permission.VIBRATE'
uses-permission: name='android.permission.FOREGROUND_SERVICE'
uses-permission: name='android.permission.FOREGROUND_SERVICE_SHORT_SERVICE'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='com.google.android.c2dm.permission.RECEIVE'
permission: com.example.bit_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: name='com.example.bit_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
