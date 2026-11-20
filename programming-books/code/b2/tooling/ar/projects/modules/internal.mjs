// يُستخدم داخل المجلد فقط: لا يصدّره index.mjs
export function countWords(text) {
  return text.split(/\s+/).filter(Boolean).length;
}
