// The API client, typed from docs/api/openapi.yaml (`npm run api` regenerates schema.d.ts;
// CI fails when it is out of date). Every error comes back in one shape, in Arabic (ApiErrors.php).
import createClient, { type Middleware } from 'openapi-fetch'
import type { components, paths } from './schema'

export type ApiErrorBody = components['schemas']['Error']

export class ApiError extends Error {
  readonly status: number
  readonly code: string
  readonly errors: Record<string, string[]>
  constructor(status: number, body: Partial<ApiErrorBody>) {
    super(body.message ?? 'حدث خطأ غير متوقع، حاول مجدداً.')
    this.status = status
    this.code = body.code ?? 'server_error'
    this.errors = body.errors ?? {}
  }
}

const errors: Middleware = {
  async onResponse({ response }) {
    if (response.ok) return response
    const body = await response.clone().json().catch(() => ({}))
    throw new ApiError(response.status, body)
  },
}

export const api = createClient<paths>({ baseUrl: '/api/v1', headers: { Accept: 'application/json' } })
api.use(errors)

/** For a network failure (no answer at all), the same Arabic error the screens show. */
export function asApiError(e: unknown): ApiError {
  return e instanceof ApiError ? e : new ApiError(0, { message: 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.', code: 'offline' as never })
}
