class Drink {
  const Drink(this.id, this.name, this.about, this.price);

  factory Drink.fromJson(Map<String, Object?> json) => Drink(
    json['id']! as String,
    json['name']! as String,
    json['about']! as String,
    json['price']! as int,
  );

  final String id;
  final String name;
  final String about;
  final int price;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'about': about,
    'price': price,
  };
}

enum OrderStatus { received, preparing, ready }

class Order {
  const Order(this.id, this.status);

  final String id;
  final OrderStatus status;
}
