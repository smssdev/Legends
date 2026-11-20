type Product = { id: number; name: string; price: number; stock: number };

// New types made from an existing one
type ProductUpdate = Partial<Omit<Product, "id">>;
type ProductCard = Pick<Product, "name" | "price">;

function update(product: Product, changes: ProductUpdate): Product {
  return { ...product, ...changes };
}

const mug: Product = { id: 2, name: "Mug", price: 8, stock: 40 };
const card: ProductCard = { name: mug.name, price: mug.price };
console.log(update(mug, { price: 7 }), card);

// One list of values, and the type comes from it
const ROLES = ["viewer", "editor", "admin"] as const;
type Role = (typeof ROLES)[number];
const labels = {
  viewer: "Can view",
  editor: "Can edit",
  admin: "Full control",
} satisfies Record<Role, string>;

const role: Role = "editor";
console.log(ROLES.length, labels[role]);
