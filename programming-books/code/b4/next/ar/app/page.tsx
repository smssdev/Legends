import Link from "next/link";
import { staffList } from "@/lib/bookings";

export const dynamic = "force-dynamic";

export default async function Home() {
  const staff = await staffList();
  return (
    <main>
      <h1>اختر من يقص شعرك</h1>
      <ul>
        {staff.map((s) => (
          <li key={s.id}>
            <Link href={`/book/${s.id}`}>{s.name}</Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
