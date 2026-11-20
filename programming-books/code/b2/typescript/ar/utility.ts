type Product = { id: number; name: string; price: number; stock: number };

// أنواع جديدة مصنوعة من نوع موجود
type ProductUpdate = Partial<Omit<Product, "id">>;
type ProductCard = Pick<Product, "name" | "price">;

function update(product: Product, changes: ProductUpdate): Product {
  return { ...product, ...changes };
}

const mug: Product = { id: 2, name: "كوب", price: 8, stock: 40 };
const card: ProductCard = { name: mug.name, price: mug.price };
console.log(update(mug, { price: 7 }), card);

// قائمة قيم واحدة، والنوع يأتي منها
const ROLES = ["viewer", "editor", "admin"] as const;
type Role = (typeof ROLES)[number];
const labels = {
  viewer: "يشاهد",
  editor: "يعدّل",
  admin: "تحكم كامل",
} satisfies Record<Role, string>;

const role: Role = "editor";
console.log(ROLES.length, labels[role]);
