import 'dart:math' as math;

// sealed: these three are the only kinds of Shape, so a switch can cover them all.
sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double radius;
  const Circle(this.radius);
}

class Rect extends Shape {
  final double width, height;
  const Rect(this.width, this.height);
}

class Square extends Shape {
  final double side;
  const Square(this.side);
}

double area(Shape s) => switch (s) {
  Circle(radius: var r) => math.pi * r * r,
  Rect(width: var w, height: var h) => w * h,
  Square(side: var a) => a * a,
};

String name(Shape s) => switch (s) {
  Circle() => 'circle',
  Rect() => 'rectangle',
  Square() => 'square',
};

void main() {
  var shapes = <Shape>[
    const Circle(1.5),
    const Rect(2, 3.5),
    const Square(2.5),
  ];
  shapes.sort((a, b) => area(a).compareTo(area(b)));
  for (var s in shapes) {
    print('${name(s).padRight(10)} area ${area(s).toStringAsFixed(2)}');
  }
  var total = shapes.fold(0.0, (sum, s) => sum + area(s));
  print('Total: ${total.toStringAsFixed(2)}');
  print('largest: ${name(shapes.last)}');
}
