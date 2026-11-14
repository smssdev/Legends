import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [Sprint 65 F3] A control's touch target of at least [min]×[min] (48, Android's guideline, M-A04) without changing how
/// it is drawn or laid out: a 32-high pill in the 42-high bar keeps its size, and the finger and the screen reader find
/// it over the 48 around its centre (the overflow is invisible). The target is one node to a screen reader: the
/// control's own label and actions (a Semantics without container inside) are said on it.
///
/// A finger reaches the overflow only where the parent reaches: inside the bar, the bar's height; on the pitch or in a
/// table, the neighbour drawn after it answers first where the two overlap.
class GlmTarget extends SingleChildRenderObjectWidget {
  const GlmTarget({super.key, this.min = 48, required Widget super.child});

  final double min;

  @override
  RenderGlmTarget createRenderObject(BuildContext context) => RenderGlmTarget(min);

  @override
  void updateRenderObject(BuildContext context, RenderGlmTarget renderObject) => renderObject.min = min;
}

class RenderGlmTarget extends RenderProxyBox {
  RenderGlmTarget(this._min);

  double _min;
  double get min => _min;
  set min(double v) {
    if (v == _min) return;
    _min = v;
    markNeedsSemanticsUpdate();
  }

  /// The child's box grown to [min] each way, around its centre.
  Rect get target {
    final w = math.max(size.width, min), h = math.max(size.height, min);
    return Rect.fromCenter(center: size.center(Offset.zero), width: w, height: h);
  }

  @override
  Rect get semanticBounds => target;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!target.contains(position)) return false;
    // Outside the drawn box, the touch lands on its nearest point, so the control's own InkWell takes it.
    final inside = Offset(position.dx.clamp(0, size.width), position.dy.clamp(0, size.height));
    if (hitTestChildren(result, position: inside) || hitTestSelf(inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
  }
}
