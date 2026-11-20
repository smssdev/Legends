"""Writes the examples of Book 3 (Laravel edition), chapter 3 "Laravel Essentials: Routes, Controllers and
Requests". Run: python3 make.py   (PHP 8.5 and Composer run in Docker through code/b3/bin)

A real Laravel 13 project per language (<lang>/shop), made with `composer create-project` and Artisan, then
given the shop's product API: routes, a controller, form requests, a service bound in the container,
middleware, rate limits and a feature test. The app is served with `php artisan serve` and curl talks to it;
what the terminal showed is saved as the transcripts the chapter prints (*.sh). vendor/ is removed at the end.
"""
import os
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
        w_p1="Robot kit", w_p2="Spare wheels", w_p3="Battery pack", w_new="USB cable",
        w_no_product="There is no product :id.",
        w_m_name_required="Give the product a name.", w_m_name_max="A name has at most :max characters.",
        w_m_price_integer="The price is a whole number of piastres.", w_m_price_min="The price must be above 0.",
        w_m_stock_min="Stock cannot be negative.", w_m_fields="Send at least one field to change.",
        w_c_contract="What the controllers need from a catalog, not how it stores products.",
        w_c_json="Products in a JSON file, as in Chapter 1. Chapter 6 moves them to a database.",
        w_c_lock="the lock makes a second request wait while the first one writes",
        w_c_bind="Ask for a ProductCatalog, get this one: built once per request cycle.",
        w_c_limit="At most N requests a minute per address; N comes from config/shop.php.",
        w_c_timing="Adds the time the app spent on the request, which browsers' developer tools show.",
        w_c_where="only numbers: /api/products/abc never reaches the controller",
        w_c_inject="the container builds the controller and passes it a catalog",
        w_c_unicode="Without the flag, Laravel writes every non-English letter as \\u0643 and so on.",
        w_c_validated="only the checked fields, nothing else the client sent",
        w_c_temp="every test gets its own empty file, so tests never share data",
        w_c_env="Read the environment here only; everywhere else, use config('shop.…').",
        w_t_list="it lists the products", w_t_create="it creates a product and says where it is",
        w_t_invalid="it refuses an invalid product with every error",
        w_s_create="A new Laravel project (Composer downloads the framework and its packages)",
        w_s_api="Add the API's routes file (and Sanctum, used in Chapter 9)",
        w_s_make="Artisan writes the empty classes, in the right folders",
        w_s_routes="Every route of the API, as Laravel sees it",
        w_s_serve="Serve the app (in its own terminal)", w_s_list="The list, and a filter",
        w_s_one="One product, then one that does not exist",
        w_s_bad_id="Not a number: the route does not even match",
        w_s_create_ok="Create a product", w_s_create_bad="Create one with every mistake at once",
        w_s_patch="Change one field, then delete", w_s_after="Gone",
        w_s_timing="Every API answer carries the middleware's header",
        w_s_debug="An unknown address while APP_DEBUG=true: look at everything it tells a stranger",
        w_s_nodebug="The same with APP_DEBUG=false, as in production",
        w_s_limit="A server limited to 3 requests a minute (SHOP_RATE_LIMIT=3)",
        w_s_config="Configuration, as the app sees it",
        w_s_pipeline="The trace, read from the bottom: the classes a request went through, in order",
        w_s_test="The feature tests send requests through the whole app, without a server",
    ),
    "ar": dict(
        w_p1="عدة الروبوت", w_p2="عجلات احتياطية", w_p3="حزمة بطارية", w_new="كابل USB",
        w_no_product="لا يوجد منتج رقمه :id.",
        w_m_name_required="أعطِ المنتج اسماً.", w_m_name_max="الاسم :max حرفاً على الأكثر.",
        w_m_price_integer="السعر عدد صحيح من القروش.", w_m_price_min="يجب أن يكون السعر أكبر من 0.",
        w_m_stock_min="لا يجوز أن يكون المخزون سالباً.", w_m_fields="أرسل حقلاً واحداً على الأقل لتغييره.",
        w_c_contract="ما تحتاجه المتحكمات من الكتالوج، لا طريقة تخزينه للمنتجات.",
        w_c_json="المنتجات في ملف JSON كما في الفصل 1، ويستبدل الفصل 6 هذا الصنف بقاعدة بيانات.",
        w_c_lock="القفل يجعل الطلب الثاني ينتظر بينما يكتب الأول",
        w_c_bind="اطلب ProductCatalog تحصل على هذا: يُبنى مرة واحدة لكل دورة طلب.",
        w_c_limit="عدد N من الطلبات في الدقيقة لكل عنوان على الأكثر، وN من config/shop.php.",
        w_c_timing="يضيف الوقت الذي أمضاه التطبيق في الطلب، وتعرضه أدوات المطور في المتصفحات.",
        w_c_where="الأرقام فقط: /api/products/abc لا يصل إلى المتحكم أبداً",
        w_c_inject="تبني الحاوية المتحكم وتمرر إليه كتالوجاً",
        w_c_unicode="بدون هذا الخيار يكتب Laravel كل حرف غير إنجليزي بالشكل \\u0643 وأمثاله.",
        w_c_validated="الحقول المفحوصة وحدها، ولا شيء آخر مما أرسله العميل",
        w_c_temp="لكل اختبار ملفه الفارغ، فلا تتشارك الاختبارات البيانات أبداً",
        w_c_env="اقرأ البيئة هنا وحدها، وفي كل مكان آخر استخدم config('shop.…').",
        w_t_list="it lists the products", w_t_create="it creates a product and says where it is",
        w_t_invalid="it refuses an invalid product with every error",
        w_s_create="مشروع Laravel جديد (ينزّل Composer الإطار وحزمه)",
        w_s_api="أضف ملف مسارات الواجهة (وSanctum، ونستخدمه في الفصل 9)",
        w_s_make="يكتب Artisan الأصناف الفارغة في مجلداتها الصحيحة",
        w_s_routes="كل مسارات الواجهة كما يراها Laravel",
        w_s_serve="شغّل التطبيق (في نافذته الخاصة)", w_s_list="القائمة، وتصفية",
        w_s_one="منتج واحد، ثم منتج غير موجود",
        w_s_bad_id="ليس رقماً: المسار لا يطابق أصلاً",
        w_s_create_ok="أنشئ منتجاً", w_s_create_bad="أنشئ منتجاً بكل الأخطاء معاً",
        w_s_patch="غيّر حقلاً واحداً، ثم احذف", w_s_after="لم يعد موجوداً",
        w_s_timing="كل جواب في الواجهة يحمل ترويسة الوسيط",
        w_s_debug="عنوان مجهول و APP_DEBUG=true: انظر إلى كل ما يخبر به غريباً",
        w_s_nodebug="الشيء نفسه مع APP_DEBUG=false، كما في الإنتاج",
        w_s_limit="خادم محدود بثلاثة طلبات في الدقيقة (SHOP_RATE_LIMIT=3)",
        w_s_config="الإعدادات كما يراها التطبيق",
        w_s_pipeline="التتبع مقروءاً من الأسفل: الأصناف التي مر بها الطلب، بالترتيب",
        w_s_test="ترسل اختبارات الميزات الطلبات عبر التطبيق كله، بلا خادم",
    ),
}

FILES = {
    "config/shop.php": '''<?php

// The shop's own settings.
// {w_c_env}
return [
    'currency' => env('SHOP_CURRENCY', 'EGP'),
    'requests_per_minute' => (int) env('SHOP_RATE_LIMIT', 60),
    'catalog_file' => storage_path('app/products.json'),
];
''',
    "app/Catalog/ProductCatalog.php": '''<?php

declare(strict_types=1);

namespace App\\Catalog;

// {w_c_contract}
interface ProductCatalog
{
    /** @return list<array{id: int, name: string, price: int, stock: int}> */
    public function all(): array;

    /** @return array{id: int, name: string, price: int, stock: int}|null */
    public function find(int $id): ?array;

    /** @param array{name: string, price: int, stock?: int} $data */
    public function create(array $data): array;

    public function update(int $id, array $data): ?array;

    public function delete(int $id): bool;
}
''',
    "app/Catalog/JsonProductCatalog.php": '''<?php

declare(strict_types=1);

namespace App\\Catalog;

// {w_c_json}
final class JsonProductCatalog implements ProductCatalog
{
    public function __construct(private readonly string $path) {}

    public function all(): array
    {
        return $this->read()['products'];
    }

    public function find(int $id): ?array
    {
        return array_find($this->all(), fn (array $p) => $p['id'] === $id);
    }

    public function create(array $data): array
    {
        return $this->change(function (array $store) use ($data) {
            $product = ['id' => $store['next_id'], 'stock' => 0, ...$data];
            $store['products'][] = $product;
            $store['next_id']++;
            return [$store, $product];
        });
    }

    public function update(int $id, array $data): ?array
    {
        return $this->change(function (array $store) use ($id, $data) {
            foreach ($store['products'] as $i => $product) {
                if ($product['id'] === $id) {
                    $store['products'][$i] = [...$product, ...$data];
                    return [$store, $store['products'][$i]];
                }
            }
            return [$store, null];
        });
    }

    public function delete(int $id): bool
    {
        return $this->change(function (array $store) use ($id) {
            $left = array_filter(
                $store['products'],
                fn (array $p) => $p['id'] !== $id,
            );
            $deleted = count($left) < count($store['products']);
            $store['products'] = array_values($left);
            return [$store, $deleted];
        });
    }

    private function read(): array
    {
        if (! is_file($this->path)) {
            return self::seed();
        }
        return json_decode((string) file_get_contents($this->path), true);
    }

    private function change(callable $edit): mixed
    {
        $file = fopen($this->path, 'c+');
        // {w_c_lock}
        flock($file, LOCK_EX);
        $text = stream_get_contents($file);
        [$store, $result] = $edit($text ? json_decode($text, true) : self::seed());
        ftruncate($file, 0);
        rewind($file);
        fwrite($file, json_encode($store, JSON_UNESCAPED_UNICODE));
        flock($file, LOCK_UN);
        fclose($file);
        return $result;
    }

    private static function seed(): array
    {
        return ['next_id' => 4, 'products' => [
            ['id' => 1, 'name' => '{w_p1}', 'price' => 45000, 'stock' => 10],
            ['id' => 2, 'name' => '{w_p2}', 'price' => 6000, 'stock' => 25],
            ['id' => 3, 'name' => '{w_p3}', 'price' => 12500, 'stock' => 0],
        ]];
    }
}
''',
    "app/Providers/AppServiceProvider.php": '''<?php

namespace App\\Providers;

use App\\Catalog\\JsonProductCatalog;
use App\\Catalog\\ProductCatalog;
use Illuminate\\Cache\\RateLimiting\\Limit;
use Illuminate\\Http\\Request;
use Illuminate\\Support\\Facades\\RateLimiter;
use Illuminate\\Support\\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // {w_c_bind}
        $this->app->singleton(
            ProductCatalog::class,
            fn () => new JsonProductCatalog(config('shop.catalog_file')),
        );
    }

    public function boot(): void
    {
        // {w_c_limit}
        RateLimiter::for('api', function (Request $request) {
            $perMinute = config('shop.requests_per_minute');
            return Limit::perMinute($perMinute)->by($request->ip());
        });
    }
}
''',
    "app/Http/Middleware/AddServerTiming.php": '''<?php

declare(strict_types=1);

namespace App\\Http\\Middleware;

use Closure;
use Illuminate\\Http\\Request;
use Symfony\\Component\\HttpFoundation\\Response;

// {w_c_timing}
final class AddServerTiming
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = hrtime(true);
        $response = $next($request); // everything after this middleware runs here
        $ms = (hrtime(true) - $start) / 1_000_000;
        $response->headers->set('Server-Timing', sprintf('app;dur=%.1f', $ms));
        return $response;
    }
}
''',
    "bootstrap/app.php": '''<?php

use App\\Http\\Middleware\\AddServerTiming;
use Illuminate\\Foundation\\Application;
use Illuminate\\Foundation\\Configuration\\Exceptions;
use Illuminate\\Foundation\\Configuration\\Middleware;
use Illuminate\\Http\\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(append: [AddServerTiming::class]);
        $middleware->throttleApi();
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );
    })->create();
''',
    "routes/api.php": '''<?php

use App\\Http\\Controllers\\ProductController;
use Illuminate\\Http\\Request;
use Illuminate\\Support\\Facades\\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::apiResource('products', ProductController::class)
    // {w_c_where}
    ->where(['product' => '[0-9]+']);
''',
    "app/Http/Requests/StoreProductRequest.php": '''<?php

declare(strict_types=1);

namespace App\\Http\\Requests;

use Illuminate\\Foundation\\Http\\FormRequest;

final class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Chapter 9 decides who may add products
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:80'],
            'price' => ['required', 'integer', 'min:1'],
            'stock' => ['sometimes', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => '{w_m_name_required}',
            'name.max' => '{w_m_name_max}',
            'price.integer' => '{w_m_price_integer}',
            'price.min' => '{w_m_price_min}',
            'stock.min' => '{w_m_stock_min}',
        ];
    }
}
''',
    "app/Http/Requests/UpdateProductRequest.php": '''<?php

declare(strict_types=1);

namespace App\\Http\\Requests;

use Illuminate\\Foundation\\Http\\FormRequest;

final class UpdateProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:80'],
            'price' => ['sometimes', 'integer', 'min:1'],
            'stock' => ['sometimes', 'integer', 'min:0'],
            'fields' => ['prohibited'],
        ];
    }

    // Runs after the rules: a body with none of the fields changes nothing.
    public function after(): array
    {
        return [
            function ($validator) {
                if ($this->safe()->collect()->isEmpty()) {
                    $message = __('{w_m_fields}');
                    $validator->errors()->add('fields', $message);
                }
            },
        ];
    }

    public function messages(): array
    {
        return (new StoreProductRequest)->messages();
    }
}
''',
    "app/Http/Controllers/ProductController.php": '''<?php

declare(strict_types=1);

namespace App\\Http\\Controllers;

use App\\Catalog\\ProductCatalog;
use App\\Http\\Requests\\StoreProductRequest;
use App\\Http\\Requests\\UpdateProductRequest;
use Illuminate\\Http\\JsonResponse;
use Illuminate\\Http\\Request;
use Illuminate\\Http\\Response;

final class ProductController extends Controller
{
    // {w_c_inject}
    public function __construct(private readonly ProductCatalog $catalog) {}

    public function index(Request $request): JsonResponse
    {
        $max = $request->integer('max_price', PHP_INT_MAX);
        $products = array_filter(
            $this->catalog->all(),
            fn (array $p) => $p['price'] <= $max,
        );
        return $this->json(['data' => array_values($products)]);
    }

    public function show(int $product): JsonResponse
    {
        return $this->json(['data' => $this->findOrFail($product)]);
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        // {w_c_validated}
        $product = $this->catalog->create($request->validated());
        return $this
            ->json(['data' => $product], 201)
            ->header('Location', route('products.show', $product['id']));
    }

    public function update(UpdateProductRequest $request, int $product): JsonResponse
    {
        $this->findOrFail($product);
        $changed = $this->catalog->update($product, $request->validated());
        return $this->json(['data' => $changed]);
    }

    public function destroy(int $product): Response
    {
        $this->findOrFail($product);
        $this->catalog->delete($product);
        return response()->noContent();
    }

    // {w_c_unicode}
    private function json(array $data, int $status = 200): JsonResponse
    {
        return response()->json($data, $status, [], JSON_UNESCAPED_UNICODE);
    }

    private function findOrFail(int $id): array
    {
        $product = $this->catalog->find($id);
        if ($product === null) {
            abort(404, __('{w_no_product}', ['id' => $id]));
        }
        return $product;
    }
}
''',
    "tests/Feature/ProductApiTest.php": '''<?php

namespace Tests\\Feature;

use App\\Catalog\\JsonProductCatalog;
use App\\Catalog\\ProductCatalog;
use Tests\\TestCase;

class ProductApiTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // {w_c_temp}
        $file = tempnam(sys_get_temp_dir(), 'catalog');
        unlink($file);
        $this->app->instance(ProductCatalog::class, new JsonProductCatalog($file));
    }

    public function test_{w_t_list_fn}(): void
    {
        $this->getJson('/api/products')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.price', 45000);
    }

    public function test_{w_t_create_fn}(): void
    {
        $this->postJson('/api/products', ['name' => '{w_new}', 'price' => 2500])
            ->assertCreated()
            ->assertHeader('Location', url('/api/products/4'))
            ->assertJsonPath('data.stock', 0);

        $this->getJson('/api/products/4')->assertOk();
    }

    public function test_{w_t_invalid_fn}(): void
    {
        $this->postJson('/api/products', ['price' => 0, 'stock' => -1])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'price', 'stock']);
    }
}
''',
}


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    base = "localhost:8000"

    s.note(t["w_s_api"])
    s.run("php artisan install:api --no-interaction --no-ansi 2>&1 | grep -E 'INFO|tokens_table'")
    s.save(folder / "install-api.sh")

    s.note(t["w_s_make"])
    for cmd in ("make:controller ProductController --api", "make:request StoreProductRequest",
                "make:request UpdateProductRequest", "make:middleware AddServerTiming"):
        s.run(f"php artisan {cmd} --no-ansi")
    s.save(folder / "make.sh")

    for name, text in FILES.items():
        words = dict(t, **{f"{k}_fn": t[k].replace(" ", "_") for k in ("w_t_list", "w_t_create", "w_t_invalid")})
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, words))
    s.run("vendor/bin/pint --quiet app bootstrap config routes tests")
    s.lines.clear()

    s.note(t["w_s_routes"])
    s.run("php artisan route:list --path=api --except-vendor --json | jq -r -f ../routes.jq")
    s.save(folder / "routes.sh")

    s.note(t["w_s_config"])
    s.run("php artisan config:show shop --no-ansi")
    s.save(folder / "config.sh")

    with Server("php artisan serve --no-ansi", shop, f"http://{base}/up") as server:
        s.note(t["w_s_list"])
        s.run(f"curl -s {base}/api/products | jq -c '.data[]'")
        s.run(f"curl -s '{base}/api/products?max_price=10000' | jq -c '.data[] | [.id, .price]'")
        s.note(t["w_s_one"])
        s.run(f"curl -s {base}/api/products/1")
        s.run(f"curl -s {base}/api/products/9 | jq -c '{{message, exception}}'")
        s.save(folder / "read.sh")

        s.note(t["w_s_create_ok"])
        body = '{"name": "%s", "price": 2500}' % t["w_new"]
        s.run(f"curl -si {base}/api/products -H 'Accept: application/json' "
              f"-H 'Content-Type: application/json' -d '{body}' | grep -iE '^(HTTP|location)|^\\{{'")
        s.note(t["w_s_create_bad"])
        s.run(f"curl -s {base}/api/products -H 'Accept: application/json' "
              "-H 'Content-Type: application/json' -d '{\"price\": 9.5, \"stock\": -1}' | jq")
        s.save(folder / "store.sh")

        s.note(t["w_s_patch"])
        s.run(f"curl -s -X PATCH {base}/api/products/4 -H 'Accept: application/json' "
              "-H 'Content-Type: application/json' -d '{\"stock\": 40}'")
        s.run(f"curl -s -X PATCH {base}/api/products/4 -H 'Accept: application/json' "
              "-H 'Content-Type: application/json' -d '{}'")
        s.run(f"curl -s -X DELETE {base}/api/products/4 -w '%{{http_code}}\\n'")
        s.note(t["w_s_after"])
        s.run(f"curl -s {base}/api/products/4 | jq -c '{{message}}'")
        s.save(folder / "change.sh")

        s.note(t["w_s_bad_id"])
        s.run(f"curl -s {base}/api/products/abc | jq -c '{{message, exception}}'")
        s.save(folder / "bad-id.sh")

        s.note(t["w_s_timing"])
        s.run(f"curl -si {base}/api/products/1 | grep -iE '^(server-timing|x-ratelimit)'")
        s.save(folder / "timing.sh")

        s.note(t["w_s_debug"])
        s.run(f"curl -s {base}/api/nothing | jq '{{message, exception, file, line, trace: (.trace | length)}}'")
        s.save(folder / "debug.sh")
        s.note(t["w_s_pipeline"])
        s.run(f"curl -s {base}/api/products/9 | jq -r -f ../pipeline.jq")
        s.save(folder / "pipeline.sh")
        log = server.log()
    s.note(t["w_s_serve"])
    s.lines.append("$ php artisan serve")
    s.add("\n".join(l for l in log.split("\n") if l.strip())[:2000])
    s.save(folder / "serve.sh")

    subprocess.run(["bash", "-c", "php artisan cache:clear -q"], cwd=shop, env=CLEAN, check=True)
    env_file = shop / ".env"
    env_file.write_text(env_file.read_text().replace("APP_DEBUG=true", "APP_DEBUG=false")
                        + "SHOP_RATE_LIMIT=3\n")
    with Server("php artisan serve --no-ansi", shop, f"http://{base}/up"):
        s.note(t["w_s_nodebug"])
        s.run(f"curl -s {base}/api/nothing")
        s.save(folder / "nodebug.sh")
        s.note(t["w_s_limit"])
        s.run(f"for i in 1 2 3; do curl -s -o /dev/null -w '%{{http_code}} ' {base}/api/products; done; echo")
        s.run(f"curl -s -D - -o /dev/null {base}/api/products | grep -iE '^(HTTP|x-ratelimit|retry-after)'")
        s.run(f"curl -s {base}/api/products")
        s.save(folder / "rate-limit.sh")

    s.note(t["w_s_test"])
    s.run("php artisan test --no-ansi tests/Feature/ProductApiTest.php")
    s.save(folder / "test.sh")


ANSWERS = {
    "routes/api.php": ("""Route::apiResource('products', ProductController::class)""",
                       """Route::get('products/{product}/stock', [ProductController::class, 'stock'])
    ->whereNumber('product')
    ->name('products.stock');

Route::apiResource('products', ProductController::class)"""),
    "app/Http/Controllers/ProductController.php": [
        ("""        $max = $request->integer('max_price', PHP_INT_MAX);
        $products = array_filter(
            $this->catalog->all(),
            fn (array $p) => $p['price'] <= $max,
        );""",
         """        $request->validate([
            'min_price' => ['sometimes', 'integer', 'min:0'],
            'max_price' => [
                'sometimes', 'integer', 'min:0',
                Rule::when($request->has('min_price'), 'gte:min_price'),
            ],
        ]);
        $min = $request->integer('min_price', 0);
        $max = $request->integer('max_price', PHP_INT_MAX);
        $products = array_filter(
            $this->catalog->all(),
            fn (array $p) => $p['price'] >= $min && $p['price'] <= $max,
        );"""),
        ("""    private function findOrFail(int $id): array""",
         """    public function stock(int $product): JsonResponse
    {
        $found = $this->findOrFail($product);
        return $this->json(['data' => [
            'id' => $found['id'],
            'stock' => $found['stock'],
            'in_stock' => $found['stock'] > 0,
        ]]);
    }

    private function findOrFail(int $id): array"""),
        ("""use Illuminate\\Http\\Response;""", """use Illuminate\\Http\\Response;
use Illuminate\\Validation\\Rule;"""),
    ],
    "bootstrap/app.php": ("""        $middleware->api(append: [AddServerTiming::class]);""",
                          """        $middleware->api(prepend: [RequireJson::class], append: [AddServerTiming::class]);"""),
    "bootstrap/app.php#2": ("""use App\\Http\\Middleware\\AddServerTiming;""",
                            """use App\\Http\\Middleware\\AddServerTiming;
use App\\Http\\Middleware\\RequireJson;"""),
}

ANSWER_NEW = {
    "app/Http/Middleware/RequireJson.php": """<?php

declare(strict_types=1);

namespace App\\Http\\Middleware;

use Closure;
use Illuminate\\Http\\Request;
use Symfony\\Component\\HttpFoundation\\Response;

// An API speaks JSON both ways: answers are always JSON, bodies must be.
final class RequireJson
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');
        $sendsBody = in_array($request->method(), ['POST', 'PUT', 'PATCH'], true);
        abort_if($sendsBody && ! $request->isJson(), 415, 'Send JSON.');
        return $next($request);
    }
}
""",
    "tests/Fakes/ArrayProductCatalog.php": """<?php

declare(strict_types=1);

namespace Tests\\Fakes;

use App\\Catalog\\ProductCatalog;

// The same contract as the real catalog, kept in memory: fast, and nothing to clean up.
final class ArrayProductCatalog implements ProductCatalog
{
    public function __construct(private array $products = []) {}

    public function all(): array
    {
        return $this->products;
    }

    public function find(int $id): ?array
    {
        return array_find($this->products, fn (array $p) => $p['id'] === $id);
    }

    public function create(array $data): array
    {
        $product = ['id' => count($this->products) + 1, 'stock' => 0, ...$data];
        $this->products[] = $product;
        return $product;
    }

    public function update(int $id, array $data): ?array
    {
        foreach ($this->products as $i => $product) {
            if ($product['id'] === $id) {
                return $this->products[$i] = [...$product, ...$data];
            }
        }
        return null;
    }

    public function delete(int $id): bool
    {
        $before = count($this->products);
        $this->products = array_values(array_filter($this->products, fn ($p) => $p['id'] !== $id));
        return count($this->products) < $before;
    }
}
""",
    "tests/Feature/AnswersTest.php": """<?php

namespace Tests\\Feature;

use App\\Catalog\\ProductCatalog;
use Tests\\Fakes\\ArrayProductCatalog;
use Tests\\TestCase;

class AnswersTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->app->instance(ProductCatalog::class, new ArrayProductCatalog([
            ['id' => 1, 'name' => 'Kit', 'price' => 45000, 'stock' => 10],
            ['id' => 2, 'name' => 'Wheels', 'price' => 6000, 'stock' => 0],
        ]));
    }

    public function test_exercise_2_stock(): void
    {
        $this->getJson('/api/products/2/stock')
            ->assertOk()
            ->assertExactJson(['data' => ['id' => 2, 'stock' => 0, 'in_stock' => false]]);
    }

    public function test_exercise_3_price_range(): void
    {
        $this->getJson('/api/products?min_price=5000&max_price=10000')->assertJsonCount(1, 'data');
        $this->getJson('/api/products?max_price=7000')->assertJsonCount(1, 'data');
        $this->getJson('/api/products?min_price=9000&max_price=100')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['max_price']);
    }

    public function test_exercise_4_the_fake_is_used(): void
    {
        $this->getJson('/api/products')->assertJsonPath('data.0.name', 'Kit');
    }

    public function test_exercise_5_json_only(): void
    {
        $this->post('/api/products', ['name' => 'Form', 'price' => 100])->assertStatus(415);
        $this->call('POST', '/api/products', [], [], [], ['CONTENT_TYPE' => 'application/json'], '{}')
            ->assertUnprocessable()
            ->assertHeader('Content-Type', 'application/json');
    }
}
""",
}


def answers(shop):
    """The exercises' answers, applied to a copy of the project and tested there; only the changed files
    are kept, in answers/."""
    folder = shop.parent
    copy = folder / "answers-shop"
    if copy.exists():
        shutil.rmtree(copy)
    shutil.copytree(shop, copy, symlinks=True)
    changed = set()
    for name, patches in ANSWERS.items():
        name = name.split("#")[0]
        path = copy / name
        text = path.read_text()
        for old, new in (patches if isinstance(patches, list) else [patches]):
            assert old in text, (name, old)
            text = text.replace(old, new)
        path.write_text(text)
        changed.add(name)
    for name, text in ANSWER_NEW.items():
        (copy / name).parent.mkdir(parents=True, exist_ok=True)
        (copy / name).write_text(text)
        changed.add(name)
    s = Session(copy)
    s.run("php artisan test --no-ansi tests/Feature/AnswersTest.php tests/Feature/ProductApiTest.php")
    s.save(folder / "answers.sh")
    for name in sorted(changed):
        target = folder / "answers" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(copy / name, target)
    shutil.rmtree(copy)


def prepare_cache():
    """Puts the skeleton's packages, and Sanctum, in Composer's cache (see php/seed.py)."""
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        # Resolve the versions with PHP 8.5, as the real install will; only metadata is downloaded.
        subprocess.run(["bash", "-c", "composer update --no-install --no-scripts -q"], cwd=f"{tmp}/skeleton",
                       env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")
    seed_latest("laravel/sanctum")


prepare_cache()
for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    s = Session(folder)
    s.note(t["w_s_create"])
    s.run("composer create-project laravel/laravel shop --no-interaction --no-ansi 2>&1 "
          "| grep -E 'Creating a|^Installing laravel|laravel/framework|Package operations|key set|Running mig'")
    s.run("cd shop && php artisan --version")
    s.save(folder / "create.sh")
    shop = folder / "shop"
    # Middleware and controllers from a debug trace, outermost first, each once.
    (folder / "pipeline.jq").write_text(
        '[.trace[].class // empty | select(test("Middleware|Controller"))]\n'
        '| reverse\n'
        '| reduce .[] as $c ([]; if index([$c]) then . else . + [$c] end)\n'
        '| .[]\n')
    # The route list as a table that fits the page.
    (folder / "routes.jq").write_text(
        '.[] | (.method | . + " " * (10 - length)) + " "\n'
        '    + (.uri | . + " " * (24 - length)) + " "\n'
        '    + (.action | ltrimstr("App\\\\Http\\\\Controllers\\\\"))\n')
    record(shop, t)
    answers(shop)
    # Files the book does not need: the framework's own notes for AI assistants and CI, and caches.
    for junk in ("AGENTS.md", "CLAUDE.md", "CHANGELOG.md", ".github", ".styleci.yml", ".phpunit.result.cache",
                 "vendor", "storage/logs/laravel.log", "storage/app/products.json", "database/database.sqlite",
                 ".env", "storage/framework/cache/data", "storage/framework/sessions", "storage/framework/views"):
        path = shop / junk
        if path.is_dir():
            shutil.rmtree(path)
            if junk.startswith(("vendor", "storage")):
                path.mkdir()
        elif path.exists():
            path.unlink()
    print("wrote", lang)
