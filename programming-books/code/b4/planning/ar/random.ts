// بذرة ثابتة: الـ10,000 تشغيل نفسها في كل مرة
export function random(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };
}

// المدة التي انتهت خلالها p% من التشغيلات
export function percentile(sorted: number[], p: number) {
  return sorted[
    Math.min(sorted.length - 1, Math.floor((sorted.length * p) / 100))
  ]!;
}
