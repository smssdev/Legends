// The shop's data, in memory for now: Part 2 moves it to PostgreSQL.
export type Product = {
  id: number;
  name: string;
  price: number; // piastres
  stock: number;
  version: number; // goes up with every change: the ETag
  created_at: string;
};

export type Order = {
  id: number;
  status: "pending" | "cancelled";
  items: { product_id: number; quantity: number; price: number }[];
  total: number;
  created_at: string;
};

const names = [
  "Robot kit",
  "Spare wheels",
  "Battery pack",
  "USB cable",
  "Servo motor",
  "Sensor set",
  "Remote control",
  "Solar panel",
  "Gear box",
  "LED strip",
  "Speaker",
  "Camera module",
];
const prices = [
  45000, 6000, 12500, 2500, 9000, 15000, 8000, 30000, 11000, 4000, 7500, 21000,
];

export function createStore() {
  const start = Date.parse("2026-11-01T09:00:00Z");
  const products: Product[] = names.map((name, i) => ({
    id: i + 1,
    name,
    price: prices[i] ?? 1000,
    stock: 10,
    version: 1,
    created_at: new Date(start + i * 3_600_000).toISOString(),
  }));
  return { products, orders: [] as Order[], nextOrderId: 1 };
}

export type Store = ReturnType<typeof createStore>;
