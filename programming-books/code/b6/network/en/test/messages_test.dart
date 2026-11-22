import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/messages.dart';

void main() {
  test('every error has words, in the language of the person', () {
    expect(
      message(const Offline()),
      'No connection. Check your internet and try again.',
    );
    expect(
      message(const ServerError(503)),
      'The café is very busy. Try again in a minute.',
    );
    expect(
      message(const ServerError(500)),
      'Something went wrong on our side. We are on it.',
    );
    expect(message(const Rejected(409, 'Sold out')), 'Sold out');
  });
}
