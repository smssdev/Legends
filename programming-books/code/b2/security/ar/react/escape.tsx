import { renderToStaticMarkup } from "react-dom/server";

const comment = `<img src="x" onerror="alert('hacked')">`;

// Text in braces is escaped: it is shown, never run
console.log(renderToStaticMarkup(<p>{comment}</p>));

// The name is a warning: this puts raw HTML into the page
console.log(renderToStaticMarkup(<p dangerouslySetInnerHTML={{ __html: comment }} />));

// URLs from users can run code too: React warns, but checking the scheme is your job
const link = "javascript:alert('hacked')";
const safe = /^https?:\/\//.test(link) ? link : "#";
console.log(renderToStaticMarkup(<a href={safe}>الملف الشخصي</a>));
