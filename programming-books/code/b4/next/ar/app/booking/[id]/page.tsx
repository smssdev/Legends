import { notFound } from "next/navigation";
import { findBooking } from "@/lib/bookings";
import { time } from "@/lib/time";

export default async function BookingPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const booking = await findBooking(Number((await params).id));
  if (!booking) notFound();
  return (
    <main>
      <h1>تم حجزك</h1>
      <p className="done">
        <strong>
          {booking.staff} · {time.format(booking.starts_at)}
        </strong>
        <br />
        أرسلنا التفاصيل إلى {booking.email}.
      </p>
    </main>
  );
}
