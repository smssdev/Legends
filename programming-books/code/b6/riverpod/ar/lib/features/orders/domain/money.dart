// المال قيمة: المبلغان متساويان حين يتساوى رقماهما.
class Money implements Comparable<Money> {
  const Money(this.pounds);

  final int pounds;

  Money operator +(Money other) => Money(pounds + other.pounds);
  Money operator *(int times) => Money(pounds * times);

  @override
  int compareTo(Money other) => pounds.compareTo(other.pounds);

  @override
  bool operator ==(Object other) => other is Money && other.pounds == pounds;

  @override
  int get hashCode => pounds.hashCode;
}
