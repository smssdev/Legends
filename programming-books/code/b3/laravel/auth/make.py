"""Writes the examples of Book 3 (Laravel edition), the chapter "Authentication and Authorization with Sanctum".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL through bin/pg-start)

A fresh Laravel 13 project per language (<lang>/shop) on PostgreSQL with Sanctum's API tokens: passwords hashed
by Laravel's Hash (bcrypt), sign-in that gives the same answer and time for a wrong email and a wrong password,
tokens stored as their SHA-256, a policy that hides other customers' orders as 404, an "admin" gate, a rate
limit on login, a JWT made by hand to show what is inside one, and feature tests. Every request is made with
curl against `php artisan serve`; the transcripts are what the terminal showed (*.sh).
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
from rec import CLEAN, Server, Session, fill  # noqa: E402
from seed import seed_latest, seed_lock  # noqa: E402

T = {
    "en": dict(
        w_sara="Sara", w_omar="Omar", w_lina="Lina", w_admin="Admin",
        w_m_login="Email or password is wrong.", w_m_taken="Email already registered.",
        w_m_limit="Too many attempts. Try again in :seconds seconds.",
        w_c_lower="emails in lower case: Lina@Example.com is lina@example.com",
        w_c_race="two registrations at once: the unique index decides, not the rule",
        w_c_dummy="an unknown email still costs one hash: the time reveals nothing",
        w_c_same="the same answer for a wrong email and a wrong password",
        w_c_token="Sanctum stores only the SHA-256 of the token; the client gets the only copy",
        w_c_current="only the token that made this request",
        w_c_all="exercise 4: sign out on every device",
        w_c_owner="another customer's order is 'not found': its existence stays secret",
        w_c_gate="a gate: one yes-or-no rule with a name",
        w_c_limit="5 attempts a minute per address and email",
        w_c_jwt_sign="a JWT: header and payload in base64url, then their HMAC",
        w_c_jwt_read="anyone can read the payload: it is encoded, not encrypted",
        w_c_jwt_tamper="change the payload, keep the signature",
        w_c_rehash="exercise 3: a hash made with fewer rounds than the configuration asks for",
        w_c_seed="two customers with orders, and an admin (passwords for development only)",
        w_d_hash1="hash 1", w_d_hash2="hash 2", w_d_right="right password:", w_d_wrong="wrong password:",
        w_d_took="one hash took", w_d_token="token:", w_d_payload="payload, read without the key:",
        w_d_valid="signature valid:", w_d_tampered="tampered token valid:", w_d_old="needs rehash (10 rounds):",
        w_d_new="needs rehash (12 rounds):",
        w_t_register="registers, signs in and reads me", w_t_401="refuses me without a token",
        w_t_403="refuses the admin list to a customer", w_t_404="hides other customers orders",
        w_t_logout="rejects a token after sign out",
        w_s_hash="Two hashes of the same password", w_s_register="Registering",
        w_s_twice="The same email again", w_s_short="A password that is too short",
        w_s_login="Signing in", w_s_wrong="A wrong password, and an unknown email: the same answer",
        w_s_noauth="Without a token", w_s_me="With the token",
        w_s_omar="Omar signs in", w_s_own="His own orders", w_s_other="Sara's order",
        w_s_admin_only="The admin list, as Omar", w_s_as_admin="The admin list, as an admin",
        w_s_logout="Signing out", w_s_after="The same token afterwards",
        w_s_stored="What the database keeps", w_s_limit="Six wrong passwords in a row",
        w_s_jwt="Inside a JWT", w_s_test="The tests", w_s_all="Signed in on two devices, then out of both",
        w_s_install="Sanctum and the API routes, in one command", w_s_rehash="Raising the cost later",
    ),
    "ar": dict(
        w_sara="سارة", w_omar="عمر", w_lina="لينا", w_admin="المدير",
        w_m_login="البريد أو كلمة المرور خطأ.", w_m_taken="البريد مسجّل من قبل.",
        w_m_limit="محاولات كثيرة. حاول مرة أخرى بعد :seconds ثانية.",
        w_c_lower="البُرد بأحرف صغيرة: Lina@Example.com هو lina@example.com",
        w_c_race="تسجيلان معاً: الفهرس الفريد يقرر، لا قاعدة التحقق",
        w_c_dummy="البريد المجهول يكلّف تجزئة أيضاً: الوقت لا يكشف شيئاً",
        w_c_same="الجواب نفسه لبريد خطأ ولكلمة مرور خطأ",
        w_c_token="لا يحفظ Sanctum إلا SHA-256 للرمز؛ والعميل يأخذ النسخة الوحيدة",
        w_c_current="الرمز الذي أرسل هذا الطلب وحده",
        w_c_all="التمرين 4: الخروج من كل الأجهزة",
        w_c_owner="طلب غيرك «غير موجود» لا «غير مسموح»: لا يُكشف وجوده",
        w_c_gate="بوابة: قاعدة واحدة بنعم أو لا ولها اسم",
        w_c_limit="5 محاولات في الدقيقة لكل عنوان وبريد",
        w_c_jwt_sign="JWT: الرأس والحمولة بـ base64url، ثم HMAC لهما بسر الخادم",
        w_c_jwt_read="أي أحد يقرأ الحمولة: إنها مرمّزة لا مشفّرة",
        w_c_jwt_tamper="غيّر الحمولة، وأبقِ التوقيع",
        w_c_rehash="التمرين 3: تجزئة صُنعت بجولات أقل مما يطلبه الإعداد",
        w_c_seed="زبونان لهما طلبات، ومدير (كلمات مرور للتطوير فقط)",
        w_d_hash1="التجزئة 1", w_d_hash2="التجزئة 2", w_d_right="كلمة المرور الصحيحة:",
        w_d_wrong="كلمة مرور خطأ:", w_d_took="استغرقت التجزئة الواحدة", w_d_token="الرمز:",
        w_d_payload="الحمولة، مقروءة بلا المفتاح:", w_d_valid="التوقيع صالح:",
        w_d_tampered="الرمز المعدّل صالح:", w_d_old="تحتاج إعادة تجزئة (10 جولات):",
        w_d_new="تحتاج إعادة تجزئة (12 جولة):",
        w_t_register="يسجّل ويدخل ويقرأ me", w_t_401="يرفض me بلا رمز",
        w_t_403="يرفض قائمة المدير لزبون", w_t_404="يخفي طلبات الزبائن الآخرين",
        w_t_logout="يتوقف الرمز عن العمل بعد الخروج",
        w_s_hash="تجزئتان لكلمة المرور نفسها", w_s_register="التسجيل",
        w_s_twice="البريد نفسه مرة أخرى", w_s_short="كلمة مرور أقصر من اللازم",
        w_s_login="تسجيل الدخول", w_s_wrong="كلمة مرور خطأ، وبريد مجهول: الجواب نفسه",
        w_s_noauth="بلا رمز", w_s_me="بالرمز",
        w_s_omar="عمر يسجّل الدخول", w_s_own="طلباته هو", w_s_other="طلب سارة",
        w_s_admin_only="قائمة المدير، بصفة عمر", w_s_as_admin="قائمة المدير، بصفة مدير",
        w_s_logout="تسجيل الخروج", w_s_after="الرمز نفسه بعدها",
        w_s_stored="ما تحفظه قاعدة البيانات", w_s_limit="ست كلمات مرور خطأ متتالية",
        w_s_jwt="داخل JWT", w_s_test="الاختبارات", w_s_all="دخول من جهازين، ثم خروج من كليهما",
        w_s_install="Sanctum ومسارات API، بأمر واحد", w_s_rehash="رفع الكلفة لاحقاً",
    ),
}

FILES = {
    "database/migrations/2026_11_08_000001_add_role_to_users_table.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('customer');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('role');
        });
    }
};
''',
    "database/migrations/2026_11_08_000002_create_orders_table.php": r'''<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->index()->constrained();
            $table->integer('total');
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
''',
    "app/Models/User.php": r'''<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}
''',
    "app/Models/Order.php": r'''<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Order extends Model
{
    protected $fillable = ['total'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
''',
    "app/Policies/OrderPolicy.php": r'''<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class OrderPolicy
{
    public function view(User $user, Order $order): Response
    {
        // {w_c_owner}
        return $user->id === $order->user_id || $user->isAdmin()
            ? Response::allow()
            : Response::denyAsNotFound();
    }
}
''',
    "app/Http/Controllers/AuthController.php": r'''<?php

namespace App\Http\Controllers;

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
        // {w_c_lower}
        $request->merge(['email' => Str::lower((string) $request->input('email'))]);
        $data = $request->validate([
            'email' => ['required', 'email', 'max:254', 'unique:users'],
            'name' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', Password::min(12), 'max:128'],
        ]);
        try {
            $user = User::create($data)->refresh();
        } catch (UniqueConstraintViolationException) {
            // {w_c_race}
            abort(409, __('{w_m_taken}'));
        }

        return response()->json($user->only('id', 'email', 'name', 'role'), 201);
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
        // {w_c_same}
        if (! $user || ! $ok) {
            abort(401, __('{w_m_login}'));
        }
        // {w_c_token}
        $token = $user->createToken('api', ['*'], now()->addDays(30))->plainTextToken;

        return response()->json(['token' => $token, 'expires_in' => 30 * 24 * 3600]);
    }

    public function logout(Request $request): JsonResponse
    {
        // {w_c_current}
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, 204);
    }

    // {w_c_all}
    public function logoutAll(Request $request): JsonResponse
    {
        $request->user()->tokens()->delete();

        return response()->json(null, 204);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json($user->only('id', 'email', 'name', 'role'));
    }

    private static function dummy(): string
    {
        static $hash;

        return $hash ??= Hash::make('not anyone\'s password');
    }
}
''',
    "app/Http/Controllers/OrderController.php": r'''<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            $request->user()->orders()->orderBy('id')->get(['id', 'total']),
        );
    }

    public function show(Order $order): JsonResponse
    {
        Gate::authorize('view', $order);

        return response()->json($order->only('id', 'user_id', 'total'));
    }

    public function users(): JsonResponse
    {
        return response()->json(User::orderBy('id')->get(['id', 'email', 'role']));
    }
}
''',
    "app/Providers/AppServiceProvider.php": r'''<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // {w_c_gate}
        Gate::define('admin', fn (User $user) => $user->isAdmin());

        // {w_c_limit}
        RateLimiter::for('login', function (Request $request) {
            $key = $request->ip().'|'.Str::lower((string) $request->input('email'));

            return Limit::perMinute(5)->by($key)->response(function ($request, $headers) {
                $seconds = $headers['Retry-After'];

                return response()->json([
                    'message' => __('{w_m_limit}', ['seconds' => $seconds]),
                ], 429, $headers);
            });
        });
    }
}
''',
    "routes/api.php": r'''<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\OrderController;
use Illuminate\Support\Facades\Route;

Route::controller(AuthController::class)->group(function () {
    Route::post('auth/register', 'register');
    Route::post('auth/login', 'login')->middleware('throttle:login');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', 'logout');
        Route::post('auth/logout-all', 'logoutAll');
        Route::get('me', 'me');
    });
});

Route::middleware('auth:sanctum')
    ->controller(OrderController::class)
    ->group(function () {
        Route::get('orders', 'index');
        Route::get('orders/{order}', 'show');
        Route::get('admin/users', 'users')->middleware('can:admin');
    });
''',
    "routes/console.php": r'''<?php

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;

Artisan::command('shop:hash', function () {
    $password = 'correct horse battery staple';
    $a = Hash::make($password);
    $b = Hash::make($password);
    $this->line("{w_d_hash1} $a");
    $this->line("{w_d_hash2} $b");
    $this->line('{w_d_right} '.json_encode(Hash::check($password, $a)));
    $this->line('{w_d_wrong} '.json_encode(Hash::check($password.'r', $a)));
    $start = hrtime(true);
    Hash::make($password);
    $this->line('{w_d_took} '.round((hrtime(true) - $start) / 1e6).' ms');
});

Artisan::command('shop:rehash', function () {
    // {w_c_rehash}
    $old = Hash::make('correct horse battery staple', ['rounds' => 10]);
    $this->line('{w_d_old} '.json_encode(Hash::needsRehash($old)));
    $new = Hash::make('correct horse battery staple');
    $this->line('{w_d_new} '.json_encode(Hash::needsRehash($new)));
});

Artisan::command('shop:jwt', function () {
    $secret = 'a secret only the server knows';
    $url = fn (string $bytes) => rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
    $b64 = fn (array $value) => $url(json_encode($value));
    $sign = fn (string $data) => $url(hash_hmac('sha256', $data, $secret, true));

    // {w_c_jwt_sign}
    $header = $b64(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = $b64(['sub' => 2, 'role' => 'customer', 'exp' => 1795000000]);
    $token = "$header.$payload.".$sign("$header.$payload");
    $this->line("{w_d_token} $token");

    // {w_c_jwt_read}
    $read = fn (string $part) => base64_decode(strtr($part, '-_', '+/'));
    $this->line('{w_d_payload} '.$read(explode('.', $token)[1]));

    $valid = function (string $jwt) use ($sign) {
        [$h, $p, $signature] = explode('.', $jwt);

        return hash_equals($sign("$h.$p"), $signature);
    };
    $this->line('{w_d_valid} '.json_encode($valid($token)));
    // {w_c_jwt_tamper}
    $forged = $b64(['sub' => 2, 'role' => 'admin', 'exp' => 1795000000]);
    $signature = explode('.', $token)[2];
    $this->line('{w_d_tampered} '.json_encode($valid("$header.$forged.$signature")));
});
''',
    "database/seeders/DatabaseSeeder.php": r'''<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // {w_c_seed}
        $people = [
            ['sara@example.com', '{w_sara}', 'customer', [45000, 6000]],
            ['omar@example.com', '{w_omar}', 'customer', [12000]],
            ['admin@example.com', '{w_admin}', 'admin', []],
        ];
        foreach ($people as [$email, $name, $role, $totals]) {
            $user = User::forceCreate([
                'email' => $email,
                'name' => $name,
                'role' => $role,
                'password' => strtok($email, '@').'-password-2026',
            ]);
            foreach ($totals as $total) {
                $user->orders()->create(['total' => $total]);
            }
        }
    }
}
''',
    "tests/Feature/AuthTest.php": r'''<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected $seed = true;

    private function signIn(string $email, string $password): array
    {
        $token = $this->postJson('/api/auth/login', compact('email', 'password'))
            ->assertOk()
            ->json('token');

        return ['Authorization' => "Bearer $token"];
    }

    public function test_it_{w_t_register_fn}(): void
    {
        $this->postJson('/api/auth/register', [
            'email' => 'test@example.com',
            'name' => 'Test',
            'password' => 'a long test password',
        ])->assertCreated();
        $as = $this->signIn('test@example.com', 'a long test password');
        $this->getJson('/api/me', $as)->assertJsonPath('email', 'test@example.com');
    }

    public function test_it_{w_t_401_fn}(): void
    {
        $this->getJson('/api/me')->assertUnauthorized();
    }

    public function test_it_{w_t_403_fn}(): void
    {
        $omar = $this->signIn('omar@example.com', 'omar-password-2026');
        $this->getJson('/api/admin/users', $omar)->assertForbidden();
    }

    public function test_it_{w_t_404_fn}(): void
    {
        $omar = $this->signIn('omar@example.com', 'omar-password-2026');
        $this->getJson('/api/orders/1', $omar)->assertNotFound();
    }

    public function test_it_{w_t_logout_fn}(): void
    {
        $sara = $this->signIn('sara@example.com', 'sara-password-2026');
        $this->postJson('/api/auth/logout', [], $sara)->assertNoContent();
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/me', $sara)->assertUnauthorized();
    }
}
''',
}


def prepare_cache():
    """Puts every package this chapter installs in Composer's cache (see php/seed.py)."""
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer update --no-install --no-scripts -q"],
                       cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")
    seed_latest("laravel/sanctum")


def write(shop, t):
    import re
    words = dict(t, **{f"{k}_fn": re.sub(r"\W+", "_", T["en"][k]).strip("_")
                       for k in ("w_t_register", "w_t_401", "w_t_403", "w_t_404", "w_t_logout")})
    for name, text in FILES.items():
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, words))
    made = glob.glob(str(shop / "database/migrations/*_create_personal_access_tokens_table.php"))[0]
    Path(made).rename(shop / "database/migrations/2026_11_08_000000_create_personal_access_tokens_table.php")
    env = (shop / ".env").read_text()
    for old, new in (("DB_CONNECTION=sqlite", "DB_CONNECTION=pgsql"), ("# DB_HOST=127.0.0.1", "DB_HOST=127.0.0.1"),
                     ("# DB_PORT=3306", "DB_PORT=5432"), ("# DB_DATABASE=laravel", "DB_DATABASE=shop"),
                     ("# DB_USERNAME=root", "DB_USERNAME=bit"), ("# DB_PASSWORD=", "DB_PASSWORD=secret"),
                     ("APP_DEBUG=true", "APP_DEBUG=false")):
        env = env.replace(old, new)
    (shop / ".env").write_text(env)


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    s.run("php artisan install:api --no-interaction --no-ansi -q")
    write(shop, t)
    s.run("vendor/bin/pint --quiet app config routes tests database")
    s.run("php artisan migrate:fresh --seed --no-ansi -q")
    s.lines.clear()

    s.note(t["w_s_hash"])
    s.run("php artisan shop:hash")
    s.save(folder / "hash.sh")
    s.note(t["w_s_jwt"])
    s.run("php artisan shop:jwt")
    s.save(folder / "jwt.sh")

    api = "localhost:8000/api"
    j = "-H 'Accept: application/json' -H 'Content-Type: application/json'"
    login = f"curl -s {api}/auth/login {j} " + "-d '{{\"email\":\"{}\",\"password\":\"{}\"}}'"
    auth = '-H "Accept: application/json" -H "Authorization: Bearer $({})"'

    def as_(var, file):
        return {"run": auth.format(f"cat {file}"), "shown": auth.format("").replace("$()", f"${var}")}

    with Server("php artisan serve --no-ansi", shop, "http://localhost:8000/up"):
        s.note(t["w_s_register"])
        reg = (f"curl -s -i {api}/auth/register {j} -d '{{\"email\":\"Lina@Example.com\","
               f"\"name\":\"{t['w_lina']}\",\"password\":\"a long and silly sentence\"}}'")
        s.run(reg + " | grep -iE '^HTTP|^content-type|^\\{' | sed 's/\\r//'", shown=reg)
        s.note(t["w_s_twice"])
        s.run(f"curl -s {api}/auth/register {j} -d '{{\"email\":\"lina@example.com\","
              f"\"name\":\"{t['w_lina']}\",\"password\":\"another long sentence\"}}' | jq")
        s.note(t["w_s_short"])
        s.run(f"curl -s {api}/auth/register {j} -d '{{\"email\":\"sam@example.com\","
              f"\"name\":\"Sam\",\"password\":\"short\"}}' | jq")
        s.save(folder / "register.sh")

        s.note(t["w_s_login"])
        s.run(login.format("lina@example.com", "a long and silly sentence") + " | jq")
        s.note(t["w_s_wrong"])
        s.run(login.format("lina@example.com", "a wrong sentence") + " | jq")
        s.run(login.format("nobody@example.com", "a wrong sentence") + " | jq")
        s.save(folder / "login.sh")

        def keep(var, email, password, file):
            s.run(login.format(email, password) + f" | jq -r .token > {file}")
            s.lines.pop()
            s.add(f"$ {var}=$(" + login.format(email, password) + " | jq -r .token)")

        s.note(t["w_s_noauth"])
        s.run(f"curl -s {api}/me -H 'Accept: application/json' | jq")
        s.note(t["w_s_me"])
        keep("TOKEN", "lina@example.com", "a long and silly sentence", ".token")
        a = as_("TOKEN", ".token")
        s.run(f"curl -s {api}/me {a['run']} | jq", shown=f"curl -s {api}/me {a['shown']} | jq")
        s.save(folder / "me.sh")

        s.note(t["w_s_omar"])
        keep("OMAR", "omar@example.com", "omar-password-2026", ".omar")
        o = as_("OMAR", ".omar")
        s.note(t["w_s_own"])
        s.run(f"curl -s {api}/orders {o['run']} | jq -c", shown=f"curl -s {api}/orders {o['shown']} | jq -c")
        s.note(t["w_s_other"])
        s.run(f"curl -s {api}/orders/1 {o['run']} | jq", shown=f"curl -s {api}/orders/1 {o['shown']} | jq")
        s.note(t["w_s_admin_only"])
        s.run(f"curl -s {api}/admin/users {o['run']} | jq", shown=f"curl -s {api}/admin/users {o['shown']} | jq")
        s.note(t["w_s_as_admin"])
        keep("ADMIN", "admin@example.com", "admin-password-2026", ".admin")
        d = as_("ADMIN", ".admin")
        s.run(f"curl -s {api}/admin/users {d['run']} | jq -c '.[]'",
              shown=f"curl -s {api}/admin/users {d['shown']} | jq -c '.[]'")
        s.save(folder / "authz.sh")

        code = 'curl -s -o /dev/null -w "%{http_code}\\n"'
        s.note(t["w_s_logout"])
        s.run(f"{code} -X POST {api}/auth/logout {a['run']}", shown=f"{code} -X POST {api}/auth/logout {a['shown']}")
        s.note(t["w_s_after"])
        s.run(f"curl -s {api}/me {a['run']} | jq -c", shown=f"curl -s {api}/me {a['shown']} | jq -c")
        s.note(t["w_s_stored"])
        s.run("psql shop -c 'SELECT email, left(password, 30) AS password FROM users ORDER BY id'")
        s.run("psql shop -c 'SELECT tokenable_id, left(token, 16) AS token, expires_at::date "
              "FROM personal_access_tokens ORDER BY id'")
        s.save(folder / "logout.sh")

        s.note(t["w_s_limit"])
        s.run(f"for i in 1 2 3 4 5 6; do {code.replace(chr(92) + 'n', ' ')} {api}/auth/login {j} "
              "-d '{\"email\":\"sara@example.com\",\"password\":\"guess number one\"}'; done; echo")
        s.run(login.format("sara@example.com", "guess number seven") + " | jq")
        s.save(folder / "limit.sh")

        for name in ("phone", "laptop"):
            s.run(login.format("omar@example.com", "omar-password-2026") + f" | jq -r .token > .{name}")
        s.lines.clear()
        s.note(t["w_s_all"])
        p, lt = as_("PHONE", ".phone"), as_("LAPTOP", ".laptop")
        s.run(f"{code} -X POST {api}/auth/logout-all {p['run']}",
              shown=f"{code} -X POST {api}/auth/logout-all {p['shown']}")
        s.run(f"{code} {api}/me {lt['run']}", shown=f"{code} {api}/me {lt['shown']}")
        s.note(t["w_s_rehash"])
        s.run("php artisan shop:rehash")
        s.save(folder / "answers.sh")

    s.note(t["w_s_test"])
    s.run("php artisan test --no-ansi tests/Feature/AuthTest.php")
    s.save(folder / "test.sh")
    for name in (".token", ".omar", ".admin", ".phone", ".laptop"):
        (shop / name).unlink(missing_ok=True)


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
