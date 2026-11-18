import { renderToStaticMarkup } from "react-dom/server";

function Greeting() {
  return <h1>Hello, Sara!</h1>;
}

console.log(renderToStaticMarkup(<Greeting />));
