import "./style.css";
import { products } from "./products.ts";
import { formatPrice } from "./format.ts";

const app = document.querySelector<HTMLElement>("#app")!;

const heading = document.createElement("h1");
heading.textContent = "متجر بِت";
const list = document.createElement("ul");
for (const product of products) {
  const item = document.createElement("li");
  item.textContent = `${product.name}: ${formatPrice(product.price)}`;
  list.append(item);
}
app.append(heading, list);

const button = document.createElement("button");
button.textContent = "اعرض التقرير";
button.addEventListener("click", async () => {
  button.textContent = "جارٍ تحميل التقرير…";
  const { buildReport } = await import("./report.ts");
  app.append(buildReport(products));
  button.remove();
});
app.append(button);
