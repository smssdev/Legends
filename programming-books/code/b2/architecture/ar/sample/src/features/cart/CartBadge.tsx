import { useCart } from "./store";

export function CartBadge() {
  return <span>{useCart((s) => s.count)}</span>;
}
