$ npx kysely-codegen --env-file=.env --type-mapping '{"int8":"number"}' --overrides '{"columns":{"orders.status":"\"pending\" | \"paid\" | \"shipped\" | \"cancelled\""}}' --out-file answers/db-types.ts > /dev/null 2>&1; grep -A5 'interface Orders' answers/db-types.ts
export interface Orders {
  created_at: Generated<Timestamp>;
  customer_id: number;
  id: Generated<number>;
  status: "pending" | "paid" | "shipped" | "cancelled";
}
