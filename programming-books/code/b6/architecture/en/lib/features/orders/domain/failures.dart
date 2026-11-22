// Everything that can go wrong, as types. No text: words belong to the screen.
sealed class OrderFailure {
  const OrderFailure();
}

final class EmptyOrder extends OrderFailure {
  const EmptyOrder();
}

final class TooLarge extends OrderFailure {
  const TooLarge(this.max);
  final int max;
}

final class Closed extends OrderFailure {
  const Closed();
}

final class NetworkFailure extends OrderFailure {
  const NetworkFailure();
}
