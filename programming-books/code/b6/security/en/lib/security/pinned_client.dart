import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Trust only these certificates, not the device's list of authorities.
http.Client pinnedClient(List<List<int>> certificates) {
  final context = SecurityContext(withTrustedRoots: false);
  for (final pem in certificates) {
    context.setTrustedCertificatesBytes(pem);
  }
  return IOClient(HttpClient(context: context));
}
