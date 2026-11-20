"""Writes the examples of Book 3 (Laravel edition), the chapter "Testing with Pest".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL through bin/pg-start)

A fresh Laravel 13 project per language (<lang>/shop) tested with Pest: unit tests for pricing with a
dataset, feature tests through the order route against a real PostgreSQL test database (RefreshDatabase),
Queue::fake for the confirmation job, travel() for an expiry rule, an architecture test, a failing test to
read, and filtering. Every command runs for real; the transcripts are what the terminal showed (*.sh).
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
        w_c_pure="pure: the same input always gives the same output, and nothing else happens",
        w_c_codes="discount codes: a percentage off, or a fixed amount (never below the subtotal)",
        w_c_vat="VAT of 14% on the discounted subtotal, rounded to the nearest piastre",
        w_c_bug="exercise 1: a bug to find, switched on with BUG=1",
        w_c_expiry="a basket left alone for 30 minutes is released",
        w_c_dataset="one row per case: adding a case is one line",
        w_c_fake="the queue is faked: jobs are recorded instead of being pushed to Redis",
        w_c_travel="move the application's clock instead of waiting 30 minutes",
        w_c_arch="rules about the code itself, checked like any test",
        w_d_unknown="unknown discount code", w_d_stock="Not enough stock",
        w_t_plain="no code: subtotal plus VAT", w_t_percent="SAVE10 takes 10% off",
        w_t_fixed="FIXED50 takes 50 pounds off", w_t_floor="never lets a fixed discount go below zero",
        w_t_unknown="refuses an unknown code",
        w_t_creates="creates an order and queues one confirmation",
        w_t_stock="refuses an order larger than the stock, and changes nothing",
        w_t_invalid="refuses a body without a quantity",
        w_t_fresh="keeps a basket touched 29 minutes ago", w_t_old="releases a basket left for 30 minutes",
        w_t_debug="leaves no debugging calls in the code",
        w_s_install="Pest, installed and initialised", w_s_run="All the tests",
        w_s_filter="Only the tests whose name matches", w_s_fail="A test that fails",
    ),
    "ar": dict(
        w_c_pure="نقية: المدخل نفسه يعطي المخرج نفسه دائماً، ولا يحدث شيء آخر",
        w_c_codes="أكواد الخصم: نسبة مئوية، أو مبلغ ثابت (لا يتجاوز المجموع أبداً)",
        w_c_vat="ضريبة 14% على المجموع بعد الخصم، مقرَّبة إلى أقرب قرش",
        w_c_bug="التمرين 1: خطأ يُبحث عنه، يُشغَّل بـ BUG=1",
        w_c_expiry="السلة المتروكة 30 دقيقة تُحرَّر",
        w_c_dataset="صف لكل حالة: إضافة حالة سطر واحد",
        w_c_fake="الطابور وهمي: تُسجَّل المهام بدل دفعها إلى Redis",
        w_c_travel="حرّك ساعة التطبيق بدل انتظار 30 دقيقة",
        w_c_arch="قواعد عن الكود نفسه، تُفحص كأي اختبار",
        w_d_unknown="كود خصم مجهول", w_d_stock="المخزون لا يكفي",
        w_t_plain="no code: subtotal plus VAT", w_t_percent="SAVE10 takes 10% off",
        w_t_fixed="FIXED50 takes 50 pounds off", w_t_floor="never lets a fixed discount go below zero",
        w_t_unknown="refuses an unknown code",
        w_t_creates="creates an order and queues one confirmation",
        w_t_stock="refuses an order larger than the stock, and changes nothing",
        w_t_invalid="refuses a body without a quantity",
        w_t_fresh="keeps a basket touched 29 minutes ago", w_t_old="releases a basket left for 30 minutes",
        w_t_debug="leaves no debugging calls in the code",
        w_s_install="تثبيت Pest وتهيئته", w_s_run="كل الاختبارات",
        w_s_filter="الاختبارات التي يطابقها الاسم وحدها", w_s_fail="اختبار يفشل",
    ),
}

FILES = {
    "database/migrations/2026_11_12_000001_create_shop_tables.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->integer('price');
            $table->integer('stock');
        });
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->integer('total');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
    }
};
''',
    "app/Support/Pricing.php": r'''<?php

namespace App\Support;

use InvalidArgumentException;

// {w_c_pure}
class Pricing
{
    private const CODES = ['SAVE10' => ['percent' => 10], 'FIXED50' => ['amount' => 5000]];

    /** @param list<array{price: int, quantity: int}> $lines */
    public static function total(array $lines, ?string $code = null): array
    {
        $subtotal = array_sum(array_map(fn ($l) => $l['price'] * $l['quantity'], $lines));
        $discount = 0;
        if ($code !== null) {
            // {w_c_codes}
            $rule = self::CODES[$code] ?? throw new InvalidArgumentException("{w_d_unknown}: $code");
            $discount = isset($rule['percent'])
                ? (int) round($subtotal * $rule['percent'] / 100)
                : $rule['amount'];
            $discount = min($discount, $subtotal);
        }
        // {w_c_vat}
        // {w_c_bug}
        $rate = getenv('BUG') ? 15 : 14;
        $vat = (int) round(($subtotal - $discount) * $rate / 100);

        return compact('subtotal', 'discount', 'vat') + ['total' => $subtotal - $discount + $vat];
    }
}
''',
    "app/Support/Baskets.php": r'''<?php

namespace App\Support;

use Illuminate\Support\Carbon;

// {w_c_expiry}
class Baskets
{
    public static function isExpired(Carbon $lastTouched): bool
    {
        return $lastTouched->diffInMinutes(now()) >= 30;
    }
}
''',
    "app/Jobs/SendOrderConfirmation.php": r'''<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendOrderConfirmation implements ShouldQueue
{
    use Queueable;

    public function __construct(public int $orderId) {}

    public function handle(): void
    {
        // the email would be sent here (Chapter 11)
    }
}
''',
    "app/Http/Controllers/OrderController.php": r'''<?php

namespace App\Http\Controllers;

use App\Jobs\SendOrderConfirmation;
use App\Support\Pricing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'product_id' => ['required', 'integer'],
            'quantity' => ['required', 'integer', 'min:1', 'max:99'],
            'code' => ['nullable', 'string'],
        ]);
        $order = DB::transaction(function () use ($data) {
            $taken = DB::table('products')->where('id', $data['product_id'])
                ->where('stock', '>=', $data['quantity'])->decrement('stock', $data['quantity']);
            if ($taken === 0) {
                return null;
            }
            $price = DB::table('products')->where('id', $data['product_id'])->value('price');
            $sum = Pricing::total([['price' => $price, 'quantity' => $data['quantity']]], $data['code'] ?? null);
            $id = DB::table('orders')->insertGetId(['email' => $data['email'], 'total' => $sum['total']]);

            return ['id' => $id, 'total' => $sum['total']];
        });
        abort_if($order === null, 409, '{w_d_stock}');
        SendOrderConfirmation::dispatch($order['id'])->afterCommit();

        return response()->json($order, 201);
    }
}
''',
    "routes/api.php": r'''<?php

use App\Http\Controllers\OrderController;
use Illuminate\Support\Facades\Route;

Route::post('orders', [OrderController::class, 'store']);
''',
    "tests/Unit/PricingTest.php": r'''<?php

use App\Support\Pricing;

$lines = [['price' => 45000, 'quantity' => 1], ['price' => 6000, 'quantity' => 2]];

// {w_c_dataset}
it('computes totals', function (?string $code, array $expected) use ($lines) {
    expect(Pricing::total($lines, $code))->toMatchArray($expected);
})->with([
    '{w_t_plain}' => [null, ['discount' => 0, 'vat' => 7980, 'total' => 64980]],
    '{w_t_percent}' => ['SAVE10', ['discount' => 5700, 'vat' => 7182, 'total' => 58482]],
    '{w_t_fixed}' => ['FIXED50', ['discount' => 5000, 'vat' => 7280, 'total' => 59280]],
]);

it('{w_t_floor}', function () {
    expect(Pricing::total([['price' => 3000, 'quantity' => 1]], 'FIXED50'))
        ->toBe(['subtotal' => 3000, 'discount' => 3000, 'vat' => 0, 'total' => 0]);
});

it('{w_t_unknown}', function () {
    Pricing::total([['price' => 3000, 'quantity' => 1]], 'FREE');
})->throws(InvalidArgumentException::class, 'FREE');
''',
    "tests/Feature/OrdersTest.php": r'''<?php

use App\Jobs\SendOrderConfirmation;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

beforeEach(function () {
    DB::table('products')->insert(['id' => 1, 'name' => 'Kit', 'price' => 45000, 'stock' => 3]);
    // {w_c_fake}
    Queue::fake();
});

function order(int $quantity)
{
    return test()->postJson('/api/orders', [
        'email' => 'sara@example.com', 'product_id' => 1, 'quantity' => $quantity, 'code' => 'SAVE10',
    ]);
}

it('{w_t_creates}', function () {
    order(2)->assertCreated()->assertExactJson(['id' => 1, 'total' => 92340]);

    expect(DB::table('products')->value('stock'))->toBe(1);
    Queue::assertPushed(SendOrderConfirmation::class, fn ($job) => $job->orderId === 1);
    Queue::assertPushed(SendOrderConfirmation::class, 1);
});

it('{w_t_stock}', function () {
    order(4)->assertConflict();

    expect(DB::table('orders')->count())->toBe(0);
    expect(DB::table('products')->value('stock'))->toBe(3);
    Queue::assertNothingPushed();
});

it('{w_t_invalid}', function () {
    $this->postJson('/api/orders', ['email' => 'sara@example.com', 'product_id' => 1])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('quantity');
});
''',
    "tests/Feature/BasketsTest.php": r'''<?php

use App\Support\Baskets;

it('{w_t_fresh}', function () {
    $touched = now();
    // {w_c_travel}
    $this->travel(29)->minutes();
    expect(Baskets::isExpired($touched))->toBeFalse();
});

it('{w_t_old}', function () {
    $touched = now();
    $this->travel(30)->minutes();
    expect(Baskets::isExpired($touched))->toBeTrue();
});
''',
    "tests/Unit/ArchTest.php": r'''<?php

// {w_c_arch}
arch('{w_t_debug}')
    ->expect(['dd', 'dump', 'ray', 'var_dump'])
    ->not->toBeUsed();

arch()->preset()->laravel();
''',
}


def prepare_cache():
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer remove --dev --no-install --no-scripts -q phpunit/phpunit && "
                        "composer require --dev --no-install --no-scripts -q -W pestphp/pest "
                        "pestphp/pest-plugin-laravel"], cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")
    seed_latest("laravel/sanctum")


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    s.note(t["w_s_install"])
    s.run("composer remove --dev phpunit/phpunit --no-interaction -q && composer require --dev -W "
          "pestphp/pest pestphp/pest-plugin-laravel --no-interaction -q", shown=
          "composer require --dev -W pestphp/pest pestphp/pest-plugin-laravel")
    s.run("./vendor/bin/pest --init --no-interaction < /dev/null 2>&1 | grep -E 'INFO|created|Created' | head -4",
          shown="./vendor/bin/pest --init")
    s.save(folder / "install.sh")
    s.run("php artisan install:api --no-interaction -q")
    for path in ("tests/Unit/ExampleTest.php", "tests/Feature/ExampleTest.php"):
        (shop / path).unlink(missing_ok=True)
    for name, text in FILES.items():
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    pest = shop / "tests/Pest.php"
    text = pest.read_text()
    old = " // ->use(RefreshDatabase::class)"
    assert old in text, text
    text = text.replace(old, "    ->use(RefreshDatabase::class)")
    pest.write_text(text)
    xml = shop / "phpunit.xml"
    text = xml.read_text()
    for old, new in (('<env name="DB_CONNECTION" value="sqlite"/>', '<env name="DB_CONNECTION" value="pgsql"/>'),
                     ('<env name="DB_DATABASE" value=":memory:"/>', '<env name="DB_DATABASE" value="shop_test"/>')):
        assert old in text, old
        text = text.replace(old, new)
    xml.write_text(text.replace('<env name="DB_DATABASE" value="shop_test"/>',
                                '<env name="DB_DATABASE" value="shop_test"/>\n        '
                                '<env name="DB_HOST" value="127.0.0.1"/>\n        '
                                '<env name="DB_USERNAME" value="bit"/>\n        '
                                '<env name="DB_PASSWORD" value="secret"/>'))
    s.run("psql shop -q -c 'CREATE DATABASE shop_test'")
    s.run("vendor/bin/pint --quiet app routes tests database")
    s.lines.clear()

    s.note(t["w_s_run"])
    s.run("./vendor/bin/pest --colors=never 2>&1 | sed -E 's/Duration: .*/Duration: …/; s/ +[0-9.]+s *$//'",
          shown="./vendor/bin/pest")
    s.save(folder / "run.sh")
    s.note(t["w_s_filter"])
    s.run("./vendor/bin/pest --colors=never --filter=basket 2>&1 | sed -E 's/ +[0-9.]+s *$//; "
          "s/Duration: .*/Duration: …/'", shown="./vendor/bin/pest --filter=basket")
    s.save(folder / "filter.sh")
    s.note(t["w_s_fail"])
    s.run("BUG=1 ./vendor/bin/pest --colors=never tests/Unit 2>&1 | sed -E 's/ +[0-9.]+s *$//' "
          "| sed -n '/FAILED/,$p' | head -15", check=False, shown="BUG=1 ./vendor/bin/pest tests/Unit")
    s.save(folder / "fail.sh")


prepare_cache()
for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
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
