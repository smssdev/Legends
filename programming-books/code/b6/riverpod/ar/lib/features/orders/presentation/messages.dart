import '../domain/failures.dart';

// كل فشل، بلغة الشخص.
String describe(OrderFailure failure) => switch (failure) {
  EmptyOrder() => 'أضف شيئاً إلى سلتك أولاً.',
  TooLarge() => 'الطلب الواحد يتسع لعشرين قطعة على الأكثر.',
  Closed() => 'المقهى مغلق، ونفتح من 8:00 إلى 22:00 كل يوم.',
  NetworkFailure() => 'لا اتصال. سلتك محفوظة؛ حاول من جديد.',
};
