import { memo } from "react";

// A deliberately slow row: in a real app, a rich card with images, prices and badges
function SlowRow({ name }: { name: string }) {
  const start = performance.now();
  while (performance.now() - start < 0.2) {
    // 0.2 ms of work per row
  }
  return <li>{name}</li>;
}

// memo: re-render the list only when its props change
export const SlowList = memo(function SlowList({ items }: { items: string[] }) {
  return (
    <ul>
      {items.slice(0, 2000).map((name) => (
        <SlowRow key={name} name={name} />
      ))}
    </ul>
  );
});
