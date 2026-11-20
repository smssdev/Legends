"""Writes the examples of Book 3 (Laravel edition), the chapter "Queues and Jobs".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL through pg-start, Redis through redis-start)

A fresh Laravel 13 project per language (<lang>/shop) with the Redis queue (Predis): order confirmations
dispatched in a millisecond and sent by `queue:work`, the same order dispatched twice and kept once
(ShouldBeUnique), a flaky mail service retried with growing pauses, a job that fails for good and waits in
failed_jobs until `queue:retry`, dispatching after the commit, and a daily job in the scheduler. Every command
runs for real; the transcripts are what the terminal showed (*.sh).
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
sys.path.insert(0, str(B3 / "php"))
from rec import CLEAN, Session, fill  # noqa: E402
from seed import seed_latest, seed_lock  # noqa: E402

T = {
    "en": dict(
        w_c_queued="queued: the worker will call handle() later, in another process",
        w_c_tries="up to 3 attempts, waiting 1, then 2 seconds between them",
        w_c_unique="one job per order: dispatching the same order again while it waits does nothing",
        w_c_work="the work itself: called once per attempt",
        w_c_never="an address that can never work: fail now, without the remaining attempts",
        w_c_failed="called once, after the last attempt: tell someone",
        w_c_flaky="a mail service that fails the first two times for order 1003",
        w_c_count="counted in the cache, so every worker process sees the same number",
        w_c_commit="dispatched only if the transaction commits",
        w_c_fresh="the job carries the order id; the data is read when it runs",
        w_c_schedule="the sales report every morning at 6, Cairo time",
        w_d_queued="queued in", w_d_sending="sending the confirmation for order", w_d_try="attempt",
        w_d_mail_down="mail service unavailable", w_d_bad_address="invalid address",
        w_d_gave_up="gave up on the confirmation for order", w_d_report="sales report for",
        w_s_dispatch="The shop dispatches four confirmations (and one twice)",
        w_s_waiting="Nobody is working yet: the jobs wait in Redis",
        w_s_worker="A worker starts and does them (stopping after 6 seconds, for this demo)",
        w_s_failed="What is left in the failed jobs table",
        w_s_schedule="What the scheduler will run",
        w_s_retry="The address is fixed; retry the failed job",
    ),
    "ar": dict(
        w_c_queued="في الطابور: سينادي العامل handle() لاحقاً، في عملية أخرى",
        w_c_tries="حتى 3 محاولات، بانتظار ثانية ثم ثانيتين بينها",
        w_c_unique="مهمة واحدة لكل طلب: إرسال الطلب نفسه مرة أخرى وهو ينتظر لا يفعل شيئاً",
        w_c_work="العمل نفسه: يُستدعى مرة لكل محاولة",
        w_c_never="عنوان لا يمكن أن ينجح أبداً: افشل الآن، بلا المحاولات الباقية",
        w_c_failed="يُستدعى مرة، بعد آخر محاولة: أخبر أحداً",
        w_c_flaky="خدمة بريد تفشل أول مرتين للطلب 1003",
        w_c_count="يُعدّ في الذاكرة المؤقتة، فترى كل عملية عاملة الرقم نفسه",
        w_c_commit="يُرسل إلى الطابور فقط إن ثُبّتت المعاملة",
        w_c_fresh="المهمة تحمل رقم الطلب؛ والبيانات تُقرأ حين تعمل",
        w_c_schedule="تقرير المبيعات كل صباح في السادسة بتوقيت القاهرة",
        w_d_queued="في الطابور خلال", w_d_sending="إرسال تأكيد الطلب", w_d_try="المحاولة",
        w_d_mail_down="خدمة البريد غير متاحة", w_d_bad_address="عنوان غير صالح",
        w_d_gave_up="توقفنا عن تأكيد الطلب", w_d_report="تقرير المبيعات عن",
        w_s_dispatch="المتجر يرسل أربعة تأكيدات إلى الطابور (وواحداً مرتين)",
        w_s_waiting="لا أحد يعمل بعد: المهام تنتظر في Redis",
        w_s_worker="عامل يبدأ وينجزها (ويتوقف بعد 6 ثوانٍ، لهذا العرض)",
        w_s_failed="ما بقي في جدول المهام الفاشلة",
        w_s_schedule="ما سينفذه المجدول",
        w_s_retry="أُصلح العنوان؛ أعد المهمة الفاشلة",
    ),
}

FILES = {
    "app/Jobs/SendOrderConfirmation.php": r'''<?php

namespace App\Jobs;

use App\Support\Mailer;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

// {w_c_queued}
class SendOrderConfirmation implements ShouldBeUnique, ShouldQueue
{
    use Queueable;

    // {w_c_tries}
    public int $tries = 3;

    public array $backoff = [1, 2];

    public function __construct(public int $orderId) {}

    // {w_c_unique}
    public function uniqueId(): string
    {
        return "order-{$this->orderId}";
    }

    // {w_c_work}
    public function handle(Mailer $mailer): void
    {
        echo "  {w_d_sending} {$this->orderId} ({w_d_try} {$this->attempts()})\n";
        // {w_c_fresh}
        $email = DB::table('orders')->where('id', $this->orderId)->value('email');
        if (! str_contains($email, '@')) {
            // {w_c_never}
            $this->fail("{w_d_bad_address}: $email");

            return;
        }
        $mailer->send($this->orderId, $email);
    }

    // {w_c_failed}
    public function failed(?Throwable $error): void
    {
        Log::error("{w_d_gave_up} {$this->orderId}", ['reason' => $error?->getMessage()]);
    }
}
''',
    "app/Support/Mailer.php": r'''<?php

namespace App\Support;

use Illuminate\Support\Facades\Cache;
use RuntimeException;

// A stand-in for a real mail service, with its bad days.
class Mailer
{
    public function send(int $orderId, string $email): void
    {
        usleep(300_000);
        // {w_c_count}
        $attempt = Cache::increment("mail-attempts:$orderId");
        // {w_c_flaky}
        if ($orderId === 1003 && $attempt <= 2) {
            throw new RuntimeException('{w_d_mail_down}');
        }
    }
}
''',
    "database/migrations/2026_11_10_000001_create_orders_table.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('email');
        });
        DB::table('orders')->insert([
            ['id' => 1001, 'email' => 'sara@example.com'],
            ['id' => 1002, 'email' => 'omar@example.com'],
            ['id' => 1003, 'email' => 'lina@example.com'],
            ['id' => 1004, 'email' => 'karim-at-example.com'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
''',
    "app/Jobs/SalesReport.php": r'''<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SalesReport implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        echo '  {w_d_report} '.now('Africa/Cairo')->subDay()->toDateString()."\n";
    }
}
''',
    "routes/console.php": r'''<?php

use App\Jobs\SalesReport;
use App\Jobs\SendOrderConfirmation;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schedule;

// {w_c_schedule}
Schedule::job(new SalesReport)->dailyAt('06:00')->timezone('Africa/Cairo');

Artisan::command('shop:dispatch', function () {
    foreach ([1001, 1002, 1003, 1004, 1001] as $orderId) {
        $start = hrtime(true);
        DB::transaction(function () use ($orderId) {
            // ... the order is saved here ...
            // {w_c_commit}
            SendOrderConfirmation::dispatch($orderId)->afterCommit();
        });
        $ms = number_format((hrtime(true) - $start) / 1e6, 1);
        $this->line("order $orderId: {w_d_queued} $ms ms");
    }
});
''',
}


def prepare_cache():
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer require --no-install --no-scripts -q predis/predis"],
                       cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")
    seed_latest("predis/predis")


def write(shop, t):
    for name, text in FILES.items():
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    env = (shop / ".env").read_text()
    for old, new in (("DB_CONNECTION=sqlite", "DB_CONNECTION=pgsql"), ("# DB_HOST=127.0.0.1", "DB_HOST=127.0.0.1"),
                     ("# DB_PORT=3306", "DB_PORT=5432"), ("# DB_DATABASE=laravel", "DB_DATABASE=shop"),
                     ("# DB_USERNAME=root", "DB_USERNAME=bit"), ("# DB_PASSWORD=", "DB_PASSWORD=secret"),
                     ("QUEUE_CONNECTION=database", "QUEUE_CONNECTION=redis"),
                     ("CACHE_STORE=database", "CACHE_STORE=redis"),
                     ("REDIS_CLIENT=phpredis", "REDIS_CLIENT=predis")):
        assert old in env, old
        env = env.replace(old, new)
    (shop / ".env").write_text(env)


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    s.run("composer require predis/predis --no-interaction -q")
    write(shop, t)
    s.run("vendor/bin/pint --quiet app routes")
    s.run("php artisan migrate --no-ansi -q")
    s.lines.clear()

    s.note(t["w_s_dispatch"])
    s.run("php artisan shop:dispatch")
    s.note(t["w_s_waiting"])
    s.run("php artisan queue:monitor redis:default --no-ansi")
    s.save(folder / "dispatch.sh")
    s.note(t["w_s_worker"])
    s.run("php artisan queue:work --max-time=6 --sleep=1 --no-ansi "
          "| sed -E 's/^ *[0-9-]+ ([0-9:]+) /  \\1 /; s/ \\.{3,} / … /'",
          shown="php artisan queue:work --max-time=6")
    s.save(folder / "worker.sh")
    s.note(t["w_s_failed"])
    s.run("php artisan queue:failed --no-ansi | sed -E 's/[0-9a-f]{8}-[0-9a-f-]{27}/…/'",
          shown="php artisan queue:failed")
    s.run("psql shop -c \"SELECT substring(exception from ': (.*?) in ') AS reason FROM failed_jobs\"")
    s.save(folder / "failed.sh")
    s.note(t["w_s_schedule"])
    s.run("php artisan schedule:list --no-ansi")
    s.save(folder / "schedule.sh")
    s.note(t["w_s_retry"])
    s.run("psql shop -q -c \"UPDATE orders SET email = 'karim@example.com' WHERE id = 1004\"")
    s.run("php artisan queue:retry all --no-ansi | sed -E 's/[0-9a-f]{8}-[0-9a-f-]{27}/…/'",
          shown="php artisan queue:retry all")
    s.run("php artisan queue:work --max-time=6 --sleep=1 --no-ansi "
          "| sed -E 's/^ *[0-9-]+ ([0-9:]+) /  \\1 /; s/ \\.{3,} / … /'",
          shown="php artisan queue:work --max-time=6")
    s.save(folder / "answers.sh")


prepare_cache()
for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    Session(folder).run("composer create-project laravel/laravel shop --no-interaction -q")
    shop = folder / "shop"
    record(shop, t)
    for junk in ("AGENTS.md", "CLAUDE.md", "CHANGELOG.md", ".github", ".styleci.yml", ".phpunit.result.cache",
                 "vendor", "storage/logs/laravel.log", "database/database.sqlite", ".env",
                 "storage/framework/cache/data", "storage/framework/sessions", "storage/framework/views"):
        path = shop / junk
        if path.is_dir():
            shutil.rmtree(path)
            if junk.startswith(("vendor", "storage")):
                path.mkdir()
        elif path.exists():
            path.unlink()
    print("wrote", lang)
