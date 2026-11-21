import { providerClient } from "../payments/provider.ts";

export async function refund(bookingId: number) {
  return providerClient.checkout({ bookingId, amount: "-50.00 EGP" });
}
