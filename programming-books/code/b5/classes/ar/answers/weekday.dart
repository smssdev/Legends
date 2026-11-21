enum Day {
  saturday('السبت'),
  sunday('الأحد'),
  friday('الجمعة');

  final String label;
  const Day(this.label);

  bool get isWeekend => this == Day.friday || this == Day.saturday;
}

void main() {
  for (var d in Day.values) {
    print('${d.label}: ${d.isWeekend ? 'عطلة' : 'يوم عمل'}');
  }
}
