import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_scene/scroll_scene.dart';

void main() {
  test('first update seeds without events', () {
    final m = SceneStateMachine();
    expect(m.update(0.4), isEmpty);
    expect(m.isActive, isTrue);
  });

  test('forward pass emits enter then leave', () {
    final m = SceneStateMachine()..update(0);
    expect(m.update(0.3), [SceneEvent.enter]);
    expect(m.direction, SceneDirection.forward);
    expect(m.update(0.7), isEmpty);
    expect(m.update(1), [SceneEvent.leave]);
    expect(m.isActive, isFalse);
  });

  test('backward pass emits enterBack then leaveBack', () {
    final m = SceneStateMachine()..update(1);
    expect(m.update(0.9), [SceneEvent.enterBack]);
    expect(m.direction, SceneDirection.backward);
    expect(m.update(0), [SceneEvent.leaveBack]);
  });

  test('jump across whole scene emits both events in order', () {
    final m = SceneStateMachine()..update(0);
    expect(m.update(1), [SceneEvent.enter, SceneEvent.leave]);
    expect(m.update(0), [SceneEvent.enterBack, SceneEvent.leaveBack]);
  });

  test('no events while inside', () {
    final m = SceneStateMachine()..update(0.2);
    expect(m.update(0.5), isEmpty);
    expect(m.update(0.3), isEmpty);
    expect(m.update(0.3), isEmpty);
  });

  test('reset clears state', () {
    final m = SceneStateMachine()..update(1);
    m.reset();
    expect(m.update(0.5), isEmpty);
  });
}
