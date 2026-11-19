import { messages as m, say } from "./messages.ts";

// Errors as Problem Details (RFC 9457): one format for every error the API returns.
export class Problem extends Error {
  status: number;
  slug: string;
  title: string;
  detail?: string;
  extra: Record<string, unknown>;

  constructor(
    status: number,
    slug: string,
    title: string,
    detail?: string,
    extra = {},
  ) {
    super(title);
    this.status = status;
    this.slug = slug;
    this.title = title;
    this.detail = detail;
    this.extra = extra;
  }

  body(instance: string) {
    return {
      // every problem type has its own page of documentation at this address
      type: `https://bit-shop.example/problems/${this.slug}`,
      title: this.title,
      status: this.status,
      ...(this.detail && { detail: this.detail }),
      instance,
      ...this.extra,
    };
  }
}

type Errors = { field: string; message: string }[];

// Every problem the API can return, so routes never invent their own.
export const problems = {
  invalidRequest: (errors: Errors) =>
    new Problem(400, "invalid-request", m.invalidRequest, undefined, { errors }),
  invalidBody: (errors: Errors) =>
    new Problem(422, "invalid-body", m.invalidBody, undefined, { errors }),
  noProduct: (id: number) =>
    new Problem(404, "not-found", m.notFound, say(m.noProduct, { id })),
  noOrder: (id: number) =>
    new Problem(404, "not-found", m.notFound, say(m.noOrder, { id })),
  needIfMatch: () =>
    new Problem(
      428,
      "precondition-required",
      m.preconditionRequired,
      m.needIfMatch,
    ),
  stale: () => new Problem(412, "stale", m.stale, m.staleDetail),
  keyReused: () =>
    new Problem(422, "idempotency-key-reused", m.keyReused, m.keyReusedDetail),
  inProgress: () =>
    new Problem(409, "in-progress", m.inProgress, m.inProgressDetail),
  outOfStock: (id: number, stock: number) =>
    new Problem(
      409,
      "out-of-stock",
      m.outOfStock,
      say(m.outOfStockDetail, { id, stock }),
    ),
  unknownProduct: (id: number) =>
    new Problem(422, "unknown-product", m.unknownProduct, say(m.noProduct, { id })),
  cannotCancel: (id: number, status: string) =>
    new Problem(
      409,
      "invalid-state",
      m.cannotCancel,
      say(m.cannotCancelDetail, { id, status }),
    ),
  tooManyRequests: (seconds: number) =>
    new Problem(
      429,
      "too-many-requests",
      m.tooManyRequests,
      say(m.tooManyRequestsDetail, { seconds }),
    ),
  server: () => new Problem(500, "server-error", m.serverError),
};
