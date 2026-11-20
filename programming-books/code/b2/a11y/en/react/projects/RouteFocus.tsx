import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router";

// After every navigation: update the title, move the focus to the new h1, and announce the page
export function RouteFocus({ appName }: { appName: string }) {
  const location = useLocation();
  const first = useRef(true);
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (first.current) {
      first.current = false; // the first page load is announced by the browser itself
      return;
    }
    const heading = document.querySelector<HTMLElement>("main h1");
    if (!heading) return;
    document.title = `${heading.textContent} · ${appName}`;
    heading.tabIndex = -1;
    heading.focus();
    setMessage(heading.textContent ?? "");
  }, [location.pathname, appName]);

  return (
    <p role="status" className="sr-only">
      {message}
    </p>
  );
}
