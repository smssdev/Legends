export const providerClient = {
  checkout: async (order: { bookingId: number; amount: string }) => ({
    id: `cs_${order.bookingId}`,
  }),
};
