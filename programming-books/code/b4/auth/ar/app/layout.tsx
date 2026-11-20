import "./globals.css";

export const metadata = { title: "بِت للحجوزات" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <header>بِت للحجوزات</header>
        {children}
      </body>
    </html>
  );
}
