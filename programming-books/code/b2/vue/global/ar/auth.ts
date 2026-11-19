import { inject, provide, readonly, ref, type InjectionKey, type Ref } from "vue";

type User = { name: string };
type Auth = { user: Readonly<Ref<User | null>>; signIn: (name: string) => void; signOut: () => void };

// مفتاح بنوعه: تعرف inject() نوع ما قُدِّم
const AuthKey: InjectionKey<Auth> = Symbol("auth");

export function provideAuth() {
  const user = ref<User | null>(null);
  provide(AuthKey, {
    user: readonly(user),
    signIn: (name) => (user.value = { name }),
    signOut: () => (user.value = null),
  });
}

// composable يخفي inject()، ويفشل بوضوح إن غاب المزوِّد
export function useAuth(): Auth {
  const auth = inject(AuthKey);
  if (!auth) throw new Error("useAuth() must be used inside a component that called provideAuth()");
  return auth;
}
