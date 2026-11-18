import { createRoot } from "react-dom/client";
import { createMemoryRouter, Link, Outlet, RouterProvider } from "react-router";
import { RouteFocus } from "./RouteFocus";

function Layout() {
  return (
    <>
      <nav className="card" style={{ display: "flex", gap: 12 }}>
        <Link to="/">Home</Link>
        <Link to="/orders">Your orders</Link>
      </nav>
      <main>
        <Outlet />
      </main>
      <RouteFocus appName="Bit's shop" />
    </>
  );
}

const router = createMemoryRouter([
  {
    path: "/",
    element: <Layout />,
    children: [
      { index: true, element: <h1>Home</h1> },
      { path: "orders", element: <h1>Your orders</h1> },
    ],
  },
]);

createRoot(document.getElementById("root")!).render(<RouterProvider router={router} />);
