const defaults = { theme: "light", fontSize: 16, language: "ar" };

// ما حفظه التطبيق في المرة الماضية، نصاً بصيغة JSON
const saved = '{"theme":"dark","fontSize":18}';

const settings = { ...defaults, ...JSON.parse(saved) };
console.log(settings);

const updated = { ...settings, fontSize: settings.fontSize + 2 };
console.log("قبل:", settings.fontSize, "بعد:", updated.fontSize);

const text = JSON.stringify(updated, null, 2);
console.log(text);
