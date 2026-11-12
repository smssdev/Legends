import 'package:dio/dio.dart';

/// [Sprint 15 F1] The API's errors as one shape: `{message, code, errors?}` with an Arabic message (README «الأخطاء»),
/// or the network's own failure in the app's words.
class ApiError implements Exception {
  const ApiError(this.message, {this.status, this.code, this.fields = const {}});

  final String message;
  final int? status;
  final String? code;

  /// Each field's first message (a form shows it under the field).
  final Map<String, String> fields;

  bool get offline => status == null;
  bool get unauthorized => status == 401;

  static ApiError from(Object e) {
    if (e is ApiError) return e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<dynamic, dynamic>) {
        final errors = <String, String>{};
        final raw = data['errors'];
        if (raw is Map<dynamic, dynamic>) {
          raw.forEach((k, v) {
            if (v is List<dynamic> && v.isNotEmpty) errors['$k'] = '${v.first}';
          });
        }
        return ApiError(
          '${data['message'] ?? 'حدث خطأ، حاول مرة أخرى.'}',
          status: e.response?.statusCode,
          code: data['code'] as String?,
          fields: errors,
        );
      }
      if (e.response != null) return ApiError('حدث خطأ في الخادم، حاول بعد قليل.', status: e.response!.statusCode);
      return const ApiError('تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.');
    }
    return ApiError('$e');
  }

  @override
  String toString() => message;
}
