export const PRICES = {
  latte: 45,
  croissant: 30,
  "mint tea": 30,
};

export function priceOf(name) {
  if (!(name in PRICES)) throw new Error(`not on the menu: ${name}`);
  return PRICES[name];
}
