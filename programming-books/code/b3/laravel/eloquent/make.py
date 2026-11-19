"""Writes the examples of Book 3 (Laravel edition), chapter 6 "Eloquent, Relationships and Migrations".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL through bin/pg-start)

A fresh Laravel 13 project per language (<lang>/shop) on PostgreSQL: migrations (with a SKU added by expand
and contract), models with relationships, an enum cast and a scope, and Artisan commands that show the
queries Eloquent sends: an order with its relations, the N+1 problem counted, lazy loading refused, and mass
assignment protection. Each command runs for real; the transcripts are what the terminal showed (*.sh).
"""
import glob
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
from seed import seed_lock  # noqa: E402

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels", w_battery="Battery pack", w_cable="USB cable",
        w_sara="Sara", w_omar="Omar", w_lina="Lina",
        w_pending="Waiting for payment", w_paid="Paid", w_shipped="On its way", w_cancelled="Cancelled",
        w_c_expand="Step 1, expand: a column that may be empty, so the code already running keeps working.",
        w_c_contract="Step 3, contract: every row has a SKU now; make it required and unique.",
        w_c_backfill="Step 2: fill it for the existing rows, in chunks.",
        w_c_pivot="order_items joins orders and products, and carries its own facts",
        w_c_scope="a reusable condition: Order::query()->shipped()",
        w_c_cast="the column holds text; the model gives you the enum",
        w_c_strict="in development: no lazy loading, no silently ignored attributes",
        w_c_count="every query Laravel sends, counted",
        w_c_lazy="each ->products loads that order's products: one more query per order",
        w_c_eager="two queries: the orders, then all their products at once",
        w_d_queries="queries", w_d_orders="orders",
        w_s_db="Laravel talks to PostgreSQL: the settings in .env",
        w_s_migrate="Run the migrations", w_s_table="The table after the three migrations",
        w_s_rollback="Undo the last migration, then run it again",
        w_s_order="An order with its customer and products, and the queries behind it",
        w_s_n1="The same report two ways: count the queries",
        w_s_strict="With lazy loading turned off, the N+1 is an error in development",
        w_s_mass="Mass assignment: only the fillable attributes",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية", w_battery="حزمة بطارية", w_cable="كابل USB",
        w_sara="سارة", w_omar="عمر", w_lina="لينا",
        w_pending="بانتظار الدفع", w_paid="مدفوع", w_shipped="في الطريق", w_cancelled="ملغى",
        w_c_expand="الخطوة 1، التوسيع: عمود يجوز أن يكون فارغاً، فيبقى الكود العامل يعمل.",
        w_c_contract="الخطوة 3، التقليص: لكل صف SKU الآن، فاجعله إلزامياً وفريداً.",
        w_c_backfill="الخطوة 2: املأه للصفوف الموجودة، على دفعات.",
        w_c_pivot="order_items يربط الطلبات بالمنتجات، ويحمل حقائقه الخاصة",
        w_c_scope="شرط قابل لإعادة الاستخدام: Order::query()->shipped()",
        w_c_cast="العمود يحمل نصاً، والنموذج يعطيك التعداد",
        w_c_strict="أثناء التطوير: لا تحميل كسول، ولا خصائص تُتجاهل بصمت",
        w_c_count="كل استعلام يرسله Laravel، معدوداً",
        w_c_lazy="كل ->products يحمّل منتجات ذلك الطلب: استعلام إضافي لكل طلب",
        w_c_eager="استعلامان: الطلبات، ثم كل منتجاتها دفعة واحدة",
        w_d_queries="استعلامات", w_d_orders="طلبات",
        w_s_db="يتحدث Laravel إلى PostgreSQL: الإعدادات في ‎.env",
        w_s_migrate="شغّل الترحيلات", w_s_table="الجدول بعد الترحيلات الثلاثة",
        w_s_rollback="تراجع عن آخر ترحيل، ثم شغّله مرة أخرى",
        w_s_order="طلب مع عميله ومنتجاته، والاستعلامات التي وراءه",
        w_s_n1="التقرير نفسه بطريقتين: عُدّ الاستعلامات",
        w_s_strict="مع إيقاف التحميل الكسول، يصير N+1 خطأً أثناء التطوير",
        w_s_mass="الإسناد الجماعي: الخصائص المسموحة وحدها",
    ),
}

MIGRATIONS = {
    "2026_11_01_000001_create_shop_tables.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestampsTz(); // timestamptz, as Chapter 5 advised
        });

        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedInteger('price'); // piastres
            $table->unsignedInteger('stock')->default(0);
            $table->timestampsTz(); // timestamptz, as Chapter 5 advised
        });

        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->index()->constrained(); // PostgreSQL adds no index itself
            $table->string('status')->default('pending');
            $table->timestampsTz(); // timestamptz, as Chapter 5 advised
        });

        // {w_c_pivot}
        Schema::create('order_items', function (Blueprint $table) {
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('price');
            $table->primary(['order_id', 'product_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
        Schema::dropIfExists('customers');
    }
};
''',
    "2026_11_02_000001_add_sku_to_products.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// {w_c_expand}
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->string('sku')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('sku');
        });
    }
};
''',
    "2026_11_03_000001_require_product_sku.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // {w_c_backfill}
        DB::table('products')->whereNull('sku')->chunkById(500, function ($products) {
            foreach ($products as $product) {
                DB::table('products')->where('id', $product->id)
                    ->update(['sku' => sprintf('BIT-%04d', $product->id)]);
            }
        });

        // {w_c_contract}
        Schema::table('products', function (Blueprint $table) {
            $table->string('sku')->nullable(false)->unique()->change();
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropUnique(['sku']);
            $table->string('sku')->nullable()->change();
        });
    }
};
''',
}

FILES = {
    "app/Enums/OrderStatus.php": r'''<?php

namespace App\Enums;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Shipped = 'shipped';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => '{w_pending}',
            self::Paid => '{w_paid}',
            self::Shipped => '{w_shipped}',
            self::Cancelled => '{w_cancelled}',
        };
    }
}
''',
    "app/Models/Customer.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends Model
{
    protected $fillable = ['name', 'email'];

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
''',
    "app/Models/Product.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Product extends Model
{
    protected $fillable = ['name', 'price', 'stock', 'sku'];

    public function orders(): BelongsToMany
    {
        return $this->belongsToMany(Order::class, 'order_items')->withPivot('quantity', 'price');
    }
}
''',
    "app/Models/Order.php": r'''<?php

namespace App\Models;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Order extends Model
{
    protected $fillable = ['customer_id', 'status'];

    protected function casts(): array
    {
        return ['status' => OrderStatus::class]; // {w_c_cast}
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function products(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'order_items')->withPivot('quantity', 'price');
    }

    // {w_c_scope}
    #[Scope]
    protected function shipped(Builder $query): void
    {
        $query->where('status', OrderStatus::Shipped);
    }

    // The total, computed from the items: piastres, as stored.
    protected function total(): Attribute
    {
        return Attribute::get(fn () => $this->products->sum(
            fn (Product $p) => $p->pivot->quantity * $p->pivot->price,
        ));
    }
}
''',
    "app/Providers/AppServiceProvider.php": r'''<?php

namespace App\Providers;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // {w_c_strict}
        Model::preventLazyLoading(config('shop.strict'));
        Model::preventSilentlyDiscardingAttributes(config('shop.strict'));
    }
}
''',
    "config/shop.php": r'''<?php

return [
    'strict' => (bool) env('SHOP_STRICT', env('APP_ENV') !== 'production'),
];
''',
    "database/seeders/DatabaseSeeder.php": r'''<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $sara = Customer::create(['name' => '{w_sara}', 'email' => 'sara@example.com']);
        Customer::create(['name' => '{w_omar}', 'email' => 'omar@example.com']);
        Customer::create(['name' => '{w_lina}', 'email' => 'lina@example.com']);

        $products = collect([
            ['{w_kit}', 45000], ['{w_wheels}', 6000], ['{w_battery}', 12500], ['{w_cable}', 2500],
        ])->map(fn ($p, $i) => Product::create([
            'name' => $p[0], 'price' => $p[1], 'stock' => 10, 'sku' => sprintf('BIT-%04d', $i + 1),
        ]));

        // Sara gets 200 orders of 1 to 3 products, for counting queries.
        foreach (range(1, 200) as $n) {
            $order = Order::create(['customer_id' => $sara->id, 'status' => 'shipped']);
            foreach ($products->take(1 + $n % 3) as $product) {
                $order->products()->attach($product->id, ['quantity' => 1, 'price' => $product->price]);
            }
        }
    }
}
''',
    "routes/console.php": r'''<?php

use App\Models\Order;
use App\Models\Product;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

// {w_c_count}
function countQueries(callable $work): array
{
    $queries = [];
    DB::listen(function ($query) use (&$queries) {
        $queries[] = $query->sql;
    });
    $result = $work();
    DB::flushQueryLog();
    return [$result, $queries];
}

Artisan::command('shop:order {id}', function (int $id) {
    [$order, $queries] = countQueries(
        fn () => Order::with(['customer', 'products'])->findOrFail($id),
    );
    $this->line("#{$order->id} {$order->customer->name} · {$order->status->label()} · {$order->total}");
    foreach ($order->products as $product) {
        $this->line("  {$product->pivot->quantity} × {$product->name} ({$product->pivot->price})");
    }
    foreach ($queries as $sql) {
        $this->line("SQL: $sql");
    }
});

Artisan::command('shop:report {mode}', function (string $mode) {
    $start = hrtime(true);
    [$orders, $queries] = countQueries(function () use ($mode) {
        $orders = $mode === 'eager'
            ? Order::shipped()->with('products')->get() // {w_c_eager}
            : Order::shipped()->get();
        // {w_c_lazy}
        $orders->each(fn (Order $order) => $order->products->count());
        return $orders;
    });
    $ms = intdiv(hrtime(true) - $start, 1_000_000);
    $this->line(sprintf('%-5s %d {w_d_orders}, %d {w_d_queries}, %d ms', $mode, $orders->count(),
        count($queries), $ms));
});

Artisan::command('shop:mass', function () {
    $product = Product::make(['name' => 'Test', 'price' => 100, 'stock' => 1]);
    $this->line(json_encode($product->only(['name', 'price', 'stock']), JSON_UNESCAPED_UNICODE));
    Product::make(['name' => 'Test', 'price' => 100, 'id' => 1]);
});

// The answers to exercises 2 and 4.
Artisan::command('shop:answers', function () {
    $this->line('shipped: '.Order::shipped()->count());
    $units = Product::withSum('orders as units', 'order_items.quantity')->orderBy('id')->get();
    foreach ($units as $product) {
        $this->line("{$product->name}: ".($product->units ?? 0));
    }
});
''',
}


def prepare_cache():
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer update --no-install --no-scripts -q"],
                       cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    env = (shop / ".env").read_text()
    for old, new in (("DB_CONNECTION=sqlite", "DB_CONNECTION=pgsql"), ("# DB_HOST=127.0.0.1", "DB_HOST=127.0.0.1"),
                     ("# DB_PORT=3306", "DB_PORT=5432"), ("# DB_DATABASE=laravel", "DB_DATABASE=shop"),
                     ("# DB_USERNAME=root", "DB_USERNAME=bit"), ("# DB_PASSWORD=", "DB_PASSWORD=secret")):
        env = env.replace(old, new)
    (shop / ".env").write_text(env)
    for name in glob.glob(str(shop / "database/migrations/*")):
        if "0001_01_01" not in name:
            Path(name).unlink()
    for name, text in MIGRATIONS.items():
        (shop / "database/migrations" / name).write_text(fill(text, t))
    for name, text in FILES.items():
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    s.run("vendor/bin/pint --quiet app config routes database")
    s.lines.clear()

    s.note(t["w_s_db"])
    s.run("grep '^DB_' .env")
    s.save(folder / "env.sh")
    s.note(t["w_s_migrate"])
    s.run("php artisan migrate --no-ansi")
    s.save(folder / "migrate.sh")
    s.note(t["w_s_table"])
    s.run("php artisan db:table products --no-ansi")
    s.save(folder / "table.sh")
    s.note(t["w_s_rollback"])
    s.run("php artisan migrate:rollback --step=1 --no-ansi")
    s.run("php artisan migrate --no-ansi")
    s.save(folder / "rollback.sh")
    s.run("php artisan db:seed --no-ansi -q")
    s.lines.clear()
    s.note(t["w_s_order"])
    s.run("php artisan shop:order 2")
    s.save(folder / "order.sh")
    s.note(t["w_s_n1"])
    s.run("SHOP_STRICT=false php artisan shop:report lazy")
    s.run("SHOP_STRICT=false php artisan shop:report eager")
    s.save(folder / "n-plus-one.sh")
    s.note(t["w_s_strict"])
    s.run("php artisan shop:report lazy 2>&1 | grep -E 'LazyLoadingViolation|Attempted to' | head -2", check=False)
    s.save(folder / "strict.sh")
    s.note(t["w_s_mass"])
    s.run("php artisan shop:mass 2>&1 | grep -E '^\\{|MassAssignmentException|fillable property' | head -3", check=False)
    s.save(folder / "mass.sh")
    s.run("php artisan shop:answers")
    s.save(folder / "answers.sh")


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
