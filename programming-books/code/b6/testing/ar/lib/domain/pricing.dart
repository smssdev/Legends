class Line {
  const Line(this.name, this.price, this.quantity);

  final String name;
  final int price;
  final int quantity;
}

// ساعة السعادة: خصم 20% بين 15:00 و17:00 (والساعة 17:00 نفسها خارجها).
bool isHappyHour(DateTime time) => time.hour >= 15 && time.hour < 17;

int total(List<Line> lines, DateTime at) {
  final subtotal = lines.fold(
    0,
    (sum, line) => sum + line.price * line.quantity,
  );
  return isHappyHour(at) ? subtotal - subtotal * 20 ~/ 100 : subtotal;
}
