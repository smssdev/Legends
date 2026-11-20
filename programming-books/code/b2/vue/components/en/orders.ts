export type Orders =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "success"; orders: string[] };
