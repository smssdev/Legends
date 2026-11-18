import { Link, NavLink, Outlet, useParams } from "react-router";
import type { RouteObject } from "react-router";

type Post = { slug: string; title: string; body: string; minutes: number };

const posts: Post[] = [
  { slug: "why-typescript", title: "Why I love TypeScript", body: "Types catch mistakes while I type, so my evenings are free.", minutes: 4 },
  { slug: "rules-for-state", title: "Three rules for state", body: "Keep it minimal, derive the rest, and never change it in place.", minutes: 6 },
  { slug: "keys-explained", title: "Keys, explained", body: "A key tells React which item is which between two renders.", minutes: 3 },
];

function Layout() {
  return (
    <div className="layout">
      <nav>
        <span className="brand">Bit's blog</span>
        <NavLink to="/" end>
          Posts
        </NavLink>
      </nav>
      <Outlet />
    </div>
  );
}

function PostList() {
  return (
    <ul className="list card">
      {posts.map((post) => (
        <li key={post.slug}>
          <Link to={`/posts/${post.slug}`}>{post.title}</Link>
          <span className="muted">
            {post.minutes} min read
          </span>
        </li>
      ))}
    </ul>
  );
}

function PostPage() {
  const { slug } = useParams();
  const post = posts.find((p) => p.slug === slug);
  if (!post) {
    return (
      <p className="card">
        This post does not exist. <Link to="/">Go to the home page</Link>
      </p>
    );
  }
  return (
    <article className="card">
      <h2>{post.title}</h2>
      <p className="muted">
        by Bit · {post.minutes} min read
      </p>
      <p>{post.body}</p>
    </article>
  );
}

export const routes: RouteObject[] = [
  {
    path: "/",
    element: <Layout />,
    children: [
      { index: true, element: <PostList /> },
      { path: "posts/:slug", element: <PostPage /> },
    ],
  },
];
