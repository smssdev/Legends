$ dart run enum-missing.dart
enum-missing.dart:4:18: Error: The type 'CupSize' is not exhaustively matched by the switch cases since it doesn't match 'CupSize.large'.
 - 'CupSize' is from 'enum-missing.dart'.
Try adding a wildcard pattern or cases that match 'CupSize.large'.
  return switch (size) {
                 ^
