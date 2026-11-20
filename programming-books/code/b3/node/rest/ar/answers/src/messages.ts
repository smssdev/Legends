// كل نص يقرؤه إنسان في مكان واحد: سهل المراجعة، سهل الترجمة.
// تملأ say() الأماكن بين الأقواس {}.
export const messages = {
  invalidRequest: "طلب غير صالح",
  invalidBody: "محتوى غير صالح",
  notFound: "غير موجود",
  noProduct: "لا يوجد منتج رقمه {id}.",
  noOrder: "لا يوجد طلب رقمه {id}.",
  preconditionRequired: "شرط مسبق مطلوب",
  needIfMatch: "أرسل If-Match مع آخر ETag قرأته.",
  stale: "تغيّر المنتج",
  staleDetail: "غيّره أحد بعد أن قرأته. اقرأه من جديد.",
  keyReused: "مفتاح عدم التكرار مستخدم",
  keyReusedDetail: "استُخدم هذا المفتاح مع محتوى مختلف.",
  inProgress: "الطلب قيد التنفيذ",
  inProgressDetail: "ما زال طلب بهذا المفتاح يعمل.",
  outOfStock: "المخزون لا يكفي",
  outOfStockDetail: "بقي {stock} فقط من المنتج {id}.",
  unknownProduct: "منتج مجهول",
  cannotCancel: "لا يمكن إلغاء الطلب",
  cannotCancelDetail: "الطلب {id} حالته {status} من قبل.",
  tooManyRequests: "طلبات كثيرة جداً",
  tooManyRequestsDetail: "حاول مرة أخرى بعد {seconds} ثانية.",
  serverError: "خطأ في الخادم",
  emptyPatch: "أرسل حقلاً واحداً على الأقل لتغييره.",
};

export function say(
  text: string,
  values: Record<string, string | number> = {},
): string {
  return text.replace(/\{(\w+)\}/g, (_, key: string) => String(values[key]));
}
