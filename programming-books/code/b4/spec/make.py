"""Writes the examples of Book 4, chapter "From Idea to Specification", in English and Arabic.
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start)

The book's project, Bit Booking, starts here as a one-page spec (spec.md), a schema in which the most
important rule of the spec ("a staff member is never booked twice at the same time") is a constraint
PostgreSQL enforces, and a script that turns the non-functional requirements into numbers (budget.ts).
What the terminal showed is saved as transcripts (*.sh).
"""
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent / "b3"
sys.path.insert(0, str(B3))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_salon="Bit Hair Studio", w_mona="Mona", w_omar="Omar", w_cut="Haircut",
        w_c_ext="lets one constraint mix = (on a number) and && (on a range)",
        w_c_range="[start, end): the end is not included, so 10:00-10:30 and 10:30-11:00 do not overlap",
        w_c_rule="US-2: a staff member is never booked twice at the same time; cancelled bookings free the slot",
        w_c_money="money in piastres, as in every book of the series",
        w_c_avail="availability: how much downtime each target allows in a 30-day month",
        w_c_load="load: from the business numbers in the spec to requests per second",
        w_c_data="data: how much the bookings table grows in a year",
        w_t_target="target", w_t_down="downtime", w_t_min="min/month",
        w_t_day="requests a day", w_t_avg="average per second", w_t_peak="peak per second (x4)",
        w_t_rows="bookings a year", w_t_size="table size a year",
        w_s_rules="The spec's rules, checked by the database",
        w_s_book="Sara books Mona at 10:00 for 30 minutes",
        w_s_clash="Karim tries Mona at 10:15: the database refuses",
        w_s_other="The same time with Omar is fine",
        w_s_next="10:30 with Mona is fine too: the ranges only touch",
        w_s_cancel="Sara cancels, and 10:00 is free again",
        w_s_budget="The non-functional requirements, as numbers",
    ),
    "ar": dict(
        w_salon="صالون بِت", w_mona="منى", w_omar="عمر", w_cut="قص شعر",
        w_c_ext="يتيح لقيد واحد أن يجمع = (على رقم) و&& (على مدى)",
        w_c_range="[البداية, النهاية): النهاية غير داخلة، فلا يتداخل 10:00-10:30 مع 10:30-11:00",
        w_c_rule="US-2: لا يُحجز موظف مرتين في الوقت نفسه أبداً؛ والحجز الملغى يحرر موعده",
        w_c_money="المال بالقروش، كما في كل كتب السلسلة",
        w_c_avail="التوافر: كم توقفاً يسمح به كل هدف في شهر من 30 يوماً",
        w_c_load="الحمل: من أرقام العمل في المواصفات إلى الطلبات في الثانية",
        w_c_data="البيانات: كم يكبر جدول الحجوزات في سنة",
        w_t_target="الهدف", w_t_down="التوقف", w_t_min="دقيقة/شهر",
        w_t_day="طلب في اليوم", w_t_avg="المتوسط في الثانية", w_t_peak="الذروة في الثانية (×4)",
        w_t_rows="حجز في السنة", w_t_size="حجم الجدول في سنة",
        w_s_rules="قواعد المواصفات، تفحصها قاعدة البيانات",
        w_s_book="سارة تحجز منى الساعة 10:00 لثلاثين دقيقة",
        w_s_clash="كريم يحاول منى الساعة 10:15: قاعدة البيانات ترفض",
        w_s_other="الوقت نفسه مع عمر مقبول",
        w_s_next="10:30 مع منى مقبول أيضاً: المديان يتلامسان فقط",
        w_s_cancel="سارة تلغي، فيعود 10:00 متاحاً",
        w_s_budget="المتطلبات غير الوظيفية، أرقاماً",
    ),
}

SPEC = {
    "en": """# Bit Booking: one-page spec

**Status:** draft for review · **Owner:** product + tech lead · **Updated:** 2026-11-20

## Problem
Small businesses (salons, clinics, tutors) take bookings by phone and chat.
Owners lose about an hour a day answering, and 1 booking in 8 is a no-show.

## Users
- **Owner:** sets services, staff and opening hours; sees the day.
- **Staff:** sees their own day; marks a booking done or no-show.
- **Customer:** books, moves or cancels, without an account.

## Stories (MVP)
- **US-1** As a customer, I see free slots for a service and a staff member.
  - Given Mona works 10:00-14:00 and has a booking 10:00-10:30,
    when I ask for a 30-minute haircut, then 10:00 is not offered and 10:30 is.
- **US-2** As a customer, I book a slot.
  - Given two customers ask for the same slot at the same time,
    then exactly one booking is made and the other sees "taken".
- **US-3** As a customer, I get a confirmation email, and a reminder 24 h before.
- **US-4** As a customer, I cancel up to 2 h before, from the link in the email.
- **US-5** As an owner, I see today's bookings for every staff member.

## Not in the MVP
Online payment (deposits come in version 2), mobile apps, several branches.

## Quality
- Availability 99.9% a month; booking page p95 < 300 ms.
- 2,000 businesses in year one; 25 bookings a business a day.
- Personal data kept 2 years after the last visit, then deleted.

## Risks and open questions
- Time zones: a business and its customers may be in different zones.
- Do customers need an account to see their history? (decide by 2026-12-01)
""",
    "ar": """# بِت للحجوزات: مواصفات في صفحة

**الحالة:** مسودة للمراجعة · **المسؤول:** المنتج + القائد التقني · **التحديث:** 2026-11-20

## المشكلة
الأعمال الصغيرة (الصالونات والعيادات والمدرسون) تأخذ الحجوزات بالهاتف والمحادثات.
يخسر أصحابها نحو ساعة يومياً في الرد، وحجز من كل 8 لا يحضر صاحبه.

## المستخدمون
- **صاحب العمل:** يحدد الخدمات والموظفين وساعات العمل؛ ويرى يومه.
- **الموظف:** يرى يومه هو؛ ويعلّم الحجز «تم» أو «لم يحضر».
- **الزبون:** يحجز أو يغيّر أو يلغي، بلا حساب.

## القصص (النسخة الأولى)
- **US-1** بصفتي زبوناً، أرى المواعيد المتاحة لخدمة وموظف.
  - إذا كانت منى تعمل 10:00-14:00 ولديها حجز 10:00-10:30،
    وطلبتُ قص شعر لثلاثين دقيقة، فلا يُعرض 10:00 ويُعرض 10:30.
- **US-2** بصفتي زبوناً، أحجز موعداً.
  - إذا طلب زبونان الموعد نفسه في اللحظة نفسها،
    يُصنع حجز واحد بالضبط، ويرى الآخر «محجوز».
- **US-3** بصفتي زبوناً، يصلني بريد تأكيد، وتذكير قبل الموعد بـ 24 ساعة.
- **US-4** بصفتي زبوناً، ألغي حتى ساعتين قبل الموعد، من الرابط في البريد.
- **US-5** بصفتي صاحب عمل، أرى حجوزات اليوم لكل موظف.

## خارج النسخة الأولى
الدفع الإلكتروني (العربون في النسخة 2)، وتطبيقات الجوال، والفروع المتعددة.

## الجودة
- توافر 99.9% في الشهر؛ وصفحة الحجز p95 أقل من 300 ms.
- 2000 عمل في السنة الأولى؛ و25 حجزاً لكل عمل في اليوم.
- البيانات الشخصية تُحفظ سنتين بعد آخر زيارة، ثم تُحذف.

## المخاطر والأسئلة المفتوحة
- المناطق الزمنية: قد يكون العمل وزبائنه في مناطق مختلفة.
- هل يحتاج الزبائن حساباً ليروا سجلهم؟ (القرار قبل 2026-12-01)
""",
}

FILES = {
    "schema.sql": '''-- {w_c_ext}
CREATE EXTENSION btree_gist;

CREATE TABLE staff (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL
);
CREATE TABLE services (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  minutes integer NOT NULL CHECK (minutes BETWEEN 5 AND 480),
  -- {w_c_money}
  price integer NOT NULL CHECK (price >= 0)
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id bigint NOT NULL REFERENCES staff (id),
  service_id bigint NOT NULL REFERENCES services (id),
  email text NOT NULL,
  -- {w_c_range}
  during tstzrange NOT NULL,
  status text NOT NULL DEFAULT 'confirmed'
    CHECK (status IN ('confirmed', 'cancelled')),
  -- {w_c_rule}
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (staff_id WITH =, during WITH &&) WHERE (status = 'confirmed')
);

INSERT INTO staff (name) VALUES ('{w_mona}'), ('{w_omar}');
INSERT INTO services (name, minutes, price) VALUES ('{w_cut}', 30, 25000);
''',
    "budget.ts": '''// {w_c_avail}
const minutesPerMonth = 30 * 24 * 60;
console.log("{w_t_target}".padEnd(9), "{w_t_down}");
for (const target of [99, 99.5, 99.9, 99.95, 99.99]) {
  const down = minutesPerMonth * (1 - target / 100);
  console.log(`${target}%`.padEnd(9), `${down.toFixed(1)} {w_t_min}`);
}

// {w_c_load}
const businesses = 2_000;
const bookingsPerDay = 25;
const pageViewsPerBooking = 12; // browsing, choosing, booking, the emails' links
const requestsPerPageView = 3; // the page, then the API calls it makes
const perDay = businesses * bookingsPerDay * pageViewsPerBooking * requestsPerPageView;
const average = perDay / 86_400;
console.log();
console.log(perDay.toLocaleString("en"), "{w_t_day}");
console.log(average.toFixed(1), "{w_t_avg}");
console.log((average * 4).toFixed(1), "{w_t_peak}");

// {w_c_data}
const rowsPerYear = businesses * bookingsPerDay * 365;
const bytesPerRow = 200; // the columns, the row header, and the indexes
console.log();
console.log(rowsPerYear.toLocaleString("en"), "{w_t_rows}");
console.log(`${((rowsPerYear * bytesPerRow) / 1024 ** 3).toFixed(1)} GB`, "{w_t_size}");
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.lines.clear()
    insert = ("psql shop -c \"INSERT INTO bookings (staff_id, service_id, email, during) "
              "VALUES ({staff}, 1, '{email}', '[2026-12-01 {start}+02, 2026-12-01 {end}+02)')\"")
    s.note(t["w_s_book"])
    s.run(insert.format(staff=1, email="sara@example.com", start="10:00", end="10:30"))
    s.note(t["w_s_clash"])
    s.run(insert.format(staff=1, email="karim@example.com", start="10:15", end="10:45") + " 2>&1", check=False,
          shown=insert.format(staff=1, email="karim@example.com", start="10:15", end="10:45"))
    s.note(t["w_s_other"])
    s.run(insert.format(staff=2, email="karim@example.com", start="10:15", end="10:45"))
    s.note(t["w_s_next"])
    s.run(insert.format(staff=1, email="nour@example.com", start="10:30", end="11:00"))
    s.note(t["w_s_cancel"])
    s.run("psql shop -c \"UPDATE bookings SET status = 'cancelled' WHERE id = 1\"")
    s.run(insert.format(staff=1, email="karim@example.com", start="10:00", end="10:30"))
    s.save(folder / "rules.sh")
    s.note(t["w_s_budget"])
    s.run("node budget.ts")
    s.save(folder / "budget.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    (folder / "spec.md").write_text(SPEC[lang])
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    record(folder, t)
    print("wrote", lang)
