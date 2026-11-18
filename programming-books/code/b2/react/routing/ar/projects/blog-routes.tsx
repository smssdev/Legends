import { Link, NavLink, Outlet, useParams } from "react-router";
import type { RouteObject } from "react-router";

type Post = { slug: string; title: string; body: string; minutes: number };

const posts: Post[] = [
  { slug: "why-typescript", title: "لماذا أحب TypeScript", body: "الأنواع تلتقط الأخطاء وأنا أكتب، فتبقى أمسياتي فارغة.", minutes: 4 },
  { slug: "rules-for-state", title: "ثلاث قواعد للحالة", body: "احفظ الأقل، واشتق الباقي، ولا تغيّرها في مكانها أبداً.", minutes: 6 },
  { slug: "keys-explained", title: "المفاتيح ببساطة", body: "المفتاح يخبر React أي عنصر هو أيّه بين رسمين.", minutes: 3 },
];

function Layout() {
  return (
    <div className="layout">
      <nav>
        <span className="brand">مدونة بِت</span>
        <NavLink to="/" end>
          التدوينات
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
            {post.minutes} دقائق قراءة
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
        هذه التدوينة غير موجودة. <Link to="/">اذهب إلى الرئيسية</Link>
      </p>
    );
  }
  return (
    <article className="card">
      <h2>{post.title}</h2>
      <p className="muted">
        بقلم بِت · {post.minutes} دقائق قراءة
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
