import { createRoot } from "react-dom/client";
import { Button } from "./Button";

function Gallery() {
  return (
    <div className="gallery">
      <div className="row">
        <Button>Primary</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="danger">Danger</Button>
        <Button variant="ghost">Ghost</Button>
      </div>
      <div className="row">
        <Button size="sm">Small</Button>
        <Button size="lg">Large</Button>
        <Button loading>Saving…</Button>
        <Button disabled>Cancel</Button>
      </div>
    </div>
  );
}

const root = createRoot(document.getElementById("root")!);
root.render(
  <>
    <Gallery />
    <div data-theme="dark" style={{ marginTop: 12 }}>
      <Gallery />
    </div>
  </>,
);
