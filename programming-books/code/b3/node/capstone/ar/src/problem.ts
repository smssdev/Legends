// كل خطأ يخرج بصيغة Problem Details (الفصل 3)
export class Problem extends Error {
  status: number;
  detail?: string;
  extra: Record<string, unknown>;

  constructor(status: number, title: string, detail?: string, extra = {}) {
    super(title);
    this.status = status;
    this.detail = detail;
    this.extra = extra;
  }

  body(instance: string) {
    const { status, detail } = this;
    return {
      title: this.message,
      status,
      ...(detail && { detail }),
      instance,
      ...this.extra,
    };
  }
}

const say = (text: string, values: Record<string, unknown>) =>
  text.replace(/\{(\w+)\}/g, (_, k: string) => String(values[k]));

export const problems = {
  unauthenticated: () =>
    new Problem(
      401,
      "لم تسجّل الدخول",
      "أرسل رمزاً صالحاً: Authorization: Bearer <token>.",
    ),
  badLogin: () => new Problem(401, "البريد أو كلمة المرور خطأ"),
  notFound: () => new Problem(404, "غير موجود"),
  emailTaken: () => new Problem(409, "البريد مسجّل من قبل"),
  outOfStock: (id: number, stock: number) =>
    new Problem(
      409,
      "المخزون لا يكفي",
      say("بقي من المنتج {id}: {stock}.", { id, stock }),
    ),
  keyReused: () =>
    new Problem(
      422,
      "مفتاح Idempotency-Key مستعمل",
      "استُعمل هذا المفتاح بجسم مختلف.",
    ),
  unknownProduct: (id: number) =>
    new Problem(422, "منتج مجهول", undefined, { product_id: id }),
  invalid: (errors: { field: string; message: string }[]) =>
    new Problem(422, "طلب غير صالح", undefined, { errors }),
  tooMany: (seconds: number) =>
    new Problem(
      429,
      "محاولات كثيرة",
      say("حاول بعد {seconds} ثانية.", { seconds }),
    ),
  server: () => new Problem(500, "خطأ في الخادم"),
};
