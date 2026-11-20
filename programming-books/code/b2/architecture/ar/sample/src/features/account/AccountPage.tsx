import { CartBadge } from "../cart/CartBadge";
import { Button } from "../../shared/ui/Button";

export function AccountPage() {
  return (
    <section>
      <CartBadge />
      <Button>Sign out</Button>
    </section>
  );
}
