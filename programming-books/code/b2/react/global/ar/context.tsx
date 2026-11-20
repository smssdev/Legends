import { createRoot } from "react-dom/client";
import { AuthProvider, useAuth } from "./auth";

function Header() {
  return (
    <header>
      <span className="brand">متجر بِت</span>
      <UserMenu />
    </header>
  );
}

// أي مكوّن تحت المزوّد يقرأ المستخدم، مهما كان عمقه
function UserMenu() {
  const { user, signIn, signOut } = useAuth();
  if (!user) return <button onClick={() => signIn("سارة")}>سجّل الدخول</button>;
  return (
    <span className="row">
      أهلاً، {user.name}
      <button className="secondary" onClick={signOut}>
        سجّل الخروج
      </button>
    </span>
  );
}

function Profile() {
  const { user } = useAuth();
  return (
    <section className="card">
      <h2>ملفك الشخصي</h2>
      <p className="muted">{user ? `${user.name} · عضو منذ 2025` : "زائر"}</p>
    </section>
  );
}

createRoot(document.getElementById("root")!).render(
  <AuthProvider>
    <Header />
    <main>
      <Profile />
    </main>
  </AuthProvider>,
);
