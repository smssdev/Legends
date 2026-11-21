enum Day {
  saturday('Saturday'),
  sunday('Sunday'),
  friday('Friday');

  final String label;
  const Day(this.label);

  bool get isWeekend => this == Day.friday || this == Day.saturday;
}

void main() {
  for (var d in Day.values) {
    print('${d.label}: ${d.isWeekend ? 'weekend' : 'workday'}');
  }
}
