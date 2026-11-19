import type { ReactNode } from "react";

export function Layout({ header, children }: { header: ReactNode; children: ReactNode }) {
  return (
    <>
      <header>{header}</header>
      <main>{children}</main>
    </>
  );
}
