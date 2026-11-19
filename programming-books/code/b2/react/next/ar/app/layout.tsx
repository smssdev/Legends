import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "متجر بِت", template: "%s · متجر بِت" },
  description: "كتب وأكواب وملصقات لمن يحبون البرمجة.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <nav>
          <Link href="/" className="brand">متجر بِت</Link>
          <Link href="/products">المنتجات</Link>
          <Link href="/contact">تواصل معنا</Link>
        </nav>
        <main>{children}</main>
      </body>
    </html>
  );
}
