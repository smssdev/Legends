$ sh tool/release.sh 42
✓ Built build/app/outputs/flutter-apk/app-prod-release.apk (44.1MB)
$ aapt2 dump badging build/app/outputs/flutter-apk/app-prod-release.apk | grep -E "^package|^application-label:"
package: name='com.example.bit_app' versionCode='42' versionName='1.4.0' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
application-label:'Bit Café'
$ apksigner verify --print-certs build/app/outputs/flutter-apk/app-prod-release.apk | grep DN
Signer #1 certificate DN: CN=Bit Cafe, O=Bit Cafe, C=EG
