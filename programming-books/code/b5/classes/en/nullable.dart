void main() {
  // String? may hold a String, or null: nothing at all.
  String? nickname;
  print(nickname);

  // ?? gives the value on its right when the left is null.
  print(nickname ?? 'Guest');

  // ?. asks only when there is something to ask: null stays null.
  print(nickname?.length);

  // ??= sets a value only if there is none yet.
  nickname ??= 'Bito';
  print(nickname);

  String? other;
  // Inside this if, Dart knows nickname is not null.
  if (other != null) {
    print(other.length);
  } else {
    print('no nickname');
  }
}
