import { chargeDeposit } from "../payments/index.ts";

export async function book(slot: number) {
  return chargeDeposit(slot, 5000);
}
