import { renderToStaticMarkup } from "react-dom/server";

function Greeting() {
  return <h1>أهلاً يا سارة!</h1>;
}

console.log(renderToStaticMarkup(<Greeting />));
