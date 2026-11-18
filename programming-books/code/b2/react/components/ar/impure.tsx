import { renderToStaticMarkup } from "react-dom/server";

let visitors = 0;

function Counter() {
  visitors = visitors + 1; // خطأ: يغيّر متغيراً خارج المكوّن أثناء الرسم
  return <p>الزوار حتى الآن: {visitors}</p>;
}

console.log("الرسم الأول:", renderToStaticMarkup(<Counter />));
console.log("الرسم الثاني:", renderToStaticMarkup(<Counter />));
