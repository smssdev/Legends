type OrderStatus =
  | { kind: "placed"; at: string }
  | { kind: "paid"; at: string; amount: number }
  | { kind: "shipped"; at: string; tracking: string }
  | { kind: "delivered"; at: string }
  | { kind: "cancelled"; at: string; reason: string };

function assertNever(value: never): never {
  throw new Error(`حالة مجهولة: ${JSON.stringify(value)}`);
}

function describe(status: OrderStatus): string {
  switch (status.kind) {
    case "placed":
      return `طُلب الساعة ${status.at}`;
    case "paid":
      return `دُفع ${status.amount} جنيهاً (${status.at})`;
    case "shipped":
      return `في الطريق، رقم التتبع ${status.tracking}`;
    case "delivered":
      return `سُلّم الساعة ${status.at}`;
    case "cancelled":
      return `أُلغي: ${status.reason}`;
    default:
      return assertNever(status);
  }
}

function canCancel(status: OrderStatus): boolean {
  return status.kind === "placed" || status.kind === "paid";
}

const history: OrderStatus[] = [
  { kind: "placed", at: "09:12" },
  { kind: "paid", at: "09:14", amount: 41 },
  { kind: "shipped", at: "15:30", tracking: "EG-55120" },
];
for (const status of history) {
  console.log(describe(status), canCancel(status) ? "[يمكن إلغاؤه]" : "");
}
