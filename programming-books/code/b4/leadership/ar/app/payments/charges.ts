import { egp } from "../shared/money.ts";
import { providerClient } from "./provider.ts";

export async function chargeDeposit(bookingId: number, piastres: number) {
  return providerClient.checkout({ bookingId, amount: egp(piastres) });
}
