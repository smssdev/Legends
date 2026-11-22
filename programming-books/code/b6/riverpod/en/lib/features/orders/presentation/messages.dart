import '../domain/failures.dart';

// Each failure, in the person's language.
String describe(OrderFailure failure) => switch (failure) {
  EmptyOrder() => 'Add something to your basket first.',
  TooLarge() => 'One order can hold at most 20 items.',
  Closed() => 'The café is closed. We open from 8:00 to 22:00.',
  NetworkFailure() => 'No connection. Your basket is kept; try again.',
};
