// Each size knows how much it adds to the price.
enum CupSize {
  small(0),
  medium(5),
  large(10);

  final int extra;
  const CupSize(this.extra);
}

String label(CupSize size) {
  // The switch covers every size: the compiler checks it.
  return switch (size) {
    CupSize.small => 'small cup',
    CupSize.medium => 'medium cup',
    CupSize.large => 'large cup',
  };
}

void main() {
  for (var size in CupSize.values) {
    print('${size.name}: ${label(size)}, +${size.extra} EGP');
  }
  print(45 + CupSize.large.extra);
}
