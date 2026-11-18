import { Link, NavLink, Outlet, useParams, useRouteError, useSearchParams } from "react-router";
import type { RouteObject } from "react-router";
import { useQuery } from "@tanstack/react-query";
import { getProduct, getProducts, NotFoundError } from "./api";

function Layout() {
  return (
    <div className="layout">
      <nav>
        <span className="brand">Bit's shop</span>
        <NavLink to="/" end>
          Home
        </NavLink>
        <NavLink to="/products">Products</NavLink>
      </nav>
      <Outlet />
    </div>
  );
}

function Home() {
  return <p className="card">Welcome! Browse the products, or search for something.</p>;
}

const CATEGORIES = [
  { value: null, label: "All" },
  { value: "books", label: "Books" },
  { value: "gifts", label: "Gifts" },
];

function Products() {
  const [params] = useSearchParams();
  const category = params.get("category");
  const query = useQuery({
    queryKey: ["products", category],
    queryFn: () => getProducts(category),
  });

  return (
    <section className="card">
      <div className="filters">
        {CATEGORIES.map((c) => (
          <Link key={c.label} to={c.value ? `?category=${c.value}` : "."} className={c.value === category ? "on" : ""}>
            {c.label}
          </Link>
        ))}
      </div>
      {query.isPending && <Skeleton />}
      {query.isError && <p className="error">Something went wrong: {query.error.message}</p>}
      {query.isSuccess && (
        <ul className="list">
          {query.data.map((p) => (
            <li key={p.id}>
              <Link to={`/products/${p.id}`}>{p.name}</Link>
              <span className="price">
                {p.price} EGP
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Product() {
  const { id } = useParams();
  const query = useQuery({
    queryKey: ["product", Number(id)],
    queryFn: () => getProduct(Number(id)),
    retry: (count, error) => !(error instanceof NotFoundError) && count < 2,
  });

  if (query.isPending) return <Skeleton />;
  if (query.isError) {
    const missing = query.error instanceof NotFoundError;
    return <p className="card error">{missing ? "There is no product with this number." : query.error.message}</p>;
  }
  const p = query.data;
  return (
    <article className="card">
      <h2>{p.name}</h2>
      <p>{p.description}</p>
      <p className="price">
        {p.price} EGP
      </p>
      <Link to="/products">← Back to products</Link>
    </article>
  );
}

function Skeleton() {
  return (
    <div aria-busy="true" aria-label="Loading…">
      <div className="skeleton" />
      <div className="skeleton" />
    </div>
  );
}

function ErrorPage() {
  const error = useRouteError();
  return (
    <p className="card error">
      Something went wrong: {String(error)}
    </p>
  );
}

function NotFound() {
  return <p className="card">Page not found</p>;
}

export const routes: RouteObject[] = [
  {
    path: "/",
    element: <Layout />,
    errorElement: <ErrorPage />,
    children: [
      { index: true, element: <Home /> },
      { path: "products", element: <Products /> },
      { path: "products/:id", element: <Product /> },
      { path: "*", element: <NotFound /> },
    ],
  },
];
