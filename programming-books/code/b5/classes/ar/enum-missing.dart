enum CupSize { small, medium, large }

String label(CupSize size) {
  return switch (size) {
    CupSize.small => 'كوب صغير',
    CupSize.medium => 'كوب وسط',
  };
}

void main() {
  print(label(CupSize.large));
}
