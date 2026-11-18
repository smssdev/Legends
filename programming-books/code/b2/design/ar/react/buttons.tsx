import { createRoot } from "react-dom/client";
import { Button } from "./Button";

function Gallery() {
  return (
    <div className="gallery">
      <div className="row">
        <Button>أساسي</Button>
        <Button variant="secondary">ثانوي</Button>
        <Button variant="danger">خطر</Button>
        <Button variant="ghost">شفاف</Button>
      </div>
      <div className="row">
        <Button size="sm">صغير</Button>
        <Button size="lg">كبير</Button>
        <Button loading>جارٍ الحفظ…</Button>
        <Button disabled>ألغِ</Button>
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
