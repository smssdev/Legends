// كل حجم يعرف كم يضيف إلى السعر.
enum CupSize {
  small(0),
  medium(5),
  large(10);

  final int extra;
  const CupSize(this.extra);
}

String label(CupSize size) {
  // الـ switch يغطي كل الأحجام: والمترجم يتحقق من ذلك.
  return switch (size) {
    CupSize.small => 'كوب صغير',
    CupSize.medium => 'كوب وسط',
    CupSize.large => 'كوب كبير',
  };
}

void main() {
  for (var size in CupSize.values) {
    print('${size.name}: ${label(size)}, +${size.extra} جنيه');
  }
  print(45 + CupSize.large.extra);
}
