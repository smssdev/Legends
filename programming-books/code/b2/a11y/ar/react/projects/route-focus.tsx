import { createRoot } from "react-dom/client";
import { createMemoryRouter, Link, Outlet, RouterProvider } from "react-router";
import { RouteFocus } from "./RouteFocus";

function Layout() {
  return (
    <>
      <nav className="card" style={{ display: "flex", gap: 12 }}>
        <Link to="/">الرئيسية</Link>
        <Link to="/orders">طلباتك</Link>
      </nav>
      <main>
        <Outlet />
      </main>
      <RouteFocus appName="متجر بِت" />
    </>
  );
}

const router = createMemoryRouter([
  {
    path: "/",
    element: <Layout />,
    children: [
      { index: true, element: <h1>الرئيسية</h1> },
      { path: "orders", element: <h1>طلباتك</h1> },
    ],
  },
]);

createRoot(document.getElementById("root")!).render(<RouterProvider router={router} />);
