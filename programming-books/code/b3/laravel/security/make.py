"""Writes the examples of Book 3 (Laravel edition), the chapter "Security: Attacks and Defences".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php, PostgreSQL through bin/pg-start)

A fresh Laravel 13 project per language (<lang>/shop) where each attack has two routes side by side: /unsafe/...
written the obvious way, and the safe version. SQL injection that leaks password hashes, mass assignment that
makes a customer an admin, a path that reads the .env file, debug mode leaking SQL and server details; then
the defences: bindings, validated fields, a Flysystem disk, security headers in a middleware, CORS for one
origin, and composer audit. Every request is made with curl against `php artisan serve` (*.sh).
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
        w_kit="Robot kit", w_wheels="Spare wheels", w_sara="Sara", w_omar="Omar",
        w_terms="Terms of sale: prices include VAT; returns within 14 days.",
        w_c_concat="DANGER: the input becomes part of the SQL text",
        w_c_bind="the input travels separately, as a binding: it is only ever a value",
        w_c_same="the same query with Eloquent: Product::where('name', $q)->get()",
        w_c_mass="DANGER: every field the client sends is written, role included",
        w_c_rules="only the fields a customer may change; role is refused outright",
        w_c_join="DANGER: '../' climbs out of the folder",
        w_c_disk="a disk rooted at the folder: Flysystem refuses paths that climb out",
        w_c_headers="security headers on every response; an API needs no scripts or frames at all",
        w_c_boom="a query that fails, to see what an error reveals",
        w_s_search="An ordinary search", w_s_inject="The same search, with SQL in the input",
        w_s_safe_inject="The same input, as a binding",
        w_s_mass="Omar changes his name, and his role",
        w_s_strict="The same request, on the safe route",
        w_s_file="A public file", w_s_climb="Climbing out of the folder",
        w_s_safe_climb="The same path, on the safe route",
        w_s_headers="The headers of every response",
        w_s_cors_ok="A request from the shop's website", w_s_cors_bad="A request from another website",
        w_s_debug="An error with APP_DEBUG=true", w_s_nodebug="The same error with APP_DEBUG=false",
        w_s_long="A search of 200 characters",
        w_s_audit="Known vulnerabilities in the dependencies", w_s_ignore="What git never sees",
        w_s_preflight="What a browser asks before a PATCH from the shop's website",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية", w_sara="سارة", w_omar="عمر",
        w_terms="شروط البيع: الأسعار تشمل الضريبة؛ والإرجاع خلال 14 يوماً.",
        w_c_concat="خطر: المدخل يصير جزءاً من نص SQL",
        w_c_bind="المدخل يسافر منفصلاً، بصفة ربط: لا يكون إلا قيمة",
        w_c_same="الاستعلام نفسه بـ Eloquent: Product::where('name', $q)->get()",
        w_c_mass="خطر: كل حقل يرسله العميل يُكتب، والدور معه",
        w_c_rules="الحقول التي يجوز للزبون تغييرها وحدها؛ والدور مرفوض صراحة",
        w_c_join="خطر: '../' تصعد خارج المجلد",
        w_c_disk="قرص جذره المجلد: Flysystem ترفض المسارات التي تصعد خارجه",
        w_c_headers="ترويسات أمان مع كل استجابة؛ وAPI لا يحتاج سكربتات ولا إطارات أصلاً",
        w_c_boom="استعلام يفشل، لنرى ما يكشفه الخطأ",
        w_s_search="بحث عادي", w_s_inject="البحث نفسه، وفي المدخل SQL",
        w_s_safe_inject="المدخل نفسه، بصفة ربط",
        w_s_mass="عمر يغيّر اسمه، ودوره",
        w_s_strict="الطلب نفسه، على المسار الآمن",
        w_s_file="ملف عام", w_s_climb="الصعود خارج المجلد",
        w_s_safe_climb="المسار نفسه، على المسار الآمن",
        w_s_headers="ترويسات كل استجابة",
        w_s_cors_ok="طلب من موقع المتجر", w_s_cors_bad="طلب من موقع آخر",
        w_s_debug="خطأ مع APP_DEBUG=true", w_s_nodebug="الخطأ نفسه مع APP_DEBUG=false",
        w_s_long="بحث من 200 حرف",
        w_s_audit="الثغرات المعروفة في الاعتماديات", w_s_ignore="ما لا يراه git أبداً",
        w_s_preflight="ما يسأله المتصفح قبل PATCH من موقع المتجر",
    ),
}

FILES = {
    "database/migrations/2026_11_09_000001_create_shop_tables.php": r'''<?php

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
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->integer('price');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('role');
        });
    }
};
''',
    "database/seeders/DatabaseSeeder.php": r'''<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::forceCreate([
            'name' => '{w_sara}', 'email' => 'sara@example.com',
            'role' => 'admin', 'password' => 'sara-password-2026',
        ]);
        User::forceCreate([
            'name' => '{w_omar}', 'email' => 'omar@example.com',
            'role' => 'customer', 'password' => 'omar-password-2026',
        ]);
        DB::table('products')->insert([
            ['name' => '{w_kit}', 'price' => 45000],
            ['name' => '{w_wheels}', 'price' => 6000],
        ]);
    }
}
''',
    "app/Http/Middleware/SecurityHeaders.php": r'''<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        // {w_c_headers}
        $response->headers->add([
            'Content-Security-Policy' => "default-src 'none'; frame-ancestors 'none'",
            'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
            'X-Content-Type-Options' => 'nosniff',
            'X-Frame-Options' => 'DENY',
            'Referrer-Policy' => 'no-referrer',
        ]);

        return $response;
    }
}
''',
    "routes/api.php": r'''<?php

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use League\Flysystem\PathTraversalDetected;

Route::get('unsafe/products', function (Request $request) {
    $q = $request->query('q');

    // {w_c_concat}
    return DB::select("SELECT name, price FROM products WHERE name = '$q'");
});

Route::get('products', function (Request $request) {
    $q = $request->validate(['q' => ['required', 'string', 'max:100']])['q'];

    // {w_c_bind}
    // {w_c_same}
    return DB::select('SELECT name, price FROM products WHERE name = ?', [$q]);
});

Route::patch('unsafe/users/{user}', function (Request $request, User $user) {
    // {w_c_mass}
    $user->forceFill($request->all())->save();

    return $user->only('id', 'name', 'role');
});

Route::patch('users/{user}', function (Request $request, User $user) {
    // {w_c_rules}
    $user->update($request->validate([
        'name' => ['required', 'string', 'max:100'],
        'role' => ['prohibited'],
    ]));

    return $user->only('id', 'name', 'role');
});

Route::get('unsafe/files/{path}', function (string $path) {
    // {w_c_join}
    $text = file_get_contents(storage_path("app/files/$path"));

    return response($text)->header('Content-Type', 'text/plain');
})->where('path', '.*');

Route::get('files/{path}', function (string $path) {
    // {w_c_disk}
    $files = Storage::build(['driver' => 'local', 'root' => storage_path('app/files')]);
    try {
        $text = $files->get($path) ?? abort(404, 'Not Found');
    } catch (PathTraversalDetected) {
        abort(404, 'Not Found');
    }

    return response($text)->header('Content-Type', 'text/plain');
})->where('path', '.*');

// {w_c_boom}
Route::get('boom', fn () => DB::select('SELECT * FROM missing_table'));
''',
    "storage/app/files/terms.txt": "{w_terms}\n",
}


def prepare_cache():
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer update --no-install --no-scripts -q"],
                       cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")
    seed_latest("laravel/sanctum")


def write(shop, t):
    for name, text in FILES.items():
        path = shop / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    app = shop / "bootstrap/app.php"
    text = app.read_text()
    old = "->withMiddleware(function (Middleware $middleware): void {\n        //\n    })"
    assert old in text
    app.write_text(text.replace(old, "->withMiddleware(function (Middleware $middleware): void {\n"
                                     "        $middleware->append(\\App\\Http\\Middleware\\SecurityHeaders::class);\n    })"))
    cors = shop / "config/cors.php"
    text = cors.read_text()
    for old, new in (("'allowed_methods' => ['*'],", "'allowed_methods' => ['GET', 'PATCH'],"),
                     ("'allowed_origins' => ['*'],", "'allowed_origins' => [env('ALLOWED_ORIGIN')],")):
        assert old in text
        text = text.replace(old, new)
    cors.write_text(text)
    env = (shop / ".env").read_text()
    for old, new in (("DB_CONNECTION=sqlite", "DB_CONNECTION=pgsql"), ("# DB_HOST=127.0.0.1", "DB_HOST=127.0.0.1"),
                     ("# DB_PORT=3306", "DB_PORT=5432"), ("# DB_DATABASE=laravel", "DB_DATABASE=shop"),
                     ("# DB_USERNAME=root", "DB_USERNAME=bit"), ("# DB_PASSWORD=", "DB_PASSWORD=secret"),
                     ("APP_DEBUG=true", "APP_DEBUG=false")):
        env = env.replace(old, new)
    (shop / ".env").write_text(env + "\nALLOWED_ORIGIN=https://shop.example\n")


def record(shop, t):
    folder = shop.parent
    s = Session(shop)
    s.run("php artisan install:api --no-interaction --no-ansi -q")
    s.run("php artisan config:publish cors --no-interaction -q")
    write(shop, t)
    s.run("vendor/bin/pint --quiet app config routes database bootstrap")
    s.run("php artisan migrate:fresh --seed --no-ansi -q")
    s.lines.clear()

    api = "localhost:8000/api"
    with Server("php artisan serve --no-ansi", shop, "http://localhost:8000/up"):
        q = "curl -s -G " + api + "{} -H 'Accept: application/json' --data-urlencode \"q={}\" | jq -c"
        evil = "x' UNION SELECT email || ' ' || password, 0 FROM users --"
        s.note(t["w_s_search"])
        s.run(q.format("/unsafe/products", t["w_kit"]))
        s.note(t["w_s_inject"])
        s.run(q.format("/unsafe/products", evil).replace("jq -c", "jq -c '.[]'"))
        s.note(t["w_s_safe_inject"])
        s.run(q.format("/products", evil))
        s.save(folder / "injection.sh")

        patch = (f"curl -s -X PATCH {api}PREFIX/users/2 -H 'Accept: application/json' "
                 "-H 'Content-Type: application/json' "
                 f"-d '{{\"name\":\"{t['w_omar']}\",\"role\":\"admin\"}}' | jq -c")
        s.note(t["w_s_mass"])
        s.run(patch.replace("PREFIX", "/unsafe"))
        s.run("psql shop -q -c \"UPDATE users SET role = 'customer' WHERE id = 2\"")
        s.lines.pop()
        s.note(t["w_s_strict"])
        s.run(patch.replace("PREFIX", ""))
        s.save(folder / "mass.sh")

        s.note(t["w_s_file"])
        s.run(f"curl -s {api}/unsafe/files/terms.txt")
        s.note(t["w_s_climb"])
        s.run(f"curl -s --path-as-is {api}/unsafe/files/../../../.env | grep -E '^(APP_KEY|DB_)'",
              shown=f"curl -s --path-as-is {api}/unsafe/files/../../../.env")
        s.note(t["w_s_safe_climb"])
        s.run(f"curl -s --path-as-is {api}/files/../../../.env -H 'Accept: application/json' | jq -c")
        s.save(folder / "traversal.sh")

        s.note(t["w_s_headers"])
        s.run(f"curl -s -I {api}/files/terms.txt | grep -iE "
              "'^(HTTP|content-security|strict-transport|x-content|x-frame|referrer)'",
              shown=f"curl -s -I {api}/files/terms.txt")
        s.save(folder / "headers.sh")

        s.note(t["w_s_cors_ok"])
        s.run(f"curl -s -I {api}/files/terms.txt -H 'Origin: https://shop.example' "
              "| grep -iE '^(HTTP|access-control|vary)'")
        s.note(t["w_s_cors_bad"])
        s.run(f"curl -s -I {api}/files/terms.txt -H 'Origin: https://evil.example' "
              "| grep -iE '^(HTTP|access-control|vary)'")
        s.save(folder / "cors.sh")

        s.note(t["w_s_long"])
        s.run(f"curl -s -G {api}/products -H 'Accept: application/json' "
              "--data-urlencode \"q=$(printf 'a%.0s' $(seq 200))\" | jq -c")
        s.note(t["w_s_nodebug"])
        s.run(f"curl -s {api}/boom -H 'Accept: application/json' | jq -c")
        s.save(folder / "errors.sh")

        s.note(t["w_s_preflight"])
        s.run(f"curl -s -i -X OPTIONS {api}/users/2 -H 'Origin: https://shop.example' "
              "-H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' "
              "| grep -iE '^(HTTP|access-control)'")
        s.save(folder / "answers.sh")

    env = shop / ".env"
    env.write_text(env.read_text().replace("APP_DEBUG=false", "APP_DEBUG=true"))
    with Server("php artisan serve --port=8001 --no-ansi", shop, "http://localhost:8001/up"):
        s.note(t["w_s_debug"])
        s.run("curl -s localhost:8000/api/boom -H 'Accept: application/json' "
              "| jq '{message, exception, file, line}'".replace("8000", "8001"),
              shown="curl -s localhost:8000/api/boom -H 'Accept: application/json' "
                    "| jq '{message, exception, file, line}'")
        s.save(folder / "debug.sh")
    env.write_text(env.read_text().replace("APP_DEBUG=true", "APP_DEBUG=false"))

    s.note(t["w_s_ignore"])
    s.run("cat .gitignore | grep -n env")
    s.note(t["w_s_audit"])
    s.run("composer audit --no-ansi 2>&1")
    s.save(folder / "audit.sh")


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
