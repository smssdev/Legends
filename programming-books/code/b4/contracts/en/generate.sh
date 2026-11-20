# Types from the contract
$ npm run types
✨ openapi-typescript 7.13.0
🚀 openapi.yaml → src/api.d.ts
$ grep -A9 'Booking: {' src/api.d.ts
        Booking: {
            id: number;
            staff_id: number;
            /** Format: date-time */
            starts_at: string;
            /** Format: date-time */
            ends_at: string;
            email: string;
            /** @enum {string} */
            status: "confirmed" | "cancelled";
