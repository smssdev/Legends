import { renderToStaticMarkup } from "react-dom/server";

function CartSummary({ count, total }: { count: number; total: number }) {
  const isEmpty = count === 0;
  return (
    <>
      <p className="summary">
        {count} عناصر في سلتك: {total.toFixed(2)} جنيهاً
      </p>
      <button disabled={isEmpty} style={{ fontWeight: 700 }}>
        أضف إلى السلة
      </button>
    </>
  );
}

console.log(renderToStaticMarkup(<CartSummary count={3} total={41} />));
