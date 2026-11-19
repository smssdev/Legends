"""Writes the examples of Book 3 (Laravel edition), chapter 4 "Designing REST APIs with API Resources".
Run: python3 make.py   (PHP 8.5 and Composer run in Docker through code/b3/bin)

A fresh Laravel 13 project per language (<lang>/shop) with the shop's API, version 1: products and orders in
SQLite through Eloquent, API Resources, cursor pagination, Problem Details, an idempotency middleware,
ETag and If-Match, and OpenAPI documentation from Scramble. Served with `php artisan serve`, called with
curl; what the terminal showed is saved as the transcripts the chapter prints (*.sh).
"""
import glob
import re
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

NAMES = {
    "en": ["Robot kit", "Spare wheels", "Battery pack", "USB cable", "Servo motor", "Sensor set",
           "Remote control", "Solar panel", "Gear box", "LED strip", "Speaker", "Camera module"],
    "ar": ["عدة الروبوت", "عجلات احتياطية", "حزمة بطارية", "كابل USB", "محرك سيرفو", "طقم حساسات",
           "جهاز تحكم", "لوح شمسي", "صندوق تروس", "شريط LED", "سماعة", "وحدة كاميرا"],
}

T = {
    "en": dict(
        w_locale="en",
        w_p_invalid="Invalid request", w_p_not_found="Not found", w_p_no_product="There is no product :id.",
        w_p_no_order="There is no order :id.", w_p_nothing="Nothing here.",
        w_p_precondition="Precondition required", w_p_need_if_match="Send If-Match with the ETag you last read.",
        w_p_stale="The product has changed", w_p_stale_detail="Someone changed it after you read it. Read it again.",
        w_p_key="Idempotency-Key is required: 8 to 100 characters.",
        w_p_reused="Idempotency key reused", w_p_reused_detail="This key was used with a different body.",
        w_p_in_progress="Request in progress", w_p_in_progress_detail="A request with this key is still running.",
        w_p_stock="Not enough stock", w_p_stock_detail="Only :stock left of product :id.",
        w_p_state="Order cannot be cancelled", w_p_state_detail="Order :id is already :status.",
        w_p_limit="Too many requests", w_p_server="Server error",
        w_m_items="An order needs 1 to 20 items.", w_m_product="There is no product :input.",
        w_m_quantity="A quantity is a whole number from 1 to 99.", w_m_price="The price must be above 0.",
        w_m_stock="Stock cannot be negative.", w_m_fields="Send at least one field to change.",
        w_m_limit="A page has 1 to 50 items.", w_m_sort="Sort by id, price, -price or name.",
        w_c_index="the list is sorted by price, then id: the index serves both",
        w_c_hidden="version is internal: the client sees it only as the ETag",
        w_c_tiebreak="a complete order: the same price is decided by id",
        w_c_atomic="one statement: change it only if the version is the one the client read",
        w_c_stock="take stock only if there is enough: two orders never get the last one",
        w_c_rollback="anything thrown here undoes the whole transaction, stock included",
        w_c_server_price="the price comes from the database, never from the client",
        w_c_lock="one request per key at a time",
        w_c_remember="kept a day; a failed request is not kept, so it may be retried",
        w_c_unicode="Arabic stays Arabic in every JSON answer, not \\u0643",
        w_c_api_only="the web pages keep Laravel's usual error pages",
        w_t_pages="it walks every page without repeats or gaps", w_t_sorted="it sorts by price, highest first",
        w_t_replay="it replays an order instead of creating it twice", w_t_stale="it refuses a stale update",
        w_t_invalid="it answers 422 problems with every invalid field",
        w_s_make="Artisan writes the model, its migration, factory and seeder, and a resource",
        w_s_migrate="Create the tables and fill them",
        w_s_docs="Scramble reads the routes, requests and resources, and writes OpenAPI",
        w_s_routes="The API's paths, from the generated document",
        w_s_first="The first page: data, links and meta", w_s_next="The next page: follow next_cursor",
        w_s_filter="Filter and sort: the cursor remembers both",
        w_s_bad="Values outside the rules", w_s_missing="A product that does not exist",
        w_s_read="Read a product: the ETag is its version", w_s_no_match="Change it without If-Match",
        w_s_ok="Change it with the ETag just read", w_s_stale="Someone else, still holding the old ETag",
        w_s_order="Create an order, with an idempotency key",
        w_s_again="The network failed, so the client sends exactly the same request again",
        w_s_other="The same key with a different body", w_s_stock_once="The stock went down once",
        w_s_too_many="More than the stock", w_s_cancel="Cancel, then cancel again",
        w_s_test="Feature tests with a fresh database for every test",
    ),
    "ar": dict(
        w_locale="ar",
        w_p_invalid="طلب غير صالح", w_p_not_found="غير موجود", w_p_no_product="لا يوجد منتج رقمه :id.",
        w_p_no_order="لا يوجد طلب رقمه :id.", w_p_nothing="لا شيء هنا.",
        w_p_precondition="شرط مسبق مطلوب", w_p_need_if_match="أرسل If-Match مع آخر ETag قرأته.",
        w_p_stale="تغيّر المنتج", w_p_stale_detail="غيّره أحد بعد أن قرأته. اقرأه من جديد.",
        w_p_key="الترويسة Idempotency-Key مطلوبة: من 8 إلى 100 حرف.",
        w_p_reused="مفتاح عدم التكرار مستخدم", w_p_reused_detail="استُخدم هذا المفتاح مع محتوى مختلف.",
        w_p_in_progress="الطلب قيد التنفيذ", w_p_in_progress_detail="ما زال طلب بهذا المفتاح يعمل.",
        w_p_stock="المخزون لا يكفي", w_p_stock_detail="بقي :stock فقط من المنتج :id.",
        w_p_state="لا يمكن إلغاء الطلب", w_p_state_detail="الطلب :id حالته :status من قبل.",
        w_p_limit="طلبات كثيرة جداً", w_p_server="خطأ في الخادم",
        w_m_items="يحتاج الطلب من 1 إلى 20 عنصراً.", w_m_product="لا يوجد منتج رقمه :input.",
        w_m_quantity="الكمية عدد صحيح من 1 إلى 99.", w_m_price="يجب أن يكون السعر أكبر من 0.",
        w_m_stock="لا يجوز أن يكون المخزون سالباً.", w_m_fields="أرسل حقلاً واحداً على الأقل لتغييره.",
        w_m_limit="الصفحة من 1 إلى 50 عنصراً.", w_m_sort="رتّب بـ id أو price أو -price أو name.",
        w_c_index="القائمة مرتبة بالسعر ثم بالرقم: والفهرس يخدم الاثنين",
        w_c_hidden="version داخلي: لا يراه العميل إلا وسماً ETag",
        w_c_tiebreak="ترتيب كامل: السعر المتساوي يحسمه الرقم",
        w_c_atomic="جملة واحدة: غيّره فقط إن كان الإصدار ما زال الذي قرأه العميل",
        w_c_stock="خذ من المخزون فقط إن كان يكفي: لا يأخذ طلبان آخر قطعة معاً",
        w_c_rollback="أي شيء يُرمى هنا يتراجع عن المعاملة كلها، والمخزون معها",
        w_c_server_price="السعر من قاعدة البيانات، لا من العميل أبداً",
        w_c_lock="طلب واحد لكل مفتاح في كل لحظة",
        w_c_remember="يُحفظ يوماً، والطلب الفاشل لا يُحفظ، فيجوز تكراره",
        w_c_unicode="تبقى العربية عربية في كل جواب JSON، لا \\u0643",
        w_c_api_only="صفحات الويب تحتفظ بصفحات الخطأ المعتادة في Laravel",
        w_t_pages="it walks every page without repeats or gaps", w_t_sorted="it sorts by price, highest first",
        w_t_replay="it replays an order instead of creating it twice", w_t_stale="it refuses a stale update",
        w_t_invalid="it answers 422 problems with every invalid field",
        w_s_make="يكتب Artisan النموذج وترحيله ومصنعه وبذرته، ومورداً",
        w_s_migrate="أنشئ الجداول واملأها",
        w_s_docs="يقرأ Scramble المسارات والطلبات والموارد، ويكتب OpenAPI",
        w_s_routes="مسارات الواجهة، من الوثيقة المولَّدة",
        w_s_first="الصفحة الأولى: data وlinks وmeta", w_s_next="الصفحة التالية: اتبع next_cursor",
        w_s_filter="التصفية والترتيب: المؤشر يتذكر الاثنين",
        w_s_bad="قيم خارج القواعد", w_s_missing="منتج غير موجود",
        w_s_read="اقرأ منتجاً: الوسم ETag هو إصداره", w_s_no_match="غيّره دون If-Match",
        w_s_ok="غيّره مع الوسم الذي قرأته للتو", w_s_stale="شخص آخر ما زال يحمل الوسم القديم",
        w_s_order="أنشئ طلباً، مع مفتاح عدم التكرار",
        w_s_again="فشلت الشبكة، فأرسل العميل الطلب نفسه بالضبط مرة أخرى",
        w_s_other="المفتاح نفسه مع محتوى مختلف", w_s_stock_once="نقص المخزون مرة واحدة",
        w_s_too_many="أكثر من المخزون", w_s_cancel="ألغِ، ثم ألغِ مرة أخرى",
        w_s_test="اختبارات الميزات بقاعدة بيانات جديدة لكل اختبار",
    ),
}

FILES = {
    "migrations/products": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name', 80);
            $table->unsignedInteger('price'); // piastres
            $table->unsignedInteger('stock')->default(0);
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
            // {w_c_index}
            $table->index(['price', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
''',
    "migrations/orders": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('status')->default('pending');
            $table->unsignedInteger('total');
            $table->timestamps();
        });
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('price');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
    }
};
''',
    "app/Models/Product.php": r'''<?php

namespace App\Models;

use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    /** @use HasFactory<ProductFactory> */
    use HasFactory;

    protected $fillable = ['name', 'price', 'stock'];
}
''',
    "app/Models/Order.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    protected $fillable = ['status', 'total'];

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
''',
    "app/Models/OrderItem.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    public $timestamps = false;

    protected $fillable = ['product_id', 'quantity', 'price'];
}
''',
    "database/factories/ProductFactory.php": r'''<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Product>
 */
class ProductFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->words(2, true),
            'price' => fake()->numberBetween(100, 50000),
            'stock' => fake()->numberBetween(0, 20),
        ];
    }
}
''',
    "database/seeders/ProductSeeder.php": r'''<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $names = [
{w_names}
        ];
        $prices = [
            45000, 6000, 12500, 2500, 9000, 15000, 8000, 30000, 11000, 4000, 7500, 21000,
        ];
        $start = Carbon::parse('2026-11-01 09:00:00', 'UTC');
        foreach ($names as $i => $name) {
            $product = new Product(['name' => $name, 'price' => $prices[$i]]);
            $product->stock = 10;
            $product->created_at = $start->copy()->addHours($i);
            $product->updated_at = $product->created_at;
            $product->save();
        }
    }
}
''',
    "database/seeders/DatabaseSeeder.php": r'''<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(ProductSeeder::class);
    }
}
''',
    "app/Http/Resources/ProductResource.php": r'''<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Product */
class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // {w_c_hidden}
        return [
            'id' => $this->id,
            'name' => $this->name,
            'price' => Money::of($this->price),
            'stock' => $this->stock,
            'created_at' => $this->created_at->toIso8601ZuluString(),
        ];
    }
}
''',
    "app/Http/Resources/Money.php": r'''<?php

namespace App\Http\Resources;

final class Money
{
    /** @return array{amount: int, currency: string} */
    public static function of(int $amount): array
    {
        return ['amount' => $amount, 'currency' => config('shop.currency')];
    }
}
''',
    "app/Http/Resources/OrderResource.php": r'''<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Order */
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'items' => $this->items->map(fn ($item) => [
                'product_id' => $item->product_id,
                'quantity' => $item->quantity,
                'price' => Money::of($item->price),
            ]),
            'total' => Money::of($this->total),
            'created_at' => $this->created_at->toIso8601ZuluString(),
        ];
    }
}
''',
    "config/shop.php": r'''<?php

return [
    'currency' => env('SHOP_CURRENCY', 'EGP'),
];
''',
    "app/Http/Problem.php": r'''<?php

declare(strict_types=1);

namespace App\Http;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

// An error in the Problem Details format (RFC 9457).
// Throw it from anywhere; bootstrap/app.php renders it.
final class Problem extends HttpException
{
    public function __construct(
        int $status,
        public readonly string $slug,
        public readonly string $title,
        public readonly ?string $detail = null,
        public readonly array $extra = [],
        array $headers = [],
    ) {
        parent::__construct($status, $detail ?? $title, null, $headers);
    }

    public function render(Request $request): JsonResponse
    {
        $body = [
            'type' => "https://bit-shop.example/problems/{$this->slug}",
            'title' => $this->title,
            'status' => $this->getStatusCode(),
            'detail' => $this->detail,
            'instance' => $request->getRequestUri(),
            ...$this->extra,
        ];
        $body = array_filter($body, fn ($value) => $value !== null);
        $headers = ['Content-Type' => 'application/problem+json', ...$this->getHeaders()];
        $flags = JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;
        return response()->json($body, $this->getStatusCode(), $headers, $flags);
    }
}
''',
    "app/Http/Problems.php": r'''<?php

declare(strict_types=1);

namespace App\Http;

use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

// Every problem the API can return, and how other exceptions become one.
final class Problems
{
    public static function from(Throwable $e): Problem
    {
        return match (true) {
            $e instanceof Problem => $e,
            $e instanceof ValidationException => new Problem(422, 'invalid-request',
                __('problems.invalid'), null, ['errors' => self::errors($e)]),
            $e instanceof NotFoundHttpException => self::notFound($e->getPrevious()),
            $e instanceof ThrottleRequestsException => new Problem(
                429, 'too-many-requests', __('problems.limit'), null, [], $e->getHeaders()),
            $e instanceof HttpExceptionInterface => new Problem(
                $e->getStatusCode(), 'http-error', $e->getMessage() ?: __('problems.server')),
            default => new Problem(500, 'server-error', __('problems.server')),
        };
    }

    public static function needIfMatch(): Problem
    {
        return new Problem(428, 'precondition-required', __('problems.precondition'),
            __('problems.need_if_match'));
    }

    public static function stale(): Problem
    {
        return new Problem(412, 'stale', __('problems.stale'),
            __('problems.stale_detail'));
    }

    public static function outOfStock(int $id, int $stock): Problem
    {
        return new Problem(409, 'out-of-stock', __('problems.stock'),
            __('problems.stock_detail', ['id' => $id, 'stock' => $stock]));
    }

    public static function cannotCancel(int $id, string $status): Problem
    {
        return new Problem(409, 'invalid-state', __('problems.state'),
            __('problems.state_detail', ['id' => $id, 'status' => $status]));
    }

    private static function notFound(?Throwable $previous): Problem
    {
        $detail = __('problems.nothing');
        if ($previous instanceof ModelNotFoundException) {
            $key = 'problems.no_'.strtolower(class_basename($previous->getModel()));
            $detail = __($key, ['id' => implode(', ', $previous->getIds())]);
        }
        return new Problem(404, 'not-found', __('problems.not_found'), $detail);
    }

    /** @return list<array{field: string, message: string}> */
    private static function errors(ValidationException $e): array
    {
        $list = [];
        foreach ($e->errors() as $field => $messages) {
            foreach ($messages as $message) {
                $list[] = ['field' => $field, 'message' => $message];
            }
        }
        return $list;
    }
}
''',
    "lang/{w_locale}/problems.php": r'''<?php

// The texts of the API's problems.
// __('problems.stale') reads them in the app's language.
return [
    'invalid' => '{w_p_invalid}',
    'not_found' => '{w_p_not_found}',
    'no_product' => '{w_p_no_product}',
    'no_order' => '{w_p_no_order}',
    'nothing' => '{w_p_nothing}',
    'precondition' => '{w_p_precondition}',
    'need_if_match' => '{w_p_need_if_match}',
    'stale' => '{w_p_stale}',
    'stale_detail' => '{w_p_stale_detail}',
    'key' => '{w_p_key}',
    'reused' => '{w_p_reused}',
    'reused_detail' => '{w_p_reused_detail}',
    'in_progress' => '{w_p_in_progress}',
    'in_progress_detail' => '{w_p_in_progress_detail}',
    'stock' => '{w_p_stock}',
    'stock_detail' => '{w_p_stock_detail}',
    'state' => '{w_p_state}',
    'state_detail' => '{w_p_state_detail}',
    'limit' => '{w_p_limit}',
    'server' => '{w_p_server}',
];
''',
    "bootstrap/app.php": r'''<?php

use App\Http\Middleware\UnescapedJson;
use App\Http\Problems;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(append: [UnescapedJson::class]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Every error in the API becomes Problem Details;
        // {w_c_api_only}.
        $exceptions->render(function (Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                return Problems::from($e)->render($request);
            }
        });
    })->create();
''',
    "app/Http/Middleware/UnescapedJson.php": r'''<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// {w_c_unicode}
final class UnescapedJson
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        if ($response instanceof JsonResponse) {
            $options = $response->getEncodingOptions();
            $options |= JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;
            $response->setEncodingOptions($options);
        }
        return $response;
    }
}
''',
    "app/Http/Middleware/Idempotent.php": r'''<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Http\Problem;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

// Safe retries: the same Idempotency-Key gets the same answer; the work is done once.
final class Idempotent
{
    public function handle(Request $request, Closure $next): Response
    {
        $key = (string) $request->header('Idempotency-Key');
        if (strlen($key) < 8 || strlen($key) > 100) {
            throw new Problem(400, 'invalid-request', __('problems.invalid'),
                __('problems.key'));
        }
        $id = 'idempotency:'.$key;
        $fingerprint = hash('sha256', $request->getContent());

        $lock = Cache::lock($id.':lock', 30); // {w_c_lock}
        if (! $lock->get()) {
            throw new Problem(409, 'in-progress', __('problems.in_progress'),
                __('problems.in_progress_detail'));
        }
        try {
            $saved = Cache::get($id);
            if ($saved !== null) {
                if ($saved['fingerprint'] !== $fingerprint) {
                    throw new Problem(422, 'idempotency-key-reused',
                        __('problems.reused'), __('problems.reused_detail'));
                }
                $headers = array_filter($saved['headers']);
                $headers['Idempotent-Replayed'] = 'true';
                return response($saved['body'], $saved['status'], $headers);
            }
            $response = $next($request);
            if ($response->isSuccessful()) {
                // {w_c_remember}
                Cache::put($id, [
                    'fingerprint' => $fingerprint,
                    'status' => $response->getStatusCode(),
                    'body' => $response->getContent(),
                    'headers' => [
                        'Content-Type' => $response->headers->get('Content-Type'),
                        'Location' => $response->headers->get('Location'),
                    ],
                ], now()->addDay());
            }
            return $response;
        } finally {
            $lock->release();
        }
    }
}
''',
    "app/Http/Requests/ListProductsRequest.php": r'''<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ListProductsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'limit' => ['sometimes', 'integer', 'between:1,50'],
            'sort' => ['sometimes', 'in:id,price,-price,name'],
            'min_price' => ['sometimes', 'integer', 'min:0'],
            'max_price' => ['sometimes', 'integer', 'min:0'],
            'cursor' => ['sometimes', 'string'],
        ];
    }

    public function messages(): array
    {
        return [
            'limit.*' => '{w_m_limit}',
            'sort.in' => '{w_m_sort}',
        ];
    }
}
''',
    "app/Http/Requests/UpdateProductRequest.php": r'''<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProductRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:80'],
            'price' => ['sometimes', 'integer', 'min:1'],
            'stock' => ['sometimes', 'integer', 'min:0'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if ($this->safe()->collect()->isEmpty()) {
                $message = '{w_m_fields}';
                $validator->errors()->add('fields', $message);
            }
        }];
    }

    public function messages(): array
    {
        return [
            'price.*' => '{w_m_price}',
            'stock.*' => '{w_m_stock}',
        ];
    }
}
''',
    "app/Http/Requests/StoreOrderRequest.php": r'''<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'items' => ['required', 'array', 'between:1,20'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'between:1,99'],
        ];
    }

    public function messages(): array
    {
        return [
            'items.*' => '{w_m_items}',
            'items.*.product_id.*' => '{w_m_product}',
            'items.*.quantity.*' => '{w_m_quantity}',
        ];
    }
}
''',
    "app/Http/Controllers/ProductController.php": r'''<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Problems;
use App\Http\Requests\ListProductsRequest;
use App\Http\Requests\UpdateProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

final class ProductController extends Controller
{
    public function index(ListProductsRequest $request): AnonymousResourceCollection
    {
        $sort = $request->validated('sort', 'id');
        $direction = str_starts_with($sort, '-') ? 'desc' : 'asc';
        $min = $request->validated('min_price');
        $max = $request->validated('max_price');

        $products = Product::query()
            ->when($min !== null, fn ($query) => $query->where('price', '>=', $min))
            ->when($max !== null, fn ($query) => $query->where('price', '<=', $max))
            ->orderBy(ltrim($sort, '-'), $direction)
            // {w_c_tiebreak}
            ->orderBy('id', $direction)
            ->cursorPaginate((int) $request->validated('limit', 5))
            ->withQueryString();

        return ProductResource::collection($products);
    }

    public function show(Request $request, Product $product): JsonResponse
    {
        $response = ProductResource::make($product)->response();
        $response->setEtag((string) $product->version);
        // 304 and no body when If-None-Match matches
        $response->isNotModified($request);

        return $response;
    }

    public function update(
        UpdateProductRequest $request,
        Product $product,
    ): JsonResponse
    {
        $ifMatch = $request->header('If-Match');
        if ($ifMatch === null) {
            throw Problems::needIfMatch();
        }
        // {w_c_atomic}
        $changed = Product::whereKey($product->id)
            ->where('version', (int) trim($ifMatch, '"'))
            ->update([...$request->validated(), 'version' => DB::raw('version + 1')]);
        if ($changed === 0) {
            throw Problems::stale();
        }

        return $this->show($request, $product->refresh());
    }
}
''',
    "app/Http/Controllers/OrderController.php": r'''<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Problems;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

final class OrderController extends Controller
{
    public function store(StoreOrderRequest $request): JsonResponse
    {
        // {w_c_rollback}
        $order = DB::transaction(function () use ($request) {
            $items = [];
            foreach ($request->validated('items') as $line) {
                ['product_id' => $id, 'quantity' => $quantity] = $line;
                // {w_c_stock}
                $taken = Product::whereKey($id)
                    ->where('stock', '>=', $quantity)
                    ->decrement('stock', $quantity, [
                        'version' => DB::raw('version + 1'),
                    ]);
                $product = Product::findOrFail($id);
                if ($taken === 0) {
                    throw Problems::outOfStock($id, $product->stock);
                }
                // {w_c_server_price}
                $items[] = [
                    'product_id' => $id,
                    'quantity' => $quantity,
                    'price' => $product->price,
                ];
            }
            $total = array_sum(array_map(
                fn ($item) => $item['price'] * $item['quantity'],
                $items,
            ));
            $order = Order::create(['status' => 'pending', 'total' => $total]);
            $order->items()->createMany($items);
            return $order;
        });

        return OrderResource::make($order->load('items'))
            ->response()
            ->setStatusCode(201)
            ->header('Location', route('orders.show', $order));
    }

    public function show(Order $order): OrderResource
    {
        return OrderResource::make($order->load('items'));
    }

    public function cancel(Order $order): OrderResource
    {
        if ($order->status !== 'pending') {
            throw Problems::cannotCancel($order->id, $order->status);
        }
        DB::transaction(function () use ($order) {
            $order->update(['status' => 'cancelled']);
            foreach ($order->items as $item) {
                Product::whereKey($item->product_id)
                    ->increment('stock', $item->quantity);
            }
        });

        return $this->show($order);
    }
}
''',
    "routes/api.php": r'''<?php

use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use App\Http\Middleware\Idempotent;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::apiResource('products', ProductController::class)
        ->only(['index', 'show', 'update']);

    Route::controller(OrderController::class)->group(function () {
        Route::post('orders', 'store')->middleware(Idempotent::class)->name('orders.store');
        Route::get('orders/{order}', 'show')->name('orders.show');
        Route::post('orders/{order}/cancel', 'cancel')->name('orders.cancel');
    });
});
''',
    "tests/Feature/ShopApiTest.php": r'''<?php

namespace Tests\Feature;

use Database\Seeders\ProductSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ShopApiTest extends TestCase
{
    use RefreshDatabase;

    protected $seeder = ProductSeeder::class;

    public function test_{w_t_pages_fn}(): void
    {
        $seen = [];
        $url = '/api/v1/products?limit=5';
        while ($url !== null) {
            $page = $this->getJson($url)->assertOk();
            $seen = [...$seen, ...array_column($page->json('data'), 'id')];
            $url = $page->json('links.next');
        }
        $this->assertSame(range(1, 12), $seen);
    }

    public function test_{w_t_sorted_fn}(): void
    {
        $this->getJson('/api/v1/products?sort=-price&limit=3')
            ->assertJsonPath('data.*.price.amount', [45000, 30000, 21000]);
    }

    public function test_{w_t_replay_fn}(): void
    {
        $order = ['items' => [['product_id' => 1, 'quantity' => 2]]];
        $headers = ['Idempotency-Key' => 'test-key-0001'];
        $first = $this->postJson('/api/v1/orders', $order, $headers)->assertCreated();
        $second = $this->postJson('/api/v1/orders', $order, $headers);

        $second->assertHeader('Idempotent-Replayed', 'true');
        $this->assertSame($first->json(), $second->json());
        $this->getJson('/api/v1/products/1')->assertJsonPath('data.stock', 8);
    }

    public function test_{w_t_stale_fn}(): void
    {
        $patch = fn () => $this->patchJson(
            '/api/v1/products/2', ['stock' => 3], ['If-Match' => '"1"']);
        $patch()->assertOk()->assertHeader('ETag', '"2"');
        $patch()->assertStatus(412);
    }

    public function test_{w_t_invalid_fn}(): void
    {
        $order = ['items' => [['product_id' => 99, 'quantity' => 0]]];
        $this->postJson('/api/v1/orders', $order, ['Idempotency-Key' => 'test-key-0002'])
            ->assertStatus(422)
            ->assertHeader('Content-Type', 'application/problem+json')
            ->assertJsonCount(2, 'errors');
    }
}
''',
}

# The exercises' answers, applied to a copy of the project and tested there (answers/ keeps the changed files).
ANSWERS = {
    "app/Http/Requests/ListProductsRequest.php": [
        ("'cursor' => ['sometimes', 'string'],",
         "'cursor' => ['sometimes', 'string'],\n            'q' => ['sometimes', 'string', 'min:2', 'max:50'],"),
    ],
    "app/Http/Controllers/ProductController.php": [
        ("            ->when($max !== null, fn ($query) => $query->where('price', '<=', $max))",
         "            ->when($max !== null, fn ($query) => $query->where('price', '<=', $max))\n"
         "            ->when($request->validated('q'), fn ($query, $q) => $query->whereLike('name', \"%$q%\"))"),
    ],
    "app/Http/Middleware/Idempotent.php": [
        ("        $id = 'idempotency:'.$key;",
         "        // Until Chapter 9 gives us real users, a header names the client.\n"
         "        $client = (string) $request->header('X-Client-Id', 'anonymous');\n"
         "        $id = 'idempotency:'.$client.':'.$key;"),
    ],
}

ANSWER_TEST = r'''<?php

namespace Tests\Feature;

use Database\Seeders\ProductSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AnswersTest extends TestCase
{
    use RefreshDatabase;

    protected $seeder = ProductSeeder::class;

    public function test_exercise_3_search(): void
    {
        $page = $this->getJson('/api/v1/products?q={w_q}&limit=1')->assertOk();
        $this->assertCount(1, $page->json('data'));
        $this->getJson($page->json('links.next'))->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/products?q=x')->assertStatus(422);
    }

    public function test_exercise_5_keys_belong_to_a_client_and_expire(): void
    {
        $order = ['items' => [['product_id' => 1, 'quantity' => 1]]];
        $a = ['Idempotency-Key' => 'same-key-001', 'X-Client-Id' => 'a'];
        $b = ['Idempotency-Key' => 'same-key-001', 'X-Client-Id' => 'b'];

        $first = $this->postJson('/api/v1/orders', $order, $a)->json('data.id');
        $other = $this->postJson('/api/v1/orders', $order, $b)->json('data.id');
        $this->assertNotSame($first, $other);

        $this->travel(25)->hours();
        $later = $this->postJson('/api/v1/orders', $order, $a)->assertCreated();
        $later->assertHeaderMissing('Idempotent-Replayed');
    }
}
'''


def prepare_cache():
    """Puts every package this chapter installs in Composer's cache (see php/seed.py)."""
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer require --no-install --no-scripts -q dedoc/scramble"],
                       cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")
    seed_latest("laravel/sanctum")


def write(shop, t):
    names = "\n".join(f"            '{n}'," for n in NAMES[t["w_locale"]])
    words = dict(t, w_names=names,
                 **{f"{k}_fn": re.sub(r"\W+", "_", t[k]).strip("_") for k in ("w_t_pages", "w_t_sorted", "w_t_replay",
                                                                 "w_t_stale", "w_t_invalid")})
    for name, text in FILES.items():
        if name.startswith("migrations/"):
            # Artisan names migrations after the current time; fixed names keep the book's references stable.
            kind = name.split("/")[1]
            made = Path(glob.glob(str(shop / f"database/migrations/*_create_{kind}_table.php"))[0])
            path = made.with_name(f"2026_11_01_00000{1 if kind == 'products' else 2}_create_{kind}_table.php")
            made.rename(path)
        else:
            path = shop / fill(name, t)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, words))


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    base = "localhost:8000/api/v1"

    s.note(t["w_s_make"])
    s.run("php artisan make:model Product --migration --factory --seed --no-ansi")
    s.run("php artisan make:resource ProductResource --no-ansi")
    s.save(folder / "make.sh")
    for cmd in ("make:model Order --migration", "make:model OrderItem", "make:resource OrderResource",
                "make:request ListProductsRequest", "make:request UpdateProductRequest",
                "make:request StoreOrderRequest", "make:controller ProductController",
                "make:controller OrderController", "make:middleware Idempotent", "make:middleware UnescapedJson"):
        s.run(f"php artisan {cmd} -q")
    s.run("php artisan install:api --no-interaction -q")
    s.run("rm -f database/migrations/*_create_order_items_table.php")
    s.lines.clear()
    write(shop, t)
    (shop / ".env").write_text((shop / ".env").read_text().replace("APP_LOCALE=en", f"APP_LOCALE={t['w_locale']}"))
    s.run("vendor/bin/pint --quiet app bootstrap/app.php config routes tests database lang")
    s.lines.clear()

    s.note(t["w_s_migrate"])
    s.run("php artisan migrate:fresh --seed --no-ansi")
    s.save(folder / "migrate.sh")

    s.note(t["w_s_docs"])
    s.run("composer require dedoc/scramble --no-interaction --no-ansi 2>&1 | grep -E 'Using version|Installing dedoc'")
    s.save(folder / "scramble.sh")

    with Server("php artisan serve --no-ansi", shop, "http://localhost:8000/up"):
        s.note(t["w_s_routes"])
        s.run("curl -s localhost:8000/docs/api.json | jq -r '.paths | to_entries[] | .key as $p "
              "| .value | keys[] | ascii_upcase + \" \" + $p'")
        s.save(folder / "routes.sh")

        s.note(t["w_s_first"])
        out = s.run(f"curl -s '{base}/products?limit=3' | jq -c '(.data[] | [.id, .name, .price.amount]), "
                    ".links, .meta'")
        s.note(t["w_s_next"])
        s.run(f"curl -s \"$(curl -s '{base}/products?limit=3' | jq -r .links.next)\" "
              "| jq -c '(.data[] | [.id, .name, .price.amount]), .meta.next_cursor'")
        s.note(t["w_s_filter"])
        s.run(f"curl -s '{base}/products?limit=2&sort=-price&max_price=20000' "
              "| jq -c '(.data[] | [.id, .price.amount]), .links.next'")
        s.save(folder / "pages.sh")

        s.note(t["w_s_bad"])
        s.run(f"curl -s '{base}/products?limit=500&sort=stock' | jq")
        s.note(t["w_s_missing"])
        s.run(f"curl -s {base}/products/99 | jq -c")
        s.save(folder / "problems.sh")

        patch = (f"curl -s -X PATCH {base}/products/2 -H 'Accept: application/json' "
                 "-H 'Content-Type: application/json' -d '{{\"price\": {p}}}'")
        s.note(t["w_s_read"])
        s.run(f"curl -si {base}/products/2 | grep -iE '^(HTTP|etag)|^\\{{'")
        s.note(t["w_s_no_match"])
        s.run(patch.format(p=6500) + " | jq -c")
        s.note(t["w_s_ok"])
        s.run(patch.format(p=6500).replace("curl -s ", "curl -si ") + " -H 'If-Match: \"1\"' "
              "| grep -iE '^(HTTP|etag)|^\\{'")
        s.note(t["w_s_stale"])
        s.run(patch.format(p=7000) + " -H 'If-Match: \"1\"' | jq -c")
        s.save(folder / "if-match.sh")

        order = (f"curl -si -X POST {base}/orders -H 'Content-Type: application/json' "
                 "-H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{{\"items\": [{{\"product_id\": 1, \"quantity\": {q}}}]}}'")
        s.note(t["w_s_order"])
        s.run(order.format(q=2) + " | grep -iE '^(HTTP|location|idempotent)|^\\{'")
        s.note(t["w_s_again"])
        s.run(order.format(q=2) + " | grep -iE '^(HTTP|location|idempotent)|^\\{'")
        s.note(t["w_s_other"])
        s.run(order.format(q=3).replace("curl -si", "curl -s") + " | jq -c")
        s.note(t["w_s_stock_once"])
        s.run(f"curl -s {base}/products/1 | jq -c '.data | {{id, stock}}'")
        s.save(folder / "idempotency.sh")

        s.note(t["w_s_too_many"])
        s.run(order.format(q=50).replace("curl -si", "curl -s").replace("0001", "0002") + " | jq")
        s.note(t["w_s_cancel"])
        s.run(f"curl -s -X POST {base}/orders/1/cancel | jq -c '.data | {{id, status, total}}'")
        s.run(f"curl -s -X POST {base}/orders/1/cancel | jq -c")
        s.save(folder / "orders.sh")

    s.note(t["w_s_test"])
    s.run("php artisan test --no-ansi tests/Feature/ShopApiTest.php")
    s.save(folder / "test.sh")


def answers(shop, t):
    folder = shop.parent
    copy = folder / "answers-shop"
    if copy.exists():
        shutil.rmtree(copy)
    shutil.copytree(shop, copy, symlinks=True)
    changed = []
    for name, patches in ANSWERS.items():
        path = copy / name
        text = path.read_text()
        for old, new in patches:
            assert old in text, (name, old)
            text = text.replace(old, new)
        path.write_text(text)
        changed.append(name)
    (copy / "tests/Feature/AnswersTest.php").write_text(fill(ANSWER_TEST, t))
    changed.append("tests/Feature/AnswersTest.php")
    s = Session(copy)
    s.run("php artisan test --no-ansi tests/Feature")
    s.save(folder / "answers.sh")
    for name in changed:
        target = folder / "answers" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(copy / name, target)
    shutil.rmtree(copy)


prepare_cache()
for lang, t in T.items():
    t = dict(t, w_q="se" if lang == "en" else "سي")
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    s = Session(folder)
    s.run("composer create-project laravel/laravel shop --no-interaction -q")
    shop = folder / "shop"
    record(shop, t)
    answers(shop, t)
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
