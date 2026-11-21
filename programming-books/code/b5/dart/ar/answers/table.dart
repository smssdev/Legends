void main() {
  for (var row = 1; row <= 9; row++) {
    var line = StringBuffer();
    for (var col = 1; col <= 9; col++) {
      line.write((row * col).toString().padLeft(4));
    }
    print(line);
  }
}
