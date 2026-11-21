// a fixed seed: the same 10,000 runs every time
export function random(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };
}

// the duration that p% of the runs finished within
export function percentile(sorted: number[], p: number) {
  return sorted[
    Math.min(sorted.length - 1, Math.floor((sorted.length * p) / 100))
  ]!;
}
