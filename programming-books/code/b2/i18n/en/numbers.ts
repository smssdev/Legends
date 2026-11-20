// One number, many correct ways to write it
const price = 1234567.5;
const show = (locale: string, options: Intl.NumberFormatOptions = {}) =>
  console.log(locale.padEnd(18), new Intl.NumberFormat(locale, options).format(price));

show("en-US");
show("de-DE");
show("ar-EG");
show("ar-EG-u-nu-latn");
show("ar-SA", { style: "currency", currency: "SAR" });
show("en-EG", { style: "currency", currency: "EGP" });
show("ar-EG", { notation: "compact" });
