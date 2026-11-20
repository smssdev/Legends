import { freeSlots } from "@/lib/bookings";
import { BookForm } from "./BookForm";

type Props = {
  params: Promise<{ staff: string }>;
  searchParams: Promise<{ date?: string }>;
};

// مكوّن خادم: يعمل على الخادم ويقرأ قاعدة البيانات مباشرة
export default async function BookPage({ params, searchParams }: Props) {
  const staffId = Number((await params).staff);
  const { date = "2026-12-01" } = await searchParams;
  const slots = await freeSlots(staffId, date);
  return (
    <main>
      <h1>اختر وقتاً</h1>
      {slots.length ? (
        <BookForm staffId={staffId} slots={slots} />
      ) : (
        <p>لا أوقات متاحة في هذا اليوم.</p>
      )}
    </main>
  );
}
