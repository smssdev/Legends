double toFahrenheit(double c) => c * 9 / 5 + 32;

String feel(double c) => switch (c) {
  < 10 => 'بارد',
  < 20 => 'معتدل',
  < 30 => 'دافئ',
  _ => 'حار',
};

void main() {
  for (var c = -10; c <= 40; c += 10) {
    var f = toFahrenheit(c.toDouble());
    print(
      '${c.toString().padLeft(4)} °C = ${f.toStringAsFixed(1).padLeft(5)} °F  ${feel(c.toDouble())}',
    );
  }
}
