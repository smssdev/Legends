class Session {
  const Session(this.version, {required this.crashed});

  final String version;
  final bool crashed;
}

Map<String, double> crashFreeRate(Iterable<Session> sessions) {
  final total = <String, int>{};
  final clean = <String, int>{};
  for (final session in sessions) {
    total.update(session.version, (n) => n + 1, ifAbsent: () => 1);
    if (!session.crashed) {
      clean.update(session.version, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return {
    for (final MapEntry(key: version, value: n) in total.entries)
      version: 100 * (clean[version] ?? 0) / n,
  };
}
