import { redirect } from "next/navigation";
import { AuthError, requireUser } from "@/lib/auth";
import { bookingsFor } from "@/lib/owner";
import { time } from "@/lib/time";
import { cancelAction } from "./actions";

async function signedIn() {
  try {
    return await requireUser(["owner", "staff"]);
  } catch (error) {
    if (error instanceof AuthError && error.status === 401) redirect("/login");
    throw error;
  }
}

// الصفحة تفحص أيضاً: قد يُضبط الوكيل خطأً أو يُتجاوز
export default async function OwnerPage() {
  const user = await signedIn();
  const bookings = await bookingsFor(user);
  return (
    <main>
      <h1>الحجوزات</h1>
      <p className="muted">{user.email}</p>
      <ul>
        {bookings.map((b) => (
          <li key={b.id}>
            <span>
              {time.format(new Date(b.starts_at))} · {b.staff} · {b.email}
            </span>
            {b.status === "confirmed" && user.role === "owner" ? (
              <form action={cancelAction}>
                <input type="hidden" name="id" value={b.id} />
                <button>إلغاء</button>
              </form>
            ) : (
              b.status !== "confirmed" && <span className="muted">ملغى</span>
            )}
          </li>
        ))}
      </ul>
    </main>
  );
}
