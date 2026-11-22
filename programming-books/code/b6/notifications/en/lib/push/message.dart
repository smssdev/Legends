// What the server may send. Anything else is ignored, not guessed.
enum PushKind { orderReady, orderUpdate, promo }

class PushMessage {
  const PushMessage(this.kind, {this.orderId, this.title, this.body});

  final PushKind kind;
  final String? orderId;
  final String? title;
  final String? body;

  // FCM delivers a message's data as a map of strings.
  static PushMessage? fromData(Map<String, Object?> data) {
    final kind = switch (data['type']) {
      'order_ready' => PushKind.orderReady,
      'order_update' => PushKind.orderUpdate,
      'promo' => PushKind.promo,
      _ => null,
    };
    if (kind == null) {
      return null;
    }
    final orderId = data['order_id'] as String?;
    if (kind != PushKind.promo &&
        (orderId == null || !RegExp(r'^\d+$').hasMatch(orderId))) {
      return null;
    }
    return PushMessage(
      kind,
      orderId: orderId,
      title: data['title'] as String?,
      body: data['body'] as String?,
    );
  }

  // A message knows where it leads; the app decides when to go there.
  String get route => switch (kind) {
    PushKind.orderReady || PushKind.orderUpdate => '/orders/$orderId',
    PushKind.promo => '/',
  };
}
