import 'package:flutter/foundation.dart';
import 'package:glm/core/live/live_channels.dart';

/// [Sprint 53] The match's channel, played by the test: it says when it is subscribed and pushes what the server would.
class FakeFeed implements LiveFeed {
  final handlers = <String, void Function(Map<String, dynamic>)>{};
  final channels = <String>[];
  final sub = FakeSubscription();

  @override
  LiveSubscription join(String name, Map<String, void Function(Map<String, dynamic>)> on) {
    channels.add(name);
    handlers.addAll(on);
    return sub;
  }

  void push(String event, Map<String, dynamic> data) => handlers[event]!(data);
}

class FakeSubscription implements LiveSubscription {
  final _subscribed = ValueNotifier(false);
  bool left = false;

  @override
  ValueListenable<bool> get subscribed => _subscribed;
  set on(bool v) => _subscribed.value = v;

  @override
  void leave() => left = true;
}
