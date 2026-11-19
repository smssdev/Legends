// A server route: this code runs only on the server, and answers /api/products
export default defineEventHandler(() => getProducts());
