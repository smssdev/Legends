import { useOrders } from "../../api/queries";
import { overview } from "../../lib/orders";
import { useT } from "../../settings";
import { Card, LoadError, Loading } from "../../ui/ui";

export function OverviewPage() {
  const t = useT();
  const orders = useOrders();
  if (orders.isPending) return <Loading />;
  if (orders.isError) return <LoadError retry={() => void orders.refetch()} />;

  const o = overview(orders.data, new Date());
  const highest = Math.max(1, ...o.days.map((d) => d.total));
  const kpis = [
    [t("revenue"), t.money(o.revenue)],
    [t("ordersCount"), String(o.orders)],
    [t("average"), t.money(o.average)],
    [t("toShip"), String(o.toShip)],
  ] as const;

  return (
    <>
      <h1>{t("overview")}</h1>
      <div className="kpis">
        {kpis.map(([label, value]) => (
          <figure key={label} className="card kpi">
            <p>{label}</p>
            <strong>{value}</strong>
          </figure>
        ))}
      </div>
      <Card title={t("lastWeek")}>
        <ol className="bars">
          {o.days.map((d) => (
            <li key={d.day}>
              <span className="bar" style={{ blockSize: `${(d.total / highest) * 100}%` }} />
              <span aria-hidden="true">{t.weekday(d.day)}</span>
              <span className="sr-only">{`${t.weekday(d.day)}: ${t.money(d.total)}`}</span>
            </li>
          ))}
        </ol>
      </Card>
    </>
  );
}
