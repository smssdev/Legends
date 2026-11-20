import "./globals.css";

export const metadata = { title: "Bit Booking" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" dir="ltr">
      <body>
        <header>Bit Booking</header>
        {children}
      </body>
    </html>
  );
}
