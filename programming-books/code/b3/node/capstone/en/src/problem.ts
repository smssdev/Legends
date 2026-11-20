// every error leaves as Problem Details (Chapter 3)
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
      "Not signed in",
      "Send a valid token: Authorization: Bearer <token>.",
    ),
  badLogin: () => new Problem(401, "Email or password is wrong"),
  notFound: () => new Problem(404, "Not found"),
  emailTaken: () => new Problem(409, "Email already registered"),
  outOfStock: (id: number, stock: number) =>
    new Problem(
      409,
      "Not enough stock",
      say("Product {id} has {stock} left.", { id, stock }),
    ),
  keyReused: () =>
    new Problem(
      422,
      "Idempotency-Key reused",
      "This key was used with a different body.",
    ),
  unknownProduct: (id: number) =>
    new Problem(422, "Unknown product", undefined, { product_id: id }),
  invalid: (errors: { field: string; message: string }[]) =>
    new Problem(422, "Invalid request", undefined, { errors }),
  tooMany: (seconds: number) =>
    new Problem(
      429,
      "Too many attempts",
      say("Try again in {seconds} seconds.", { seconds }),
    ),
  server: () => new Problem(500, "Server error"),
};
