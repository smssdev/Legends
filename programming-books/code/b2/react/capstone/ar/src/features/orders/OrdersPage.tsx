import { Link, useSearchParams } from "react-router";
import { useOrders } from "../../api/queries";
import { filterOrders, readFilters, STATUSES } from "../../lib/orders";
import { useT } from "../../settings";
import { LoadError, Loading, StatusBadge } from "../../ui/ui";

export function OrdersPage() {
  const t = useT();
  const orders = useOrders();
  // المرشحات تعيش في العنوان، فتُحفظ القائمة المرشحة وتُشارك
  const [params, setParams] = useSearchParams();
  const filters = readFilters(params);

  const link = (changes: Record<string, string | null>) => {
    const next = new URLSearchParams(params);
    for (const [key, value] of Object.entries(changes)) {
      if (value === null) next.delete(key);
      else next.set(key, value);
    }
    return `?${next}`;
  };

  return (
    <>
      <h1>{t("orders")}</h1>
      <nav className="filters" aria-label={t("status")}>
        {(["all", ...STATUSES] as const).map((s) => (
          <Link key={s} to={link({ status: s === "all" ? null : s, page: null })} aria-current={filters.status === s ? "page" : undefined}>
            {t(s)}
          </Link>
        ))}
      </nav>
      <label htmlFor="q" className="sr-only">
        {t("search")}
      </label>
      <input
        id="q"
        type="search"
        placeholder={t("search")}
        value={filters.q}
        onChange={(e) => setParams(link({ q: e.target.value || null, page: null }).slice(1), { replace: true })}
      />
      {orders.isPending && <Loading />}
      {orders.isError && <LoadError retry={() => void orders.refetch()} />}
      {orders.isSuccess && <OrdersTable result={filterOrders(orders.data, filters)} link={link} />}
    </>
  );
}

type Result = ReturnType<typeof filterOrders>;

function OrdersTable({ result, link }: { result: Result; link: (changes: Record<string, string>) => string }) {
  const t = useT();
  if (result.count === 0) return <p role="status">{t("none")}</p>;
  return (
    <section className="card">
      <table>
        <caption className="sr-only">{t("found", { count: result.count })}</caption>
        <thead>
          <tr>
            <th scope="col">{t("order")}</th>
            <th scope="col">{t("customer")}</th>
            <th scope="col">{t("total")}</th>
            <th scope="col">{t("status")}</th>
          </tr>
        </thead>
        <tbody>
          {result.rows.map((o) => (
            <tr key={o.id}>
              <td>
                <Link to={`/orders/${o.id}`}>#{o.id}</Link>
              </td>
              <td>{o.customer}</td>
              <td>{t.money(o.total)}</td>
              <td>
                <StatusBadge status={o.status} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="pager">
        {result.page > 1 ? <Link to={link({ page: String(result.page - 1) })}>{t("previous")}</Link> : <span />}
        <span>{t("page", { page: result.page, pages: result.pages })}</span>
        {result.page < result.pages ? <Link to={link({ page: String(result.page + 1) })}>{t("next")}</Link> : <span />}
      </div>
    </section>
  );
}
