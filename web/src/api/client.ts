// The API client, typed from docs/api/openapi.yaml (`npm run api` regenerates schema.d.ts;
// CI fails when it is out of date). Every error comes back in one shape, in Arabic (ApiErrors.php).
// The web signs in with Sanctum's session cookie: every request carries the XSRF token.
import createClient, { type Middleware } from 'openapi-fetch'
import type { components, paths } from './schema'
import { locale, t } from '../lib/i18n'
import { useToast } from '../stores/toast'

export type ApiErrorBody = components['schemas']['Error']
export type Account = components['schemas']['Account']

export class ApiError extends Error {
  readonly status: number
  readonly code: string
  readonly errors: Record<string, string[]>
  constructor(status: number, body: { message?: string; code?: string; errors?: Record<string, string[]> }) {
    super(body.message ?? t('حدث خطأ غير متوقع، حاول مجدداً.'))
    this.status = status
    this.code = body.code ?? 'server_error'
    this.errors = body.errors ?? {}
  }

  /** The first message for a field, for under its input. */
  field(name: string): string {
    return this.errors[name]?.[0] ?? ''
  }
}

function cookie(name: string): string {
  const m = document.cookie.match(new RegExp('(?:^|; )' + name + '=([^;]*)'))
  return m ? decodeURIComponent(m[1]) : ''
}

// [X50] Each request as it was before it went, so one refused for an expired session (419) is sent once more.
const unsent = new WeakMap<Request, Request>()
const session: Middleware = {
  onRequest({ request }) {
    const xsrf = cookie('XSRF-TOKEN')
    if (xsrf) request.headers.set('X-XSRF-TOKEN', xsrf)
    request.headers.set('Accept-Language', locale.value)   // [UP2] the server's words in the coach's language
    unsent.set(request, request.clone())
    return request
  },
  async onResponse({ request, response }) {
    if (response.ok) return response
    // [X50] The session ended under the page (a deploy, a restart): a new XSRF token, then the same request again.
    // The remember-me cookie signs the coach back in on it, so the tap still does what it should.
    const again = unsent.get(request)
    if (response.status === 419 && again && !again.headers.has('X-Retried')) {
      csrf = null
      await ensureCsrf()
      again.headers.set('X-XSRF-TOKEN', cookie('XSRF-TOKEN'))
      again.headers.set('X-Retried', '1')
      const retried = await fetch(again)
      if (retried.ok) return retried
      response = retried
    }
    const body = await response.clone().json().catch(() => ({}))
    const error = new ApiError(response.status, body)
    failed(request, error)
    throw error
  },
  // [Sprint 30 Q3] No answer at all (offline, the server down) on a tap that changes something: said at once too.
  onError({ request }) {
    const error = asApiError(null)
    failed(request, error)
    return error
  },
}

/**
 * [Sprint 30 Q3] A tap that changes something and fails is never silent: the error also shows in the one toast at the
 * top of the screen, whatever the page does with it (its message may sit out of sight). Not the field errors (422,
 * under their inputs), nor the sign-in (401) and the admin's code (423) that their screens ask for; and the same
 * message once in a short while.
 */
let lastToast = { text: '', at: 0 }
function failed(request: Request, error: ApiError) {
  if (request.method === 'GET' || [401, 419, 422, 423].includes(error.status)) return
  const now = Date.now()
  if (error.message === lastToast.text && now - lastToast.at < 2500) return
  lastToast = { text: error.message, at: now }
  try {
    useToast().show(t(error.message), 'error', 4500)
  } catch { /* before the app has its store: the page's own message is enough */ }
}

export const api = createClient<paths>({ baseUrl: '/api/v1', headers: { Accept: 'application/json' }, credentials: 'same-origin' })
api.use(session)

/** Sanctum's XSRF cookie, once, before the first request that changes something. */
let csrf: Promise<unknown> | null = null
export function ensureCsrf(): Promise<unknown> {
  if (!cookie('XSRF-TOKEN')) csrf = null
  return (csrf ??= fetch('/sanctum/csrf-cookie', { credentials: 'same-origin' }))
}

/** For a network failure (no answer at all), the same Arabic error the screens show. */
export function asApiError(e: unknown): ApiError {
  return e instanceof ApiError ? e : new ApiError(0, { message: t('تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.'), code: 'offline' })
}
