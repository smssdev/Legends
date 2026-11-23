import {MENU} from "./menu.mjs";

export function topThree(menu) {
  return menu
    .map((drink) => drink.price)
    .sort()
    .reverse()
    .slice(0, 3)
    .map((price) => menu.find((drink) => drink.price === price).name);
}

console.log(topThree(MENU));
