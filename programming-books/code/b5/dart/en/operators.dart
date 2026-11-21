void main() {
  var score = 10;
  // score += 5 is a short way to write score = score + 5.
  score += 5;
  score++;
  print(score);

  print(score == 16);
  print(score != 16);
  print(score > 10 && score < 20);
  print(score < 10 || score > 15);
  print(!(score > 10));

  print(5 == 5.0);
  print('5' == 5);
}
