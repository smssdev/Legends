import { z } from "zod";

// مكان واحد يتحدث إلى الخادم: بالأنواع، ومع التحقق، وبأخطاء تفهمها الشاشات
export const Product = z.object({ id: z.number(), name: z.string(), price: z.number().nonnegative() });
export type Product = z.infer<typeof Product>;

export type ApiError =
  | { kind: "network"; message: string }
  | { kind: "not-found"; path: string }
  | { kind: "invalid"; issues: string[] }
  | { kind: "server"; status: number };

export type Result<T> = { ok: true; data: T } | { ok: false; error: ApiError };

export function createApi(base: string, fetcher: typeof fetch = fetch) {
  async function get<T>(path: string, schema: z.ZodType<T>): Promise<Result<T>> {
    let response: Response;
    try {
      response = await fetcher(base + path, { signal: AbortSignal.timeout(2000) });
    } catch (e) {
      return { ok: false, error: { kind: "network", message: (e as Error).name } };
    }
    if (response.status === 404) return { ok: false, error: { kind: "not-found", path } };
    if (!response.ok) return { ok: false, error: { kind: "server", status: response.status } };
    const parsed = schema.safeParse(await response.json());
    if (!parsed.success) {
      return { ok: false, error: { kind: "invalid", issues: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`) } };
    }
    return { ok: true, data: parsed.data };
  }

  return {
    products: () => get("/products", z.array(Product)),
    product: (id: number) => get(`/products/${id}`, Product),
  };
}
