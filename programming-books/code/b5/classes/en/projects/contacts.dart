class Contact {
  final String name;
  // phone is optional: some contacts have none.
  final String? phone;
  const Contact(this.name, {this.phone});

  String describe() => '$name: ${phone ?? 'no phone'}';
}

void main() {
  var contacts = [
    const Contact('Sara', phone: '0100 123 4567'),
    const Contact('Omar'),
    const Contact('Mona', phone: '0122 765 4321'),
  ];
  for (var c in contacts) {
    print(c.describe());
  }
  var withPhone = contacts.where((c) => c.phone != null).length;
  print('$withPhone / ${contacts.length}');
  print(contacts.map((c) => c.phone?.replaceAll(' ', '')).toList());
}
