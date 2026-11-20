import { readFileSync } from "node:fs";
import Fastify, { type FastifyError } from "fastify";
import { parse } from "yaml";
import type { components } from "./api.d.ts";

// أنواع مولَّدة من العقد نفسه
type Booking = components["schemas"]["Booking"];
type BookingIn = components["schemas"]["BookingIn"];
type Problem = components["schemas"]["Problem"];

// العقد هو المصدر: مخططاته تتحقق من كل طلب
const contract = parse(readFileSync("openapi.yaml", "utf8"));
const schemas = contract.components.schemas;

// ساعات العمل ومدة الخدمة ثابتة هنا؛ والفصل 1 وضعها في جداول
const MINUTES = 30;
const OPEN = "10:00";
const CLOSE = "14:00";

const problem = (status: number, title: string, detail?: string): Problem => ({
  title,
  status,
  ...(detail && { detail }),
});

export function buildApp() {
  const app = Fastify();
  const bookings: Booking[] = [];
  let nextId = 1;

  const overlaps = (staffId: number, start: number, end: number) =>
    bookings.some(
      (b) =>
        b.staff_id === staffId &&
        b.status === "confirmed" &&
        Date.parse(b.starts_at) < end &&
        start < Date.parse(b.ends_at),
    );

  // كل خطأ يخرج Problem، كما يعد العقد
  if (process.env.BUG !== "errors") {
    app.setErrorHandler((error: FastifyError, _request, reply) => {
      const status = error.validation ? 422 : 500;
      const body = problem(
        status,
        "طلب غير صالح",
        error.validation ? error.message : undefined,
      );
      return reply.code(status).type("application/problem+json").send(body);
    });
  }

  app.get<{ Querystring: { staff_id: number; date: string } }>(
    "/slots",
    {
      schema: {
        querystring: {
          type: "object",
          required: ["staff_id", "date"],
          properties: {
            staff_id: { type: "integer", minimum: 1 },
            date: { type: "string", format: "date" },
          },
        },
      },
    },
    async (request) => {
      const { staff_id, date } = request.query;
      const data = [];
      const close = Date.parse(`${date}T${CLOSE}:00+02:00`);
      for (
        let t = Date.parse(`${date}T${OPEN}:00+02:00`);
        t + MINUTES * 60_000 <= close;
        t += MINUTES * 60_000
      ) {
        const end = t + MINUTES * 60_000;
        if (!overlaps(staff_id, t, end)) {
          data.push({
            starts_at: new Date(t).toISOString(),
            ends_at: new Date(end).toISOString(),
          });
        }
      }
      return { data };
    },
  );

  app.post<{ Body: BookingIn }>(
    "/bookings",
    { schema: { body: schemas.BookingIn } },
    async (request, reply) => {
      const { staff_id, starts_at, email } = request.body;
      const start = Date.parse(starts_at);
      const end = start + MINUTES * 60_000;
      if (overlaps(staff_id, start, end)) {
        const body = problem(
          409,
          "الموعد محجوز",
          "حجز آخر يبدأ أو ينتهي داخل هذا الوقت.",
        );
        return reply.code(409).type("application/problem+json").send(body);
      }
      const booking: Booking = {
        id: nextId++,
        staff_id,
        starts_at: new Date(start).toISOString(),
        ends_at: new Date(end).toISOString(),
        email,
        status: "confirmed",
      };
      bookings.push(booking);
      return reply.code(201).send(booking);
    },
  );

  return app;
}
