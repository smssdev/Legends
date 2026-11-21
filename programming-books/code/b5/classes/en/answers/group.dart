void main() {
  var words = ['apple', 'avocado', 'banana', 'cherry', 'blueberry'];
  var groups = <String, List<String>>{};
  for (var w in words) {
    groups.putIfAbsent(w[0], () => []).add(w);
  }
  print(groups);
}
