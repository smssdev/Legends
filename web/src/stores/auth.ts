// The signed-in account for the web (Sanctum session cookie) [PLAN 2.17].
import { storage } from '../lib/storage'
import { defineStore } from 'pinia'
import { track } from '../lib/analytics'
import { computed, ref } from 'vue'
import { api, ApiError, ensureCsrf, type Account } from '../api/client'
import { adoptLocale } from '../lib/i18n'
import { boot, rebootSession } from '../lib/session'
import { useBot } from './bot'
import { useBoard } from './board'

export const useAuth = defineStore('auth', () => {
  const user = ref<Account | null>(null)
  const loaded = ref(false)
  const signedIn = computed(() => !!user.value)
  /**
   * [Sprint 51 W3] The server did not answer who is signed in (offline, a deploy, an error): not the same as signed out.
   * The guard then keeps the coach where he is and App.vue offers to try again, instead of sending him to the login.
   */
  const unreachable = ref(false)

  async function load() {
    for (let attempt = 0; ; attempt++) {
      try {
        // [Sprint 58 W1] From the visit's start (GET /bootstrap), shared with the shell's stores.
        const data = await boot()
        user.value = (data.user ?? null) as Account | null
        unreachable.value = false
        adoptLocale(user.value?.locale)
        break
      } catch (e) {
        // Refused (401, 419): signed out. Anything else is the server or the network: twice more, a second apart.
        if (e instanceof ApiError && [401, 419].includes(e.status)) {
          user.value = null
          unreachable.value = false
          break
        }
        if (attempt >= 2) {
          unreachable.value = true
          break
        }
        await new Promise((r) => setTimeout(r, 1000))
      }
    }
    loaded.value = true
  }
  /** Waits for the first load: route guards ask this before deciding. */
  let first: Promise<void> | null = null
  const ready = () => (first ??= load())
  /** «حاول مجدداً» after the server did not answer. */
  async function retry() {
    rebootSession()
    first = load()
    await first
  }

  async function login(email: string, password: string, remember: boolean) {
    await ensureCsrf()
    const { data } = await api.POST('/auth/login', { body: { email, password, remember } })
    user.value = data!.user!
    adoptLocale(user.value.locale)
    rebootSession()
    track('login')
  }
  /** [UP5] The name, the username and the password; the session stays until the coach signs out. */
  async function register(name: string, username: string, password: string) {
    await ensureCsrf()
    // [Sprint 21 E2.3] The inviter's number from an invite link opened on this device.
    let ref: number | undefined
    try {
      ref = Number(storage.get('ref')) || undefined
    } catch {}
    const { data } = await api.POST('/auth/register', { body: { name, username, password, ref } })
    user.value = data!.user
    rebootSession()
    track('sign_up')
    return data!.verification_sent !== false
  }
  async function logout() {
    await ensureCsrf()
    await api.POST('/auth/logout')
    user.value = null
    rebootSession()
    // [Sprint 58 W6] The club board's refresh stops with the account.
    useBoard().pause()
    // [Sprint 51 W5] The Assistant Coach's conversation stays with the account, not on a shared device.
    useBot().forget(true)
  }
  const set = (u: Account | null) => (user.value = u)

  return { user, loaded, signedIn, unreachable, ready, load, retry, login, register, logout, set }
})
