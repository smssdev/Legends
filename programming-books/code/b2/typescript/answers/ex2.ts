const SIZES = ["S", "M", "L"] as const;
type Size = (typeof SIZES)[number];
const mine: Size = "M";
console.log(SIZES.length, mine);
