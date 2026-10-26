// The signed-in account for the web (Sanctum session cookie) [PLAN 2.17].
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api, ensureCsrf, type Account } from '../api/client'

export const useAuth = defineStore('auth', () => {
  const user = ref<Account | null>(null)
  const loaded = ref(false)
  const signedIn = computed(() => !!user.value)

  async function load() {
    try {
      const { data } = await api.GET('/auth/me')
      user.value = data?.user ?? null
    } catch {
      user.value = null
    }
    loaded.value = true
  }
  /** Waits for the first load: route guards ask this before deciding. */
  let first: Promise<void> | null = null
  const ready = () => (first ??= load())

  async function login(email: string, password: string, remember: boolean) {
    await ensureCsrf()
    const { data } = await api.POST('/auth/login', { body: { email, password, remember } })
    user.value = data!.user!
  }
  /** [UP5] The name, the username and the password; the session stays until the coach signs out. */
  async function register(name: string, username: string, password: string) {
    await ensureCsrf()
    const { data } = await api.POST('/auth/register', { body: { name, username, password } })
    user.value = data!.user
    return data!.verification_sent !== false
  }
  async function logout() {
    await ensureCsrf()
    await api.POST('/auth/logout')
    user.value = null
  }
  const set = (u: Account | null) => (user.value = u)

  return { user, loaded, signedIn, ready, load, login, register, logout, set }
})
