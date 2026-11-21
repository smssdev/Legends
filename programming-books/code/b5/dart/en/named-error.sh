$ dart run named-error.dart
named-error.dart:4:14: Error: Required named parameter 'cups' must be provided.
  print(price(each: 20));
             ^
named-error.dart:1:8: Context: Found this candidate, but the arguments don't match.
double price({required int cups, double each = 12.5}) => cups * each;
       ^^^^^
