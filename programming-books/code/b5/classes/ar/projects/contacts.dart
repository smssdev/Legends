class Contact {
  final String name;
  // الهاتف اختياري: بعض جهات الاتصال بلا هاتف.
  final String? phone;
  const Contact(this.name, {this.phone});

  String describe() => '$name: ${phone ?? 'لا هاتف'}';
}

void main() {
  var contacts = [
    const Contact('سارة', phone: '0100 123 4567'),
    const Contact('عمر'),
    const Contact('منى', phone: '0122 765 4321'),
  ];
  for (var c in contacts) {
    print(c.describe());
  }
  var withPhone = contacts.where((c) => c.phone != null).length;
  print('$withPhone / ${contacts.length}');
  print(contacts.map((c) => c.phone?.replaceAll(' ', '')).toList());
}
