import { createContext, useContext, useMemo, useState, type ReactNode } from "react";

type User = { name: string };
type Auth = { user: User | null; signIn: (name: string) => void; signOut: () => void };

const AuthContext = createContext<Auth | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const value = useMemo(
    () => ({ user, signIn: (name: string) => setUser({ name }), signOut: () => setUser(null) }),
    [user],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): Auth {
  const auth = useContext(AuthContext);
  if (!auth) throw new Error("useAuth must be used inside <AuthProvider>");
  return auth;
}
