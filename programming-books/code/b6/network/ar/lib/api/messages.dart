import 'errors.dart';

// كلمات الشاشة لكل خطأ: ويجب أن يغطيها الـ switch كلها.
String message(ApiError e) => switch (e) {
  Offline() => 'لا اتصال. تحقق من الإنترنت وحاول من جديد.',
  TimedOut() => 'المقهى يتأخر في الإجابة. حاول بعد لحظة.',
  Unauthorized() => 'من فضلك سجّل الدخول من جديد.',
  NotFound() => 'لم يُعثر على هذا. ربما حُذف.',
  Rejected(:final message) => message,
  ServerError(status: 429 || 503) => 'المقهى مزدحم جداً. حاول بعد دقيقة.',
  ServerError() => 'حدث خطأ من جهتنا. ونحن نعمل عليه.',
  BadResponse() => 'تعذّرت قراءة إجابة المقهى. من فضلك حدّث التطبيق.',
};
