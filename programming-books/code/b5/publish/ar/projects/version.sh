$ flutter build apk --build-name 1.0.1 --build-number 2
Running Gradle task 'assembleRelease'...                        
Font asset "CupertinoIcons.ttf" was tree-shaken, reducing it from 257628 to 844 bytes (99.7% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 2176 bytes (99.9% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Running Gradle task 'assembleRelease'...                           45.1s
✓ Built build/app/outputs/flutter-apk/app-release.apk (50.2MB)
$ aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "^package|application-label(-ar)?:"
package: name='online.bitcafe.bit_notes' versionCode='2' versionName='1.0.1' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
application-label:'Bit Notes'
application-label-ar:'ملاحظات بِت'
