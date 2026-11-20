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
      "Not signed in",
      "Send a valid token: Authorization: Bearer <token>.",
    ),
  badLogin: () => new Problem(401, "Email or password is wrong"),
  forbidden: (role: string) =>
    new Problem(403, "Not allowed", say("This needs the {role} role.", { role })),
  noOrder: (id: number) =>
    new Problem(404, "Not found", say("There is no order {id}.", { id })),
  emailTaken: () => new Problem(409, "Email already registered"),
  invalid: (errors: { field: string; message: string }[]) =>
    new Problem(422, "Invalid body", undefined, { errors }),
  tooMany: (seconds: number) =>
    new Problem(
      429,
      "Too many attempts",
      say("Try again in {seconds} seconds.", { seconds }),
    ),
  server: () => new Problem(500, "Server error"),
};
