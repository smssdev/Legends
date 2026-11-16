import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/device_tier.dart';
import 'package:glm/core/frame_stats.dart';
import 'package:mocktail/mocktail.dart';

class _Dio extends Mock implements Dio {}

/// [Sprint 74 P2] The frames counted per screen and sent as counts: nothing but the screen, the version and the tier.
void main() {
  setUp(FrameStats.clear);

  test('frames are counted per screen, late ones apart, and a screen seen a moment is left out', () {
    for (var i = 0; i < 100; i++) {
      FrameStats.add('/leagues/8/squad?tab=1', i < 70 ? 10 : (i < 90 ? 20 : 40));
    }
    for (var i = 0; i < 30; i++) {
      FrameStats.add('/wallet', 50);
    }
    final r = FrameStats.describe(platform: 'android', version: '2.5.3', tier: DeviceTier.low)!;
    expect(r.keys.toSet(), {'platform', 'version', 'tier', 'screens'});
    expect(r['tier'], 'low');
    expect(r['screens'], [
      {'path': '/leagues/8/squad', 'frames': 100, 'late16': 30, 'late33': 10},
    ]);
  });

  test('nothing counted, nothing sent; what is sent is forgotten', () {
    expect(FrameStats.describe(platform: 'android', version: '2.5.3', tier: DeviceTier.mid), isNull);
    final dio = _Dio();
    when(() => dio.post<void>(any(), data: any(named: 'data'))).thenAnswer((_) async => Response<void>(requestOptions: RequestOptions()));
    FrameStats.client = dio;
    FrameStats.enabled = true;
    addTearDown(() => FrameStats.enabled = false);
    FrameStats.send();
    verifyNever(() => dio.post<void>(any(), data: any(named: 'data')));
    for (var i = 0; i < 80; i++) {
      FrameStats.add('/home', 8);
    }
    FrameStats.send();
    final body = verify(() => dio.post<void>('/client-frames', data: captureAny(named: 'data'))).captured.single as Map<String, Object>;
    expect((body['screens']! as List).single, {'path': '/home', 'frames': 80, 'late16': 0, 'late33': 0});
    FrameStats.send(); // already sent: nothing left
    verifyNever(() => dio.post<void>(any(), data: any(named: 'data')));
  });
}
