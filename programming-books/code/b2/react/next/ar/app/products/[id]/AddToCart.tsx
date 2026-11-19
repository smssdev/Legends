"use client"; // يعمل في المتصفح: له حالة ويتفاعل مع الضغطات

import { useState } from "react";

export function AddToCart({ name }: { name: string }) {
  const [added, setAdded] = useState(false);
  return (
    <button className={added ? "secondary" : undefined} aria-pressed={added} onClick={() => setAdded(!added)} aria-label={`أضف إلى السلة: ${name}`}>
      {added ? "✓ في سلتك" : "أضف إلى السلة"}
    </button>
  );
}
