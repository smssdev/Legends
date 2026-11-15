import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/device_tier.dart';
import 'package:glm/core/disk_images.dart';
import 'package:glm/ui/widgets/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [Sprint 74 P3, P5] The phone's tier and what it turns off, and a picture decoded no wider than it is shown.
void main() {
  test('[P3] the first guess from the cores', () {
    expect(DeviceTiers.guess(4), DeviceTier.low);
    expect(DeviceTiers.guess(6), DeviceTier.mid);
    expect(DeviceTiers.guess(8), DeviceTier.high);
  });

  test('[P3] a phone that draws over 15% of its frames late goes down a tier, never up, and not on a few frames', () {
    expect(DeviceTiers.judged(DeviceTier.high, frames: 299, late: 299), DeviceTier.high);
    expect(DeviceTiers.judged(DeviceTier.high, frames: 300, late: 45), DeviceTier.high);
    expect(DeviceTiers.judged(DeviceTier.high, frames: 300, late: 46), DeviceTier.mid);
    expect(DeviceTiers.judged(DeviceTier.mid, frames: 1000, late: 400), DeviceTier.low);
    expect(DeviceTiers.judged(DeviceTier.low, frames: 1000, late: 0), DeviceTier.low);
  });

  test('[P3] the endless motion is off on a low phone, or when the coach asks', () async {
    expect(DeviceTiers.liteFor(DeviceTier.low, asked: false), isTrue);
    expect(DeviceTiers.liteFor(DeviceTier.mid, asked: false), isFalse);
    expect(DeviceTiers.liteFor(DeviceTier.high, asked: true), isTrue);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    addTearDown(() => Ambient.lite = false);
    DeviceTiers.now = DeviceTier.high;
    await DeviceTiers.ask(prefs, true);
    expect(DeviceTiers.asked(prefs), isTrue);
    expect(Ambient.lite, isTrue);
    expect(Ambient.endless, isFalse);
    await DeviceTiers.ask(prefs, false);
    expect(Ambient.lite, isFalse);
  });

  test('[P5] a picture is decoded no wider than its slot, and a smaller one is left alone', () {
    expect(DiskImage.fit(1280, 720, 640), (640, 360));
    expect(DiskImage.fit(300, 200, 640), (300, 200));
    expect(DiskImage.fit(4000, 10, 100), (100, 1));
    expect(const DiskImage('a', cacheWidth: 256) == const DiskImage('a', cacheWidth: 512), isFalse);
    expect(const DiskImage('a', cacheWidth: 256) == const DiskImage('a', cacheWidth: 256), isTrue);
  });
}
