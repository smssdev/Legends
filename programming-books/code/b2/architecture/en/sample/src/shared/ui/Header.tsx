import { useCart } from "../../features/cart/store";

export function Header() {
  const count = useCart((s) => s.count);
  return <p>{count}</p>;
}
