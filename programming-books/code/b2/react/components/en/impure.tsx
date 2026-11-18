import { renderToStaticMarkup } from "react-dom/server";

let visitors = 0;

function Counter() {
  visitors = visitors + 1; // Bad: changes a variable outside the component while rendering
  return <p>Visitors so far: {visitors}</p>;
}

console.log("First render:", renderToStaticMarkup(<Counter />));
console.log("Second render:", renderToStaticMarkup(<Counter />));
