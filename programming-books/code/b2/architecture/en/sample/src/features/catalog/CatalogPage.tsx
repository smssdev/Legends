import { Button } from "../../shared/ui/Button";
import { formatMoney } from "../../shared/lib/money";
import { addToCart } from "../cart";
import { useProducts } from "./useProducts";

export function CatalogPage() {
  const products = useProducts();
  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>
          {p.name} {formatMoney(p.price)} <Button onClick={() => addToCart(p)}>+</Button>
        </li>
      ))}
    </ul>
  );
}
