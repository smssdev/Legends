enum CupSize { small, medium, large }

String label(CupSize size) {
  return switch (size) {
    CupSize.small => 'small cup',
    CupSize.medium => 'medium cup',
  };
}

void main() {
  print(label(CupSize.large));
}
