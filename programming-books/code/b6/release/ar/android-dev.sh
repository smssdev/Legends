$ flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json -t lib/main_app.dart
✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk
$ aapt2 dump badging build/app/outputs/flutter-apk/app-dev-debug.apk | grep -E "^package|^application-label:"
package: name='com.example.bit_app.dev' versionCode='1' versionName='0.1.0-dev' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
application-label:'Bit Café Dev'
