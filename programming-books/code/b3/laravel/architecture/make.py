"""Writes the examples of Book 3 (Laravel edition), the chapter "Architecture: Keeping Code Easy to Change".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL through bin/pg-start)

A fresh Laravel 13 project per language (<lang>/shop) with the order feature as one module, app/Orders: pure
domain rules and errors, ports (interfaces), an action that orchestrates them, adapters for the database and
mail, a thin controller, and the service container as the composition root. The action is tested with fakes
in Pest, Pest architecture tests guard the layers (and fail when the domain uses the DB facade), and the route
runs against PostgreSQL. Transcripts are what the terminal showed (*.sh).
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
from rec import CLEAN, Server, Session, fill  # noqa: E402
from seed import seed_latest, seed_lock  # noqa: E402

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels",
        w_c_domain="the domain: the shop's rules in plain PHP; no facades, no Eloquent, no HTTP",
        w_c_limit="a rule of the business, not of the database or the API",
        w_c_error="errors that speak the business's language; each adapter decides what they become",
        w_c_store="a port: what the action needs, described by the action",
        w_c_action="the action: one thing the shop does, start to finish, through its ports",
        w_c_after="the email after the order is saved, never inside its transaction",
        w_c_adapter="an adapter: the OrderStore port, implemented with Laravel's query builder",
        w_c_http="the HTTP adapter: validated input in, a response or an error out",
        w_c_bind="the composition root: which concrete class answers each port",
        w_c_fakes="fakes: the ports, implemented in memory for this test",
        w_c_arch="the layers, checked on every run",
        w_m_limit="At most 10 of one product per order", w_m_stock="Not enough stock",
        w_m_unknown="Unknown product",
        w_t_places="places an order, saves it and sends one email",
        w_t_limit="refuses more than 10 of one product, before touching the store",
        w_t_stock="sends no email when the store reports too little stock",
        w_t_pure="keeps the domain free of Laravel and of the adapters",
        w_t_action="lets the action use only the domain and the ports",
        w_s_tree="The order module", w_s_test="The tests: an action without a database, and the layers",
        w_s_place="An order", w_s_limit="Eleven of one product", w_s_stock="More than the stock",
        w_s_break="Someone uses the DB facade in the domain",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية",
        w_c_domain="المجال: قواعد المتجر بـ PHP عادية؛ بلا واجهات، ولا Eloquent، ولا HTTP",
        w_c_limit="قاعدة من قواعد العمل، لا من قواعد قاعدة البيانات ولا API",
        w_c_error="أخطاء تتكلم لغة العمل؛ وكل محوّل يقرر ماذا تصير",
        w_c_store="منفذ: ما يحتاجه الفعل، كما يصفه هو",
        w_c_action="الفعل: شيء واحد يفعله المتجر، من البداية إلى النهاية، عبر منافذه",
        w_c_after="البريد بعد حفظ الطلب، لا داخل معاملته أبداً",
        w_c_adapter="محوّل: المنفذ OrderStore، مطبَّقاً بباني الاستعلامات في Laravel",
        w_c_http="محوّل HTTP: مدخلات مُتحقق منها إلى الداخل، ورد أو خطأ إلى الخارج",
        w_c_bind="جذر التركيب: أي صنف حقيقي يجيب كل منفذ",
        w_c_fakes="البدائل: المنافذ، مطبَّقة في الذاكرة لهذا الاختبار",
        w_c_arch="الطبقات، تُفحص في كل تشغيل",
        w_m_limit="10 على الأكثر من المنتج الواحد في الطلب", w_m_stock="المخزون لا يكفي",
        w_m_unknown="منتج مجهول",
        w_t_places="places an order, saves it and sends one email",
        w_t_limit="refuses more than 10 of one product, before touching the store",
        w_t_stock="sends no email when the store reports too little stock",
        w_t_pure="keeps the domain free of Laravel and of the adapters",
        w_t_action="lets the action use only the domain and the ports",
        w_s_tree="وحدة الطلبات", w_s_test="الاختبارات: فعل بلا قاعدة بيانات، والطبقات",
        w_s_place="طلب", w_s_limit="أحد عشر من منتج واحد", w_s_stock="أكثر من المخزون",
        w_s_break="أحدهم يستخدم واجهة DB في المجال",
    ),
}

FILES = {
    "database/migrations/2026_11_13_000001_create_shop_tables.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
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
            $table->timestampTz('placed_at');
        });
        Schema::create('order_items', function (Blueprint $table) {
            $table->foreignId('order_id')->index()->constrained();
            $table->foreignId('product_id')->constrained();
            $table->integer('quantity');
            $table->integer('price');
        });
        DB::table('products')->insert([
            ['id' => 1, 'name' => '{w_kit}', 'price' => 45000, 'stock' => 5],
            ['id' => 2, 'name' => '{w_wheels}', 'price' => 6000, 'stock' => 50],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
    }
};
''',
    "app/Orders/Domain/OrderRules.php": r'''<?php

namespace App\Orders\Domain;

// {w_c_domain}
final class OrderRules
{
    // {w_c_limit}
    public const MAX_PER_PRODUCT = 10;

    /** @param list<array{product_id: int, quantity: int}> $items */
    public static function checkQuantities(array $items): void
    {
        foreach ($items as $item) {
            if ($item['quantity'] > self::MAX_PER_PRODUCT) {
                throw new TooMany('{w_m_limit}');
            }
        }
    }

    /** @param list<array{quantity: int, price: int}> $lines */
    public static function total(array $lines): int
    {
        return array_sum(array_map(fn ($l) => $l['quantity'] * $l['price'], $lines));
    }
}
''',
    "app/Orders/Domain/OrderError.php": r'''<?php

namespace App\Orders\Domain;

use DomainException;

// {w_c_error}
abstract class OrderError extends DomainException {}
''',
    "app/Orders/Domain/TooMany.php": "<?php\n\nnamespace App\\Orders\\Domain;\n\nfinal class TooMany extends OrderError {}\n",
    "app/Orders/Domain/OutOfStock.php": "<?php\n\nnamespace App\\Orders\\Domain;\n\nfinal class OutOfStock extends OrderError {}\n",
    "app/Orders/Domain/UnknownProduct.php": "<?php\n\nnamespace App\\Orders\\Domain;\n\nfinal class UnknownProduct extends OrderError {}\n",
    "app/Orders/Domain/PlacedOrder.php": r'''<?php

namespace App\Orders\Domain;

final readonly class PlacedOrder
{
    public function __construct(public int $id, public string $email, public int $total) {}
}
''',
    "app/Orders/Ports/OrderStore.php": r'''<?php

namespace App\Orders\Ports;

use App\Orders\Domain\PlacedOrder;
use DateTimeImmutable;

// {w_c_store}
interface OrderStore
{
    /**
     * Takes the stock and saves the order, all or nothing; prices come from the store.
     *
     * @param  list<array{product_id: int, quantity: int}>  $items
     */
    public function place(string $email, array $items, DateTimeImmutable $placedAt): PlacedOrder;
}
''',
    "app/Orders/Ports/Mailer.php": r'''<?php

namespace App\Orders\Ports;

interface Mailer
{
    public function send(string $to, string $subject): void;
}
''',
    "app/Orders/Actions/PlaceOrder.php": r'''<?php

namespace App\Orders\Actions;

use App\Orders\Domain\OrderRules;
use App\Orders\Domain\PlacedOrder;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;
use DateTimeImmutable;

// {w_c_action}
final readonly class PlaceOrder
{
    public function __construct(private OrderStore $store, private Mailer $mailer) {}

    /** @param list<array{product_id: int, quantity: int}> $items */
    public function __invoke(string $email, array $items, DateTimeImmutable $now): PlacedOrder
    {
        OrderRules::checkQuantities($items);
        $order = $this->store->place($email, $items, $now);
        // {w_c_after}
        $this->mailer->send($email, "Order {$order->id}: ".($order->total / 100).' EGP');

        return $order;
    }
}
''',
    "app/Orders/Infrastructure/QueryBuilderOrderStore.php": r'''<?php

namespace App\Orders\Infrastructure;

use App\Orders\Domain\OrderRules;
use App\Orders\Domain\OutOfStock;
use App\Orders\Domain\PlacedOrder;
use App\Orders\Domain\UnknownProduct;
use App\Orders\Ports\OrderStore;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

// {w_c_adapter}
final class QueryBuilderOrderStore implements OrderStore
{
    public function place(string $email, array $items, DateTimeImmutable $placedAt): PlacedOrder
    {
        return DB::transaction(function () use ($email, $items, $placedAt) {
            $lines = [];
            foreach ($items as ['product_id' => $id, 'quantity' => $quantity]) {
                $taken = DB::table('products')->where('id', $id)
                    ->where('stock', '>=', $quantity)->decrement('stock', $quantity);
                if ($taken === 0) {
                    throw DB::table('products')->where('id', $id)->exists()
                        ? new OutOfStock('{w_m_stock}')
                        : new UnknownProduct('{w_m_unknown}');
                }
                $price = DB::table('products')->where('id', $id)->value('price');
                $lines[] = ['product_id' => $id, 'quantity' => $quantity, 'price' => $price];
            }
            $total = OrderRules::total($lines);
            $orderId = DB::table('orders')->insertGetId(
                ['email' => $email, 'total' => $total, 'placed_at' => $placedAt],
            );
            DB::table('order_items')->insert(
                array_map(fn ($line) => ['order_id' => $orderId] + $line, $lines),
            );

            return new PlacedOrder($orderId, $email, $total);
        });
    }
}
''',
    "app/Orders/Infrastructure/LogMailer.php": r'''<?php

namespace App\Orders\Infrastructure;

use App\Orders\Ports\Mailer;
use Illuminate\Support\Facades\Log;

final class LogMailer implements Mailer
{
    public function send(string $to, string $subject): void
    {
        Log::info("mail to $to: $subject");
    }
}
''',
    "app/Orders/Http/PlaceOrderController.php": r'''<?php

namespace App\Orders\Http;

use App\Orders\Actions\PlaceOrder;
use App\Orders\Domain\OrderError;
use App\Orders\Domain\OutOfStock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

// {w_c_http}
final class PlaceOrderController
{
    public function __invoke(Request $request, PlaceOrder $placeOrder): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'items' => ['required', 'array', 'min:1', 'max:20'],
            'items.*.product_id' => ['required', 'integer'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);
        try {
            $order = $placeOrder($data['email'], $data['items'], now()->toDateTimeImmutable());
        } catch (OrderError $error) {
            $status = $error instanceof OutOfStock ? 409 : 422;

            return response()->json(['title' => $error->getMessage(), 'status' => $status], $status);
        }

        return response()->json(['id' => $order->id, 'total' => $order->total], 201);
    }
}
''',
    "app/Providers/AppServiceProvider.php": r'''<?php

namespace App\Providers;

use App\Orders\Infrastructure\LogMailer;
use App\Orders\Infrastructure\QueryBuilderOrderStore;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    // {w_c_bind}
    public array $bindings = [
        OrderStore::class => QueryBuilderOrderStore::class,
        Mailer::class => LogMailer::class,
    ];
}
''',
    "routes/api.php": r'''<?php

use App\Orders\Http\PlaceOrderController;
use Illuminate\Support\Facades\Route;

Route::post('orders', PlaceOrderController::class);
''',
    "tests/Unit/PlaceOrderTest.php": r'''<?php

use App\Orders\Actions\PlaceOrder;
use App\Orders\Domain\OutOfStock;
use App\Orders\Domain\PlacedOrder;
use App\Orders\Domain\TooMany;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;

// {w_c_fakes}
function fakeMailer(): Mailer
{
    return new class implements Mailer
    {
        public array $sent = [];

        public function send(string $to, string $subject): void
        {
            $this->sent[] = $to;
        }
    };
}

function fakeStore(Closure $place): OrderStore
{
    return new class($place) implements OrderStore
    {
        public function __construct(private Closure $place) {}

        public function place(string $email, array $items, DateTimeImmutable $placedAt): PlacedOrder
        {
            return ($this->place)($email, $items, $placedAt);
        }
    };
}

$now = new DateTimeImmutable('2026-11-20 10:00:00');

it('{w_t_places}', function () use ($now) {
    $mailer = fakeMailer();
    $store = fakeStore(fn ($email) => new PlacedOrder(7, $email, 12000));
    $order = (new PlaceOrder($store, $mailer))('sara@example.com', [['product_id' => 2, 'quantity' => 2]], $now);

    expect($order->total)->toBe(12000)
        ->and($mailer->sent)->toBe(['sara@example.com']);
});

it('{w_t_limit}', function () use ($now) {
    $store = fakeStore(fn () => throw new LogicException('the store must not be called'));
    (new PlaceOrder($store, fakeMailer()))('a@b.c', [['product_id' => 1, 'quantity' => 11]], $now);
})->throws(TooMany::class);

it('{w_t_stock}', function () use ($now) {
    $mailer = fakeMailer();
    $store = fakeStore(fn () => throw new OutOfStock('no'));

    expect(fn () => (new PlaceOrder($store, $mailer))('a@b.c', [['product_id' => 1, 'quantity' => 9]], $now))
        ->toThrow(OutOfStock::class)
        ->and($mailer->sent)->toBe([]);
});
''',
    "tests/Unit/ArchTest.php": r'''<?php

// {w_c_arch}
arch('{w_t_pure}')
    ->expect('App\Orders\Domain')
    ->not->toUse(['Illuminate', 'App\Orders\Infrastructure', 'App\Orders\Http']);

arch('{w_t_action}')
    ->expect('App\Orders\Actions')
    ->toOnlyUse(['App\Orders\Domain', 'App\Orders\Ports']);
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
    s.run("composer remove --dev phpunit/phpunit --no-interaction -q && composer require --dev -W "
          "pestphp/pest pestphp/pest-plugin-laravel --no-interaction -q")
    s.run("./vendor/bin/pest --init --no-interaction < /dev/null > /dev/null 2>&1")
    s.run("php artisan install:api --no-interaction -q")
    for path in ("tests/Unit/ExampleTest.php", "tests/Feature/ExampleTest.php"):
        (shop / path).unlink(missing_ok=True)
    for name, text in FILES.items():
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    env = (shop / ".env").read_text()
    for old, new in (("DB_CONNECTION=sqlite", "DB_CONNECTION=pgsql"), ("# DB_HOST=127.0.0.1", "DB_HOST=127.0.0.1"),
                     ("# DB_PORT=3306", "DB_PORT=5432"), ("# DB_DATABASE=laravel", "DB_DATABASE=shop"),
                     ("# DB_USERNAME=root", "DB_USERNAME=bit"), ("# DB_PASSWORD=", "DB_PASSWORD=secret"),
                     ("APP_DEBUG=true", "APP_DEBUG=false")):
        env = env.replace(old, new)
    (shop / ".env").write_text(env)
    s.run("vendor/bin/pint --quiet app routes tests database")
    s.run("php artisan migrate:fresh --no-ansi -q")
    s.lines.clear()

    s.note(t["w_s_tree"])
    s.run("find app/Orders -name '*.php' | sort")
    s.save(folder / "tree.sh")
    s.note(t["w_s_test"])
    s.run("./vendor/bin/pest --colors=never tests/Unit 2>&1 | sed -E 's/Duration: .*/Duration: …/; s/ +[0-9.]+s *$//'",
          shown="./vendor/bin/pest tests/Unit")
    s.save(folder / "test.sh")

    post = ("curl -s localhost:8000/api/orders -H 'Accept: application/json' -H 'Content-Type: application/json' "
            "-d '{{\"email\":\"sara@example.com\",\"items\":[{items}]}}' | jq -c")
    with Server("php artisan serve --no-ansi", shop, "http://localhost:8000/up"):
        s.note(t["w_s_place"])
        s.run(post.format(items='{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}'))
        s.note(t["w_s_limit"])
        s.run(post.format(items='{"product_id":2,"quantity":11}'))
        s.note(t["w_s_stock"])
        s.run(post.format(items='{"product_id":1,"quantity":4}'))
        s.run("psql shop -c 'SELECT id, stock FROM products ORDER BY id'")
        s.run("grep -o 'mail to.*' storage/logs/laravel.log")
        s.save(folder / "http.sh")

    domain = shop / "app/Orders/Domain/OrderRules.php"
    original = domain.read_text()
    domain.write_text(original.replace("namespace App\\Orders\\Domain;\n",
                                       "namespace App\\Orders\\Domain;\n\nuse Illuminate\\Support\\Facades\\DB;\n", 1))
    s.note(t["w_s_break"])
    s.run("./vendor/bin/pest --colors=never tests/Unit/ArchTest.php 2>&1 | grep -E 'FAILED|Expecting' | head -2",
          shown="./vendor/bin/pest tests/Unit/ArchTest.php", check=False)
    s.save(folder / "break.sh")
    domain.write_text(original)


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
