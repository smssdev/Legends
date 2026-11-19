export default defineEventHandler(async (event) => {
  const product = await getProduct(Number(getRouterParam(event, "id")));
  if (!product) throw createError({ statusCode: 404, statusMessage: "Not found" });
  return product;
});
