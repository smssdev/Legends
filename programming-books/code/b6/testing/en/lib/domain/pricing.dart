class Line {
  const Line(this.name, this.price, this.quantity);

  final String name;
  final int price;
  final int quantity;
}

// Happy hour: 20% off between 15:00 and 17:00 (17:00 itself is not included).
bool isHappyHour(DateTime time) => time.hour >= 15 && time.hour < 17;

int total(List<Line> lines, DateTime at) {
  final subtotal = lines.fold(
    0,
    (sum, line) => sum + line.price * line.quantity,
  );
  return isHappyHour(at) ? subtotal - subtotal * 20 ~/ 100 : subtotal;
}
