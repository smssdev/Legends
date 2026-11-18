function last<T>(list: readonly T[]): T | undefined {
  return list.at(-1);
}

function groupBy<T, K extends string>(list: readonly T[], key: (item: T) => K): Record<K, T[]> {
  const groups = {} as Record<K, T[]>;
  for (const item of list) {
    (groups[key(item)] ??= []).push(item);
  }
  return groups;
}

console.log(last([1, 2, 3]), last([]));
console.log(groupBy(["apple", "avocado", "banana"], (w) => w[0] ?? ""));
