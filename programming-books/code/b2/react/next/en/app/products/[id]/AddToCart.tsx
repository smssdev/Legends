"use client"; // Runs in the browser: it has state and reacts to clicks

import { useState } from "react";

export function AddToCart({ name }: { name: string }) {
  const [added, setAdded] = useState(false);
  return (
    <button className={added ? "secondary" : undefined} aria-pressed={added} onClick={() => setAdded(!added)} aria-label={`Add to cart: ${name}`}>
      {added ? "✓ In your cart" : "Add to cart"}
    </button>
  );
}
