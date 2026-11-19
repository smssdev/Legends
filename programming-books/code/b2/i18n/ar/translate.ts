import { translate } from "./messages";

for (const n of [0, 1, 2, 5, 11, 100]) {
  console.log(String(n).padStart(3), "|", translate("ar", "cart.items", { count: n }).padEnd(12), "|", translate("en", "cart.items", { count: n }));
}
