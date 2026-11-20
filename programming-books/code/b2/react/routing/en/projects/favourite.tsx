import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { getProduct, setFavourite, type Product } from "../api";

export function FavouriteButton({ id }: { id: number }) {
  const client = useQueryClient();
  const key = ["product", id];
  const product = useQuery({ queryKey: key, queryFn: () => getProduct(id) });

  const mutation = useMutation({
    mutationFn: (favourite: boolean) => setFavourite(id, favourite),
    // 1. Before the server answers: change the cache, and remember the old value
    onMutate: async (favourite) => {
      await client.cancelQueries({ queryKey: key });
      const previous = client.getQueryData<Product>(key);
      client.setQueryData<Product>(key, (old) => (old ? { ...old, favourite } : old));
      return { previous };
    },
    // 2. If it fails: put the old value back
    onError: (_error, _favourite, context) => {
      client.setQueryData(key, context?.previous);
    },
    // 3. Either way: ask the server for the truth
    onSettled: () => client.invalidateQueries({ queryKey: key }),
  });

  if (!product.data) return <p className="muted">Loading…</p>;
  const on = product.data.favourite;
  return (
    <div className="card">
      <h2>{product.data.name}</h2>
      <button aria-pressed={on} className={on ? "" : "secondary"} onClick={() => mutation.mutate(!on)}>
        {on ? "♥ Favourite" : "♡ Favourite"}
      </button>
      {mutation.isPending && <span className="muted"> Saving…</span>}
      {mutation.isError && <p className="error">Could not save. The change was undone.</p>}
    </div>
  );
}
