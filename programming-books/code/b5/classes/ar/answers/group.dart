void main() {
  var words = ['تفاح', 'توت', 'موز', 'كرز', 'مانجو'];
  var groups = <String, List<String>>{};
  for (var w in words) {
    groups.putIfAbsent(w[0], () => []).add(w);
  }
  print(groups);
}
