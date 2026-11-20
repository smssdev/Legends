type RemoteData<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; message: string };

function assertNever(value: never): never {
  throw new Error("حالة غير متوقعة: " + JSON.stringify(value));
}

function render(state: RemoteData<string[]>): string {
  switch (state.status) {
    case "idle":
      return "اضغط الزر للتحميل";
    case "loading":
      return "جارٍ التحميل…";
    case "success":
      return `${state.data.length} منتجات: ${state.data.join(", ")}`; // data موجودة في هذه الحالة فقط
    default:
      return assertNever(state); // إن نقصت حالة فلن تكون state من نوع never هنا، ويفشل البناء
  }
}

const states: RemoteData<string[]>[] = [
  { status: "idle" },
  { status: "loading" },
  { status: "success", data: ["كتاب", "كوب"] },
];
for (const state of states) console.log(render(state));
