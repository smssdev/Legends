import { useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import type { Product } from "../../api/schemas";
import { useT } from "../../settings";
import type { T } from "../../i18n/format";

const productSchema = (t: T) =>
  z.object({
    name: z.string().trim().min(2, t("nameError")).max(40, t("nameError")),
    price: z.coerce.number<string>().int(t("priceError")).positive(t("priceError")),
    stock: z.coerce.number<string>().int(t("stockError")).min(0, t("stockError")),
  });

type Fields = "name" | "price" | "stock";
type Props = { product: Product; onSave: (product: Product) => Promise<Partial<Record<Fields, string>> | void> };

export function ProductForm({ product, onSave }: Props) {
  const t = useT();
  const schema = useMemo(() => productSchema(t), [t]);
  const [saved, setSaved] = useState(false);
  const { register, handleSubmit, setError, formState } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { name: product.name, price: String(product.price), stock: String(product.stock) },
  });
  const { errors, isSubmitting } = formState;

  const submit = handleSubmit(async (values) => {
    setSaved(false);
    const serverErrors = await onSave({ ...product, ...values });
    if (!serverErrors) return setSaved(true);
    for (const [field, message] of Object.entries(serverErrors)) setError(field as Fields, { message });
  });

  const field = (name: Fields, label: string, inputMode?: "numeric") => (
    <>
      <label htmlFor={name}>{label}</label>
      <input id={name} inputMode={inputMode} aria-invalid={!!errors[name]} aria-describedby={`${name}-error`} {...register(name)} />
      {errors[name] && (
        <p className="error" id={`${name}-error`}>
          {errors[name].message}
        </p>
      )}
    </>
  );

  return (
    <form onSubmit={submit} noValidate>
      {field("name", t("name"))}
      {field("price", t("price"), "numeric")}
      {field("stock", t("stock"), "numeric")}
      <p>
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? t("saving") : t("save")}
        </button>
      </p>
      {saved && (
        <p role="status" className="done">
          {t("saved")}
        </p>
      )}
    </form>
  );
}
