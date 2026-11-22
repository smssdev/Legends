import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/messages.dart';

void main() {
  test('لكل خطأ كلمات، بلغة الشخص', () {
    expect(
      message(const Offline()),
      'لا اتصال. تحقق من الإنترنت وحاول من جديد.',
    );
    expect(
      message(const ServerError(503)),
      'المقهى مزدحم جداً. حاول بعد دقيقة.',
    );
    expect(
      message(const ServerError(500)),
      'حدث خطأ من جهتنا. ونحن نعمل عليه.',
    );
    expect(message(const Rejected(409, 'Sold out')), 'Sold out');
  });
}
