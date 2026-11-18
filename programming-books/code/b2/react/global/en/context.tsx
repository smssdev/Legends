import { createRoot } from "react-dom/client";
import { AuthProvider, useAuth } from "./auth";

function Header() {
  return (
    <header>
      <span className="brand">Bit's shop</span>
      <UserMenu />
    </header>
  );
}

// Any component under the provider can read the user, however deep
function UserMenu() {
  const { user, signIn, signOut } = useAuth();
  if (!user) return <button onClick={() => signIn("Sara")}>Sign in</button>;
  return (
    <span className="row">
      Hello, {user.name}
      <button className="secondary" onClick={signOut}>
        Sign out
      </button>
    </span>
  );
}

function Profile() {
  const { user } = useAuth();
  return (
    <section className="card">
      <h2>Your profile</h2>
      <p className="muted">{user ? `${user.name} · Member since 2025` : "Guest"}</p>
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
