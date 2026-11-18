import { renderToStaticMarkup } from "react-dom/server";

function CartSummary({ count, total }: { count: number; total: number }) {
  const isEmpty = count === 0;
  return (
    <>
      <p className="summary">
        {count} items in your cart: {total.toFixed(2)} EGP
      </p>
      <button disabled={isEmpty} style={{ fontWeight: 700 }}>
        Add to cart
      </button>
    </>
  );
}

console.log(renderToStaticMarkup(<CartSummary count={3} total={41} />));
