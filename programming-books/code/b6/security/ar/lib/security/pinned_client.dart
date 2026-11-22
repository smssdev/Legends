import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// ثق بهذه الشهادات فقط، لا بقائمة الجهات الموثوقة في الجهاز.
http.Client pinnedClient(List<List<int>> certificates) {
  final context = SecurityContext(withTrustedRoots: false);
  for (final pem in certificates) {
    context.setTrustedCertificatesBytes(pem);
  }
  return IOClient(HttpClient(context: context));
}
