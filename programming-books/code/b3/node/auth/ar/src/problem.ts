// Errors as Problem Details, as in Chapter 3, with only the problems this API needs.
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
  forbidden: (role: string) =>
    new Problem(403, "غير مسموح", say("هذا يحتاج الدور {role}.", { role })),
  noOrder: (id: number) =>
    new Problem(404, "غير موجود", say("لا يوجد طلب {id}.", { id })),
  emailTaken: () => new Problem(409, "البريد مسجّل من قبل"),
  invalid: (errors: { field: string; message: string }[]) =>
    new Problem(422, "جسم غير صالح", undefined, { errors }),
  tooMany: (seconds: number) =>
    new Problem(
      429,
      "محاولات كثيرة",
      say("حاول مرة أخرى بعد {seconds} ثانية.", { seconds }),
    ),
  server: () => new Problem(500, "خطأ في الخادم"),
};
