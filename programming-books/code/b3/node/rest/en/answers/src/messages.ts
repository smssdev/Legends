// Every text a person reads, in one place: easy to review, easy to translate.
// {placeholders} are filled in by say().
export const messages = {
  invalidRequest: "Invalid request",
  invalidBody: "Invalid body",
  notFound: "Not found",
  noProduct: "There is no product {id}.",
  noOrder: "There is no order {id}.",
  preconditionRequired: "Precondition required",
  needIfMatch: "Send If-Match with the ETag you last read.",
  stale: "The product has changed",
  staleDetail: "Someone changed it after you read it. Read it again.",
  keyReused: "Idempotency key reused",
  keyReusedDetail: "This key was used with a different body.",
  inProgress: "Request in progress",
  inProgressDetail: "A request with this key is still running.",
  outOfStock: "Not enough stock",
  outOfStockDetail: "Only {stock} left of product {id}.",
  unknownProduct: "Unknown product",
  cannotCancel: "Order cannot be cancelled",
  cannotCancelDetail: "Order {id} is already {status}.",
  tooManyRequests: "Too many requests",
  tooManyRequestsDetail: "Try again in {seconds} seconds.",
  serverError: "Server error",
  emptyPatch: "Send at least one field to change.",
};

export function say(
  text: string,
  values: Record<string, string | number> = {},
): string {
  return text.replace(/\{(\w+)\}/g, (_, key: string) => String(values[key]));
}
