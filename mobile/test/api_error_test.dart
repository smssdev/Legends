import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_error.dart';

DioException failure(int status, Object data) {
  final r = RequestOptions(path: '/x');
  return DioException(requestOptions: r, response: Response(requestOptions: r, statusCode: status, data: data));
}

void main() {
  test("the API's message and each field's first message", () {
    final e = ApiError.from(failure(422, {'message': 'البيانات غير صحيحة.', 'code' : 'validation', 'errors': {'email': ['البريد أو كلمة المرور غير صحيحة.', 'x']}}));
    expect(e.message, 'البيانات غير صحيحة.');
    expect(e.status, 422);
    expect(e.code, 'validation');
    expect(e.fields, {'email': 'البريد أو كلمة المرور غير صحيحة.'});
  });

  test('no answer from the server is told as offline', () {
    final e = ApiError.from(DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError));
    expect(e.offline, isTrue);
    expect(e.message, contains('الاتصال'));
  });

  test('a refused token is unauthorized', () {
    expect(ApiError.from(failure(401, {'message': 'غير مسجل الدخول.'})).unauthorized, isTrue);
  });
}
