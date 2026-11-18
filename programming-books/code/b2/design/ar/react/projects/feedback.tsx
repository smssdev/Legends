import { createRoot } from "react-dom/client";
import { Alert } from "./Alert";
import { Badge } from "./Badge";

createRoot(document.getElementById("root")!).render(
  <div className="gallery">
    <div className="row">
      <b>الطلب #1042</b>
      <Badge tone="success">مدفوع</Badge>
      <Badge tone="warning">قيد الانتظار</Badge>
      <Badge tone="danger">مسترد</Badge>
      <Badge>جديد</Badge>
    </div>
    <div>
      <Alert>يُشحن طلبك غداً.</Alert>
      <Alert tone="success">وصل الدفع. شكراً لك!</Alert>
      <Alert tone="warning">بقيت قطعتان فقط في المخزون.</Alert>
      <Alert tone="danger">رُفضت البطاقة. جرّب بطاقة أخرى من فضلك.</Alert>
    </div>
  </div>,
);
