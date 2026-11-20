"""Writes the examples of Book 3 (Laravel edition), the capstone chapter "Capstone: A Production API".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL and Redis through bin/pg-start and
bin/redis-start, then Docker)

A fresh Laravel 13 project per language (<lang>/shop) with everything the book built: Sanctum tokens, products
in cursor pages over an index, orders in one transaction with an Idempotency-Key, the confirmation email as a
job on the database queue (so the job row commits with the order: an outbox), a login limit counted in Redis,
Problem Details, JSON logs, metrics and a readiness check, Pest tests against PostgreSQL, and a multi-stage
image run by Compose with its database, Redis and a queue worker. Transcripts are what the terminal showed.
"""
import json
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
from rec import CLEAN, Session, fill  # noqa: E402
from seed import CACHE, seed_latest, seed_lock  # noqa: E402

T = {
    "en": dict(
        w_p1="Robot kit", w_p2="Spare wheels", w_p3="Soldering iron", w_p4="Battery pack", w_p5="Sensor set",
        w_c_rules="what must hold whatever the code does: the database guarantees it",
        w_c_index="the cursor pages read products by (price, id)",
        w_c_key="one order per customer and key: the database refuses a second",
        w_c_problem="every error the API can give, in the Problem Details format (Chapter 4)",
        w_c_from="how Laravel's own exceptions become problems",
        w_c_dummy="an unknown email still costs one hash, so timing does not reveal which emails exist",
        w_c_hash="Sanctum stores only the token's hash: a leaked table opens no account",
        w_c_limit="5 tries a minute per address and email; throttleWithRedis keeps the count in Redis",
        w_c_cursor="Laravel's cursor pages: the cursor holds the last row's price and id",
        w_c_claim="the key is claimed first; ON CONFLICT DO NOTHING inserts nothing if it was used",
        w_c_once="all or nothing: the order, its lines, the stock and the job commit together",
        w_c_replay="the key was used before: return that order, unless the body is different",
        w_c_stock="the stock is taken only if it is enough, in the same statement",
        w_c_outbox="the database queue writes the job in this same transaction: an outbox, with no extra table",
        w_c_job="the job carries only the id, and reads the rest when it runs",
        w_c_measure="one JSON log line and one counter per request, whatever the answer",
        w_c_ready="ready means the database and Redis both answer; /up only says the process is alive",
        w_c_redis="the rate limits are counted in Redis, shared by every copy of the app; Measure wraps every request, so it also sees the 401s and 429s of the middleware",
        w_c_render="every error under /api leaves as Problem Details",
        w_c_fresh="shop_test is migrated once, then every table is emptied before each test",
        w_m_unauth="Not signed in", w_m_unauth_d="Send a valid token: Authorization: Bearer <token>.",
        w_m_login="Email or password is wrong", w_m_taken="Email already registered",
        w_m_invalid="Invalid request", w_m_many="Too many attempts", w_m_many_d="Try again in :seconds seconds.",
        w_m_none="Not found", w_m_stock="Not enough stock", w_m_stock_d="Product :id has :stock left.",
        w_m_unknown="Unknown product", w_m_reused="Idempotency-Key reused",
        w_m_reused_d="This key was used with a different body.", w_m_server="Server error",
        w_t_order="places an order once, however many times the same key is sent",
        w_t_reused="refuses a key reused with another body",
        w_t_stock="takes no stock when one line is short",
        w_t_token="refuses an order without a token",
        w_t_pages="pages follow each other with no gaps and no repeats",
        w_s_tree="The files this chapter adds to a new Laravel project",
        w_s_test="The tests, against PostgreSQL and Redis",
        w_s_build="The image", w_s_up="Then the API and the worker",
        w_s_migrate="First the database and Redis, then the migrations, as their own step", w_s_register="An account", w_s_login="A token",
        w_s_page="The first page of products, cheapest first", w_s_next="The next page, from the cursor",
        w_s_order="An order, with a key the client chose",
        w_s_retry="The network failed and the client sends it again, with the same key",
        w_s_short="More than the stock", w_s_anon="No token", w_s_guess="Someone guesses a password",
        w_s_metrics="What Prometheus would collect", w_s_worker="The worker sent the email, once",
        w_s_logs="One request in the API's log", w_s_down="Stop everything and delete the data",
    ),
    "ar": dict(
        w_p1="عدة الروبوت", w_p2="عجلات احتياطية", w_p3="كاوية لحام", w_p4="حزمة بطاريات", w_p5="طقم حساسات",
        w_c_rules="ما يجب أن يصح مهما فعل الكود: قاعدة البيانات تضمنه",
        w_c_index="صفحات المؤشر تقرأ المنتجات بـ (price, id)",
        w_c_key="طلب واحد لكل زبون ومفتاح: قاعدة البيانات ترفض الثاني",
        w_c_problem="كل خطأ يمكن أن تعطيه الواجهة، بصيغة Problem Details (الفصل 4)",
        w_c_from="كيف تصير استثناءات Laravel نفسه مشكلات",
        w_c_dummy="البريد المجهول يكلّف بصمة واحدة أيضاً، فلا يكشف الوقت أي البُرُد موجود",
        w_c_hash="لا يخزّن Sanctum إلا بصمة الرمز: جدول مسرَّب لا يفتح أي حساب",
        w_c_limit="5 محاولات في الدقيقة لكل عنوان وبريد؛ وthrottleWithRedis يحفظ العدّ في Redis",
        w_c_cursor="صفحات المؤشر في Laravel: المؤشر يحمل سعر آخر صف ورقمه",
        w_c_claim="يُحجز المفتاح أولاً؛ وON CONFLICT DO NOTHING لا يُدرج شيئاً إن كان مستعملاً",
        w_c_once="الكل أو لا شيء: الطلب وبنوده والمخزون والمهمة تُعتمد معاً",
        w_c_replay="المفتاح استُعمل من قبل: أعد ذلك الطلب، إلا إن اختلف الجسم",
        w_c_stock="لا يؤخذ المخزون إلا إن كفى، في الجملة نفسها",
        w_c_outbox="طابور قاعدة البيانات يكتب المهمة في هذه المعاملة نفسها: صندوق صادر، بلا جدول إضافي",
        w_c_job="المهمة تحمل الرقم وحده، وتقرأ الباقي حين تعمل",
        w_c_measure="سطر سجل JSON واحد وعدّاد واحد لكل طلب، أياً كانت الإجابة",
        w_c_ready="الجاهزية أن تجيب قاعدة البيانات وRedis معاً؛ و/up تقول فقط إن البرنامج حي",
        w_c_redis="حدود المعدل تُعدّ في Redis، تتشاركها كل نسخ التطبيق؛ وMeasure يحيط بكل طلب، فيرى أيضاً 401 و429 من الوسائط",
        w_c_render="كل خطأ تحت /api يخرج بصيغة Problem Details",
        w_c_fresh="تُرحَّل shop_test مرة، ثم يُفرَّغ كل جدول قبل كل اختبار",
        w_m_unauth="لم تسجّل الدخول", w_m_unauth_d="أرسل رمزاً صالحاً: Authorization: Bearer <token>.",
        w_m_login="البريد أو كلمة المرور خطأ", w_m_taken="البريد مسجّل من قبل",
        w_m_invalid="طلب غير صالح", w_m_many="محاولات كثيرة", w_m_many_d="حاول بعد :seconds ثانية.",
        w_m_none="غير موجود", w_m_stock="المخزون لا يكفي", w_m_stock_d="بقي من المنتج :id: :stock.",
        w_m_unknown="منتج مجهول", w_m_reused="مفتاح Idempotency-Key مستعمل",
        w_m_reused_d="استُعمل هذا المفتاح بجسم مختلف.", w_m_server="خطأ في الخادم",
        w_t_order="places an order once, however many times the same key is sent",
        w_t_reused="refuses a key reused with another body",
        w_t_stock="takes no stock when one line is short",
        w_t_token="refuses an order without a token",
        w_t_pages="pages follow each other with no gaps and no repeats",
        w_s_tree="الملفات التي يضيفها هذا الفصل إلى مشروع Laravel جديد",
        w_s_test="الاختبارات، على PostgreSQL وRedis",
        w_s_build="الصورة", w_s_up="ثم الـ API والعامل",
        w_s_migrate="أولاً قاعدة البيانات وRedis، ثم الترحيلات، خطوةً مستقلة", w_s_register="حساب", w_s_login="رمز",
        w_s_page="أول صفحة من المنتجات، الأرخص أولاً", w_s_next="الصفحة التالية، من المؤشر",
        w_s_order="طلب، بمفتاح اختاره العميل",
        w_s_retry="فشلت الشبكة فأعاد العميل الإرسال، بالمفتاح نفسه",
        w_s_short="أكثر من المخزون", w_s_anon="بلا رمز", w_s_guess="أحدهم يخمّن كلمة مرور",
        w_s_metrics="ما سيجمعه Prometheus", w_s_worker="العامل أرسل البريد، مرة واحدة",
        w_s_logs="طلب واحد في سجل الـ API", w_s_down="أوقف كل شيء واحذف البيانات",
    ),
}

FILES = {
    "database/migrations/2026_11_20_000001_create_shop_tables.php": r'''<?php

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
            // {w_c_index}
            $table->index(['price', 'id']);
        });
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->string('idempotency_key', 100);
            $table->string('request_hash', 64);
            $table->integer('total')->default(0);
            $table->timestamps();
            // {w_c_key}
            $table->unique(['user_id', 'idempotency_key']);
        });
        Schema::create('order_items', function (Blueprint $table) {
            $table->foreignId('order_id')->constrained();
            $table->foreignId('product_id')->constrained();
            $table->integer('quantity');
            $table->integer('price');
            $table->primary(['order_id', 'product_id']);
        });
        // {w_c_rules}
        DB::statement('ALTER TABLE products ADD CHECK (price > 0), ADD CHECK (stock >= 0)');
        DB::statement('ALTER TABLE order_items ADD CHECK (quantity > 0)');
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
    }
};
''',
    "database/seeders/DatabaseSeeder.php": r'''<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([['{w_p1}', 45000, 5], ['{w_p2}', 6000, 50], ['{w_p3}', 18000, 12],
            ['{w_p4}', 9000, 30], ['{w_p5}', 25000, 8]] as [$name, $price, $stock]) {
            Product::create(compact('name', 'price', 'stock'));
        }
    }
}
''',
    "app/Models/User.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    use HasApiTokens;

    protected function casts(): array
    {
        return ['password' => 'hashed'];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
''',
    "app/Models/Product.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name', 'price', 'stock'])]
class Product extends Model
{
    public $timestamps = false;
}
''',
    "app/Models/Order.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['total'])]
class Order extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
''',
    "app/Models/OrderItem.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['product_id', 'quantity', 'price'])]
class OrderItem extends Model
{
    public $timestamps = false;

    public $incrementing = false;

    protected $primaryKey = null;
}
''',
    "app/Http/Problem.php": r'''<?php

namespace App\Http;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

// {w_c_problem}
final class Problem extends HttpException
{
    public function __construct(
        int $status,
        public readonly string $title,
        public readonly ?string $detail = null,
        public readonly array $extra = [],
        array $headers = [],
    ) {
        parent::__construct($status, $title, null, $headers);
    }

    public static function unauthenticated(): self
    {
        return new self(401, '{w_m_unauth}', '{w_m_unauth_d}');
    }

    public static function badLogin(): self
    {
        return new self(401, '{w_m_login}');
    }

    public static function emailTaken(): self
    {
        return new self(409, '{w_m_taken}');
    }

    public static function outOfStock(int $id, int $stock): self
    {
        return new self(409, '{w_m_stock}', __('{w_m_stock_d}', ['id' => $id, 'stock' => $stock]));
    }

    public static function unknownProduct(int $id): self
    {
        return new self(422, '{w_m_unknown}', null, ['product_id' => $id]);
    }

    public static function keyReused(): self
    {
        return new self(422, '{w_m_reused}', '{w_m_reused_d}');
    }

    // {w_c_from}
    public static function from(Throwable $e): self
    {
        return match (true) {
            $e instanceof self => $e,
            $e instanceof AuthenticationException => self::unauthenticated(),
            $e instanceof ValidationException => new self(422, '{w_m_invalid}', null, [
                'errors' => collect($e->errors())->map(fn ($messages, $field) => [
                    'field' => $field, 'message' => $messages[0],
                ])->values()->all(),
            ]),
            $e instanceof ThrottleRequestsException => new self(429, '{w_m_many}',
                __('{w_m_many_d}', ['seconds' => $e->getHeaders()['Retry-After']]), [], $e->getHeaders()),
            $e instanceof NotFoundHttpException => new self(404, '{w_m_none}'),
            default => new self(500, '{w_m_server}'),
        };
    }

    public function render(Request $request): JsonResponse
    {
        $body = array_filter([
            'title' => $this->title,
            'status' => $this->getStatusCode(),
            'detail' => $this->detail,
            'instance' => $request->getRequestUri(),
            ...$this->extra,
        ], fn ($value) => $value !== null);
        $headers = ['Content-Type' => 'application/problem+json', ...$this->getHeaders()];

        return response()->json($body, $this->getStatusCode(), $headers, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
}
''',
    "app/Http/Controllers/AuthController.php": r'''<?php

namespace App\Http\Controllers;

use App\Http\Problem;
use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $request->merge(['email' => Str::lower((string) $request->input('email'))]);
        $data = $request->validate([
            'email' => ['required', 'email', 'max:254'],
            'name' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', Password::min(12), 'max:128'],
        ]);
        try {
            $user = User::create($data);
        } catch (UniqueConstraintViolationException) {
            throw Problem::emailTaken();
        }

        return response()->json($user->only('id', 'email', 'name'), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'max:254'],
            'password' => ['required', 'string', 'max:128'],
        ]);
        $user = User::where('email', Str::lower($data['email']))->first();
        // {w_c_dummy}
        $ok = Hash::check($data['password'], $user->password ?? self::dummy());
        if (! $user || ! $ok) {
            throw Problem::badLogin();
        }
        // {w_c_hash}
        $token = $user->createToken('api', ['*'], now()->addDays(30))->plainTextToken;

        return response()->json(['token' => $token]);
    }

    private static function dummy(): string
    {
        static $hash;

        return $hash ??= Hash::make('not anyone\'s password');
    }
}
''',
    "app/Http/Controllers/ProductController.php": r'''<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = $request->validate([
            'limit' => ['integer', 'min:1', 'max:50'],
        ])['limit'] ?? 20;
        // {w_c_cursor}
        $page = Product::query()
            ->select('id', 'name', 'price', 'stock')
            ->orderBy('price')
            ->orderBy('id')
            ->cursorPaginate($limit);

        return response()->json([
            'data' => $page->items(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
''',
    "app/Http/Controllers/OrderController.php": r'''<?php

namespace App\Http\Controllers;

use App\Http\Problem;
use App\Jobs\SendOrderEmail;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $items = $request->validate([
            'items' => ['required', 'array', 'min:1', 'max:20'],
            'items.*.product_id' => ['required', 'integer', 'min:1', 'distinct'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:10'],
        ])['items'];
        $key = Validator::validate(
            ['idempotency_key' => $request->header('Idempotency-Key')],
            ['idempotency_key' => ['required', 'string', 'min:8', 'max:100']],
        )['idempotency_key'];
        $user = $request->user();
        $hash = hash('sha256', json_encode($items));

        // {w_c_once}
        [$order, $replayed] = DB::transaction(function () use ($user, $key, $hash, $items) {
            // {w_c_claim}
            $claimed = DB::table('orders')->insertOrIgnore([
                'user_id' => $user->id, 'idempotency_key' => $key, 'request_hash' => $hash,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $order = $user->orders()->where('idempotency_key', $key)->firstOrFail();
            if ($claimed === 0) {
                // {w_c_replay}
                if ($order->request_hash !== $hash) {
                    throw Problem::keyReused();
                }

                return [$order, true];
            }

            $total = 0;
            foreach ($items as ['product_id' => $id, 'quantity' => $quantity]) {
                // {w_c_stock}
                $taken = Product::whereKey($id)->where('stock', '>=', $quantity)
                    ->decrement('stock', $quantity);
                if ($taken === 0) {
                    $stock = Product::whereKey($id)->value('stock');
                    throw $stock === null
                        ? Problem::unknownProduct($id)
                        : Problem::outOfStock($id, $stock);
                }
                $price = Product::whereKey($id)->value('price');
                $order->items()->create(['product_id' => $id, 'quantity' => $quantity, 'price' => $price]);
                $total += $price * $quantity;
            }
            $order->update(['total' => $total]);
            // {w_c_outbox}
            SendOrderEmail::dispatch($order->id);

            return [$order, false];
        });

        return response()->json(self::present($order), $replayed ? 200 : 201,
            $replayed ? ['Idempotent-Replayed' => 'true'] : []);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        return response()->json(self::present($request->user()->orders()->findOrFail($id)));
    }

    private static function present(Order $order): array
    {
        $items = $order->items()->orderBy('product_id')->get(['product_id', 'quantity', 'price']);

        return ['id' => $order->id, 'total' => $order->total,
            'created_at' => $order->created_at, 'items' => $items];
    }
}
''',
    "app/Jobs/SendOrderEmail.php": r'''<?php

namespace App\Jobs;

use App\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

// {w_c_job}
class SendOrderEmail implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    public array $backoff = [5, 30, 120];

    public function __construct(public int $orderId) {}

    public function handle(): void
    {
        $order = Order::with('user:id,email')->findOrFail($this->orderId);
        Log::info('email sent', ['to' => $order->user->email, 'order_id' => $order->id]);
    }
}
''',
    "app/Http/Middleware/Measure.php": r'''<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;
use Symfony\Component\HttpFoundation\Response;

// {w_c_measure}
class Measure
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = hrtime(true);
        $response = $next($request);
        $route = $request->route()?->uri() ?? 'unknown';
        if (in_array($route, ['up', 'api/ready', 'api/metrics'])) {
            return $response;
        }
        $status = $response->getStatusCode();
        Redis::hincrby('metrics:requests', "{$request->method()}|$route|$status", 1);
        Log::info('request', [
            'method' => $request->method(),
            'url' => $request->getRequestUri(),
            'status' => $status,
            'ms' => intdiv(hrtime(true) - $start, 1_000_000),
        ]);

        return $response;
    }

    public static function metrics(): Response
    {
        $lines = ['# TYPE http_requests_total counter'];
        foreach (Redis::hgetall('metrics:requests') as $key => $count) {
            [$method, $route, $status] = explode('|', $key);
            $lines[] = "http_requests_total{method=\"$method\",route=\"/$route\",status=\"$status\"} $count";
        }

        return response(implode("\n", $lines)."\n", 200, ['Content-Type' => 'text/plain; version=0.0.4']);
    }
}
''',
    "app/Providers/AppServiceProvider.php": r'''<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // {w_c_limit}
        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(5)
            ->by($request->ip().'|'.Str::lower((string) $request->input('email'))));
    }
}
''',
    "routes/api.php": r'''<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use App\Http\Middleware\Measure;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Route;

Route::post('auth/register', [AuthController::class, 'register']);
Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');
Route::get('products', [ProductController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('orders', [OrderController::class, 'store']);
    Route::get('orders/{id}', [OrderController::class, 'show'])->whereNumber('id');
});

// {w_c_ready}
Route::get('ready', function () {
    try {
        DB::select('SELECT 1');
        Redis::ping();

        return ['ready' => true];
    } catch (Throwable) {
        return response()->json(['ready' => false], 503);
    }
});
Route::get('metrics', [Measure::class, 'metrics']);
''',
    "bootstrap/app.php": r'''<?php

use App\Http\Middleware\Measure;
use App\Http\Problem;
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
        // {w_c_redis}
        $middleware->throttleWithRedis();
        $middleware->append(Measure::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // {w_c_render}
        $exceptions->render(function (Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                return Problem::from($e)->render($request);
            }
        });
    })->create();
''',
    "tests/Feature/ApiTest.php": r'''<?php

use App\Models\Product;
use Illuminate\Foundation\Testing\DatabaseTruncation;
use Illuminate\Support\Facades\DB;

// {w_c_fresh}
pest()->use(DatabaseTruncation::class);

beforeEach(fn () => $this->seed());

function signIn(): array
{
    $user = ['email' => 'sara@example.com', 'name' => 'Sara', 'password' => 'a long password'];
    test()->postJson('/api/auth/register', $user);
    $token = test()->postJson('/api/auth/login', $user)->json('token');

    return ['Authorization' => "Bearer $token"];
}

function order(array $headers, string $key, array $items)
{
    return test()->postJson('/api/orders', ['items' => $items], [...$headers, 'Idempotency-Key' => $key]);
}

test('{w_t_order}', function () {
    $auth = signIn();
    $items = [['product_id' => 2, 'quantity' => 3]];
    $first = order($auth, 'key-0001', $items)->assertCreated();
    order($auth, 'key-0001', $items)->assertOk()->assertJsonPath('id', $first->json('id'));
    expect(Product::find(2)->stock)->toBe(47)
        ->and(DB::table('jobs')->count())->toBe(1);
});

test('{w_t_reused}', function () {
    $auth = signIn();
    order($auth, 'key-0002', [['product_id' => 2, 'quantity' => 1]]);
    order($auth, 'key-0002', [['product_id' => 2, 'quantity' => 2]])->assertStatus(422);
});

test('{w_t_stock}', function () {
    $response = order(signIn(), 'key-0003', [
        ['product_id' => 2, 'quantity' => 1],
        ['product_id' => 1, 'quantity' => 6],
    ]);
    $response->assertConflict();
    expect(Product::find(2)->stock)->toBe(50)
        ->and(DB::table('orders')->count())->toBe(0)
        ->and(DB::table('jobs')->count())->toBe(0);
});

test('{w_t_token}', function () {
    order([], 'key-0004', [['product_id' => 2, 'quantity' => 1]])
        ->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/problem+json');
});

test('{w_t_pages}', function () {
    $seen = [];
    $url = '/api/products?limit=2';
    do {
        $page = $this->getJson($url)->json();
        $seen = [...$seen, ...array_column($page['data'], 'id')];
        $url = "/api/products?limit=2&cursor={$page['next_cursor']}";
    } while ($page['next_cursor']);
    expect($seen)->toBe([2, 4, 3, 5, 1]);
});
''',
    ".dockerignore": "vendor\nnode_modules\n.env\ntests\nstorage/logs/*\nstorage/framework/*/*\n"
                     "database/database.sqlite\n",
    "Dockerfile": r'''FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY . .
RUN composer dump-autoload --optimize --no-dev

FROM php:8.5-apache
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev \
 && docker-php-ext-install pdo_pgsql pcntl \
 && rm -rf /var/lib/apt/lists/*
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN echo "FallbackResource /index.php" > /etc/apache2/conf-enabled/laravel.conf \
 && echo 'SetEnvIf Authorization "(.+)" HTTP_AUTHORIZATION=$1' >> /etc/apache2/conf-enabled/laravel.conf \
 && sed -i 's#/var/www/html#/var/www/html/public#' /etc/apache2/sites-available/000-default.conf
WORKDIR /var/www/html
COPY --from=vendor --chown=www-data:www-data /app ./
HEALTHCHECK --interval=5s --timeout=2s CMD curl -fs http://localhost/up || exit 1
''',
    "compose.yaml": r'''name: shop

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: shop
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: shop
    volumes:
      - db-data:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "shop", "-d", "shop"]
      interval: 2s
      retries: 15

  redis:
    image: redis:8
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 2s
      retries: 15

  app:
    build: .
    image: shop-api
    ports:
      - "8080:80"
    environment: &env
      APP_ENV: production
      APP_DEBUG: "false"
      # read from the .env file next to this one, which never goes into the image
      APP_KEY: ${APP_KEY:?APP_KEY is not set}
      DB_CONNECTION: pgsql
      DB_HOST: db
      DB_DATABASE: shop
      DB_USERNAME: shop
      DB_PASSWORD: secret
      REDIS_HOST: redis
      REDIS_CLIENT: predis
      CACHE_STORE: redis
      QUEUE_CONNECTION: database
      LOG_CHANNEL: stderr
      LOG_STDERR_FORMATTER: Monolog\Formatter\JsonFormatter
    depends_on: &ready
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  worker:
    image: shop-api
    command: ["php", "artisan", "queue:work", "--sleep=1"]
    environment: *env
    depends_on: *ready
    # the worker serves no HTTP, so the image's health check does not apply
    healthcheck:
      disable: true

volumes:
  db-data:
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
    seed_latest("predis/predis")


def ccr_build(shop):
    """The image, built here with the proxy's certificate and the downloads Composer already has (this
    machine cannot download GitHub's zip files): Dockerfile.ccr is the Dockerfile with those lines added."""
    shutil.copy("/root/.ccr/ca-bundle.crt", shop / ".ccr-ca.crt")
    lock = json.loads((shop / "composer.lock").read_text())
    for package in lock["packages"]:
        src = CACHE / package["name"]
        if src.exists():
            shutil.copytree(src, shop / ".ccr-cache/files" / package["name"], dirs_exist_ok=True)
    lines = []
    for line in (shop / "Dockerfile").read_text().split("\n"):
        lines.append(line)
        if line.startswith("FROM composer"):
            lines += ["COPY .ccr-ca.crt /tmp/ccr-ca.crt", "ENV SSL_CERT_FILE=/tmp/ccr-ca.crt",
                      "COPY .ccr-cache /tmp/ccr-cache", "ENV COMPOSER_CACHE_DIR=/tmp/ccr-cache"]
        elif line.startswith("FROM php"):
            lines += ["COPY .ccr-ca.crt /usr/local/share/ca-certificates/ccr.crt", "RUN update-ca-certificates",
                      "RUN sed -i 's#http://deb.debian.org#https://deb.debian.org#g' "
                      "/etc/apt/sources.list.d/debian.sources"]
    (shop / "Dockerfile.ccr").write_text("\n".join(lines))
    (shop / ".dockerignore").write_text((shop / ".dockerignore").read_text() + "Dockerfile.ccr\n")
    proxy = os.environ.get("HTTPS_PROXY", "")
    return (f"docker build -q -f Dockerfile.ccr --network host --build-arg HTTPS_PROXY={proxy} "
            f"--build-arg https_proxy={proxy} -t shop-api . > /dev/null 2>&1")


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    s.run("composer remove --dev phpunit/phpunit --no-interaction -q && composer require --dev -W "
          "pestphp/pest pestphp/pest-plugin-laravel --no-interaction -q")
    s.run("./vendor/bin/pest --init --no-interaction < /dev/null > /dev/null 2>&1")
    s.run("php artisan install:api --no-interaction -q")
    s.run("composer require predis/predis --no-interaction -q")
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
                     ("CACHE_STORE=database", "CACHE_STORE=redis"), ("REDIS_CLIENT=phpredis", "REDIS_CLIENT=predis"),
                     ("APP_DEBUG=true", "APP_DEBUG=false")):
        assert old in env, old
        env = env.replace(old, new)
    (shop / ".env").write_text(env)
    xml = (shop / "phpunit.xml").read_text()
    for old, new in (('"DB_CONNECTION" value="sqlite"', '"DB_CONNECTION" value="pgsql"'),
                     ('"DB_DATABASE" value=":memory:"', '"DB_DATABASE" value="shop_test"'),
                     ('"QUEUE_CONNECTION" value="sync"', '"QUEUE_CONNECTION" value="database"')):
        assert old in xml, old
        xml = xml.replace(old, new)
    (shop / "phpunit.xml").write_text(xml)
    s.run("vendor/bin/pint --quiet app routes tests database bootstrap")
    s.run("psql shop -q -c 'CREATE DATABASE shop_test'")
    s.lines.clear()

    s.note(t["w_s_tree"])
    s.run("find app/Http app/Jobs app/Models bootstrap/app.php routes/api.php database/migrations/*shop* "
          "tests/Feature Dockerfile compose.yaml -type f | sort")
    s.save(folder / "tree.sh")
    s.note(t["w_s_test"])
    s.run("./vendor/bin/pest --colors=never 2>&1 | sed -E 's/Duration: .*/Duration: …/; s/ +[0-9.]+s *$//'",
          shown="./vendor/bin/pest")
    s.save(folder / "test.sh")

    build = ccr_build(shop)
    subprocess.run("docker compose down -v", shell=True, cwd=shop, capture_output=True)
    s.note(t["w_s_build"])
    s.run(f"{build} && docker image ls shop-api --format '{{{{.Repository}}}}:{{{{.Tag}}}}  {{{{.Size}}}}'",
          shown="docker build -t shop-api .\n$ docker image ls shop-api")
    s.note(t["w_s_migrate"])
    s.run("docker compose up -d --wait db redis > /dev/null 2>&1")
    s.run("docker compose run --rm app php artisan migrate --force --seed --no-ansi 2>/dev/null "
          "| grep -E 'DONE' | sed -E 's/ +[0-9.]+ms DONE$/ DONE/; s/ \\.{3,}/ …/; s/^ +//'",
          shown="docker compose run --rm app php artisan migrate --force --seed")
    s.note(t["w_s_up"])
    s.run("docker compose up -d --wait 2>&1 | grep -E '(Started|Healthy) *$' | sed -E 's/^ *//; s/ *$//' "
          "| awk '!seen[$0]++'", shown="docker compose up -d --wait")
    s.run("docker compose ps --format 'table {{.Service}}\\t{{.Status}}'")
    s.save(folder / "docker.sh")

    base = "localhost:8080/api"
    j = "-H 'content-type: application/json' -H 'accept: application/json'"
    user = '{"email":"sara@example.com","name":"Sara","password":"a long password"}'
    login = '{"email":"sara@example.com","password":"a long password"}'
    auth = "-H \"authorization: Bearer $TOKEN\""
    real = "-H \"authorization: Bearer $(cat .token)\""
    s.note(t["w_s_register"])
    s.run(f"curl -s {base}/auth/register {j} -d '{user}' | jq -c")
    s.note(t["w_s_login"])
    s.run(f"curl -s {base}/auth/login {j} -d '{login}' | jq -r .token > .token",
          shown=f"TOKEN=$(curl -s {base}/auth/login {j} -d '{login}' | jq -r .token)")
    s.note(t["w_s_page"])
    out = s.run(f"curl -s '{base}/products?limit=2' | jq -c")
    cursor = json.loads(out)["next_cursor"]
    s.note(t["w_s_next"])
    s.run(f"curl -s '{base}/products?limit=2&cursor={cursor}' | jq -c '.data[].name, .next_cursor'")
    body = '{"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}'
    post = (f"curl -s -i {base}/orders {j} AUTH -H 'idempotency-key: order-0001' -d '{body}' "
            "| grep -iE '^HTTP|^idempotent|^\\{' | sed 's/\\r//'")
    s.note(t["w_s_order"])
    s.run(post.replace("AUTH", real), shown=post.replace("AUTH", auth))
    s.note(t["w_s_retry"])
    s.run(post.replace("AUTH", real), shown=post.replace("AUTH", auth))
    s.note(t["w_s_short"])
    short = '{"items":[{"product_id":1,"quantity":4}]}'
    p2 = f"curl -s {base}/orders {j} AUTH -H 'idempotency-key: order-0002' -d '{short}' | jq -c"
    s.run(p2.replace("AUTH", real), shown=p2.replace("AUTH", auth))
    s.note(t["w_s_anon"])
    s.run(f"curl -s {base}/orders {j} -H 'idempotency-key: order-0003' -d '{short}' | jq -c")
    s.note(t["w_s_guess"])
    bad = '{"email":"sara@example.com","password":"guess"}'
    s.run(f"for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{{http_code}} ' {base}/auth/login {j} "
          f"-d '{bad}'; done; echo")
    s.save(folder / "journey.sh")

    s.note(t["w_s_metrics"])
    s.run(f"curl -s {base}/metrics | grep '^http_requests_total'")
    s.note(t["w_s_worker"])
    s.run("sleep 2; docker compose logs worker --no-log-prefix | grep -v '^$' "
          "| sed -E 's/^ *[0-9-]+ ([0-9:]+) /  \\1 /; s/ \\.{3,} / … /; s/ [0-9.]+ms DONE/ DONE/' "
          "| sed -E 's/\"datetime\":\"[^\"]+\",//'", shown="docker compose logs worker")
    s.note(t["w_s_logs"])
    s.run("docker compose logs app --no-log-prefix | grep '\"message\":\"request\"' | grep '/api/orders' | head -1 "
          "| jq -c '{level_name, message, context}'", shown="docker compose logs app")
    s.note(t["w_s_down"])
    s.run("docker compose down -v 2>&1 | grep -E 'Removed' | sed -E 's/^ *//'", shown="docker compose down -v")
    s.save(folder / "ops.sh")
    for name in (".ccr-ca.crt", "Dockerfile.ccr", ".token"):
        (shop / name).unlink(missing_ok=True)
    shutil.rmtree(shop / ".ccr-cache", ignore_errors=True)
    (shop / ".dockerignore").write_text(FILES[".dockerignore"])


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
