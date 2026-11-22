// شكل البيانات على الشبكة. يتغير حين يتغير الخادم؛ أما الكيان فلا.
class OrderDto {
  const OrderDto({
    required this.id,
    required this.items,
    required this.status,
    required this.placedAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) => OrderDto(
    id: json['id'] as int,
    items: (json['items'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    status: json['status'] as String,
    placedAt: json['placed_at'] as String,
  );

  final int id;
  final Map<String, int> items;
  final String status;
  final String placedAt;
}
