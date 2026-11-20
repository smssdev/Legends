import { CatalogPage } from "../features/catalog";
import { CartBadge } from "../features/cart";
import { Layout } from "../shared/ui/Layout";

export function App() {
  return (
    <Layout header={<CartBadge />}>
      <CatalogPage />
    </Layout>
  );
}
