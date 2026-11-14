import 'package:flutter_test/flutter_test.dart';
import 'package:glm/api/gen/models.g.dart' as api;
import 'package:glm/features/sim/first_match_controller.dart';

api.IntroMoment moment(String kind, int minute) => api.IntroMoment.fromJson({'kind': kind, 'minute': minute, 'title': kind, 'text': kind});

void main() {
  test('[Sprint 64 F1] each moment from its minute until answered, one at a time, none once over', () {
    final moments = [moment('style', 20), moment('effect', 28), moment('sub', 60)];
    IntroCoachState s = (answered: <String>{}, over: false);
    expect(IntroCoach.current(moments, s, 10), isNull);
    expect(IntroCoach.current(moments, s, 30)?.kind, 'style');
    s = (answered: {'style'}, over: false);
    expect(IntroCoach.current(moments, s, 30)?.kind, 'effect');
    s = (answered: {'style', 'effect'}, over: false);
    expect(IntroCoach.current(moments, s, 30), isNull);
    expect(IntroCoach.current(moments, s, 61)?.kind, 'sub');
    s = (answered: {'style', 'effect'}, over: true);
    expect(IntroCoach.current(moments, s, 61), isNull);
  });
}
