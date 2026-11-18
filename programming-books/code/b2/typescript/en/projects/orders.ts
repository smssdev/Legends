type OrderStatus =
  | { kind: "placed"; at: string }
  | { kind: "paid"; at: string; amount: number }
  | { kind: "shipped"; at: string; tracking: string }
  | { kind: "delivered"; at: string }
  | { kind: "cancelled"; at: string; reason: string };

function assertNever(value: never): never {
  throw new Error(`Unknown status: ${JSON.stringify(value)}`);
}

function describe(status: OrderStatus): string {
  switch (status.kind) {
    case "placed":
      return `Order placed at ${status.at}`;
    case "paid":
      return `Paid ${status.amount} EGP (${status.at})`;
    case "shipped":
      return `On its way, tracking number ${status.tracking}`;
    case "delivered":
      return `Delivered at ${status.at}`;
    case "cancelled":
      return `Cancelled: ${status.reason}`;
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
  console.log(describe(status), canCancel(status) ? "[can cancel]" : "");
}
