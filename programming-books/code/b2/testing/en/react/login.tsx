import { createRoot } from "react-dom/client";
import { LoginForm } from "./LoginForm";

createRoot(document.getElementById("root")!).render(
  <main>
    <h1>Bit's shop</h1>
    <LoginForm />
  </main>,
);
