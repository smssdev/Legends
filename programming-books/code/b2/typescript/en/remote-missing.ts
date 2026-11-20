type RemoteData<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; message: string };

function assertNever(value: never): never {
  throw new Error("Unexpected state: " + JSON.stringify(value));
}

function render(state: RemoteData<string[]>): string {
  switch (state.status) {
    case "idle":
      return "Press the button to load";
    case "loading":
      return "Loading…";
    case "success":
      return `${state.data.length} products: ${state.data.join(", ")}`; // data exists only in this case
    default:
      return assertNever(state); // if a case is missing, state is not never here, and the build fails
  }
}

const states: RemoteData<string[]>[] = [
  { status: "idle" },
  { status: "loading" },
  { status: "success", data: ["book", "mug"] },
];
for (const state of states) console.log(render(state));
