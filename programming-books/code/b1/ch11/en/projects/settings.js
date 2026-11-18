const defaults = { theme: "light", fontSize: 16, language: "en" };

// What the app stored last time, as JSON text
const saved = '{"theme":"dark","fontSize":18}';

const settings = { ...defaults, ...JSON.parse(saved) };
console.log(settings);

const updated = { ...settings, fontSize: settings.fontSize + 2 };
console.log("Before:", settings.fontSize, "after:", updated.fontSize);

const text = JSON.stringify(updated, null, 2);
console.log(text);
