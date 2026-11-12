import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

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

  /// [Sprint 59 F9] The app's language for the network's own failures (no screen at hand): the app sets it with its
  /// locale, and Arabic before that.
  static Locale locale = const Locale('ar');
  static L get _words => lookupL(locale);

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
          '${data['message'] ?? _words.errorUnknown}',
          status: e.response?.statusCode,
          code: data['code'] as String?,
          fields: errors,
        );
      }
      if (e.response != null) return ApiError(_words.errorServer, status: e.response!.statusCode);
      return ApiError(_words.errorOffline);
    }
    return ApiError('$e');
  }

  @override
  String toString() => message;
}
