import { Link, useParams } from "react-router";
import { useOrder, useSetStatus } from "../../api/queries";
import { STATUSES } from "../../lib/orders";
import { useT } from "../../settings";
import { Card, LoadError, Loading, StatusBadge } from "../../ui/ui";

export function OrderPage() {
  const t = useT();
  const id = Number(useParams().id);
  const order = useOrder(id);
  const setStatus = useSetStatus(id);
  if (order.isPending) return <Loading />;
  if (order.isError) return <LoadError retry={() => void order.refetch()} />;
  const o = order.data;

  return (
    <>
      <h1>{t("orderTitle", { id: String(o.id) })}</h1>
      <Card>
        <dl>
          <dt>{t("customer")}</dt>
          <dd>{o.customer}</dd>
          <dt>{t("city")}</dt>
          <dd>{o.city}</dd>
          <dt>{t("date")}</dt>
          <dd>{t.date(o.createdAt)}</dd>
          <dt>{t("total")}</dt>
          <dd>{t.money(o.total)}</dd>
          <dt>{t("status")}</dt>
          <dd aria-live="polite">
            <StatusBadge status={o.status} />
          </dd>
        </dl>
        <p>{t("markAs")}</p>
        <div className="actions">
          {STATUSES.filter((s) => s !== o.status).map((s) => (
            <button key={s} type="button" className="secondary" disabled={setStatus.isPending} onClick={() => setStatus.mutate(s)}>
              {t(s)}
            </button>
          ))}
        </div>
        {setStatus.isError && (
          <p role="alert" className="error">
            {t("failed")}
          </p>
        )}
      </Card>
      <Link to="/orders">{t("allOrders")}</Link>
    </>
  );
}
