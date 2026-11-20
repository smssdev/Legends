import { freeSlots } from "@/lib/bookings";
import { BookForm } from "./BookForm";

type Props = {
  params: Promise<{ staff: string }>;
  searchParams: Promise<{ date?: string }>;
};

// a Server Component: it runs on the server and reads the database directly
export default async function BookPage({ params, searchParams }: Props) {
  const staffId = Number((await params).staff);
  const { date = "2026-12-01" } = await searchParams;
  const slots = await freeSlots(staffId, date);
  return (
    <main>
      <h1>Choose a time</h1>
      {slots.length ? (
        <BookForm staffId={staffId} slots={slots} />
      ) : (
        <p>No free times on this day.</p>
      )}
    </main>
  );
}
