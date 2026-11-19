import type { ReactNode } from "react";
import type { OrderStatus } from "../api/schemas";
import { useT } from "../settings";

export function Card({ title, children }: { title?: string; children: ReactNode }) {
  return (
    <section className="card">
      {title && <h2>{title}</h2>}
      {children}
    </section>
  );
}

export function StatusBadge({ status }: { status: OrderStatus }) {
  const t = useT();
  return <span className={`badge ${status}`}>{t(status)}</span>;
}

export function Loading() {
  const t = useT();
  return (
    <div aria-busy="true" aria-label={t("loading")}>
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
    </div>
  );
}

export function LoadError({ retry }: { retry: () => void }) {
  const t = useT();
  return (
    <div role="alert" className="card">
      <p>{t("loadError")}</p>
      <button type="button" onClick={retry}>
        {t("retry")}
      </button>
    </div>
  );
}
