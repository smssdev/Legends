import { Link, useParams } from "react-router";
import { useProduct, useProducts, useSaveProduct } from "../../api/queries";
import { ApiError } from "../../api/client";
import { useT } from "../../settings";
import { Card, LoadError, Loading } from "../../ui/ui";
import { ProductForm } from "./ProductForm";

export function ProductsPage() {
  const t = useT();
  const products = useProducts();
  if (products.isPending) return <Loading />;
  if (products.isError) return <LoadError retry={() => void products.refetch()} />;
  return (
    <>
      <h1>{t("products")}</h1>
      <Card>
        <table>
          <thead>
            <tr>
              <th scope="col">{t("name")}</th>
              <th scope="col">{t("price")}</th>
              <th scope="col">{t("stock")}</th>
            </tr>
          </thead>
          <tbody>
            {products.data.map((p) => (
              <tr key={p.id}>
                <td>
                  <Link to={`/products/${p.id}`} aria-label={`${t("edit")}: ${p.name}`}>
                    {p.name}
                  </Link>
                </td>
                <td>{t.money(p.price)}</td>
                <td>{p.stock}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </>
  );
}

export function ProductPage() {
  const t = useT();
  const id = Number(useParams().id);
  const product = useProduct(id);
  const save = useSaveProduct();
  if (product.isPending) return <Loading />;
  if (product.isError) return <LoadError retry={() => void product.refetch()} />;
  return (
    <>
      <h1>{product.data.name}</h1>
      <Card>
        <ProductForm
          key={product.data.id}
          product={product.data}
          onSave={async (changed) => {
            try {
              await save.mutateAsync(changed);
            } catch (error) {
              if (error instanceof ApiError && error.status === 422) return error.errors;
              throw error;
            }
          }}
        />
      </Card>
      <Link to="/products">{t("products")}</Link>
    </>
  );
}
