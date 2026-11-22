$ flutter build apk --debug --flavor staging --dart-define-from-file=config/staging.json -t lib/main_app.dart
✓ Built build/app/outputs/flutter-apk/app-staging-debug.apk
$ aapt2 dump badging build/app/outputs/flutter-apk/app-staging-debug.apk | grep -E "^package|^application-label:"
package: name='com.example.bit_app.staging' versionCode='1' versionName='0.1.0-staging' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
application-label:'Bit Café Staging'
