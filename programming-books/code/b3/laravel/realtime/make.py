"""Writes the examples of Book 3 (Laravel edition), the chapter "Real-time with Reverb".
Run: python3 make.py   (PHP 8.5 through code/b3/bin/php)

A fresh Laravel 13 project per language (<lang>/shop) with broadcasting through Reverb, Laravel's own WebSocket
server: an event that broadcasts an order's status, Reverb running for real, and a small client (watch.ts,
Node's own WebSocket) that speaks the Pusher protocol Reverb uses, in one terminal, while Artisan changes the
status in another; then a private channel and its authorization route. Transcripts are saved as *.sh.
"""
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
sys.path.insert(0, str(B3 / "php"))
from rec import CLEAN, Server, Session, fill  # noqa: E402
from seed import seed_lock  # noqa: E402

T = {
    "en": dict(
        w_c_now="broadcast at once; with ShouldBroadcast it would go through the queue",
        w_c_channel="the channel: everyone watching order 1001 listens here",
        w_c_name="the event's name, as clients see it",
        w_c_data="exactly what clients receive: nothing more than they need",
        w_c_private="exercise 4: only the order's customer may listen to its private channel",
        w_c_client="a client speaking the Pusher protocol, which Reverb uses; in a browser, Laravel Echo does this",
        w_c_key="the app key from .env: it says which application we connect to (it is not a secret)",
        w_c_subscribe="once connected, ask for the channel",
        w_d_changed="order {order} is now {status}",
        w_s_install="Broadcasting with Reverb, in one command",
        w_s_watch="A screen follows order 1001",
        w_s_change="Meanwhile, the shop changes its status",
        w_s_auth="A private channel needs permission",
    ),
    "ar": dict(
        w_c_now="يُبث في الحال؛ ومع ShouldBroadcast يمر عبر الطابور",
        w_c_channel="القناة: كل من يتابع الطلب 1001 يستمع هنا",
        w_c_name="اسم الحدث، كما يراه العملاء",
        w_c_data="بالضبط ما يستقبله العملاء: لا أكثر مما يحتاجون",
        w_c_private="التمرين 4: زبون الطلب وحده يستمع إلى قناته الخاصة",
        w_c_client="عميل يتكلم بروتوكول Pusher الذي يستخدمه Reverb؛ وفي المتصفح يفعل Laravel Echo هذا",
        w_c_key="مفتاح التطبيق من .env: يقول بأي تطبيق نتصل (وليس سراً)",
        w_c_subscribe="بعد الاتصال، اطلب القناة",
        w_d_changed="الطلب {order} صار {status}",
        w_s_install="البث بـ Reverb، بأمر واحد",
        w_s_watch="شاشة تتابع الطلب 1001",
        w_s_change="في الأثناء، يغيّر المتجر حالته",
        w_s_auth="القناة الخاصة تحتاج إذناً",
    ),
}

FILES = {
    "shop/app/Events/OrderStatusChanged.php": r'''<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

// {w_c_now}
class OrderStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $orderId, public string $status) {}

    // {w_c_channel}
    public function broadcastOn(): array
    {
        return [new Channel("orders.{$this->orderId}")];
    }

    // {w_c_name}
    public function broadcastAs(): string
    {
        return 'status';
    }

    // {w_c_data}
    public function broadcastWith(): array
    {
        return ['order' => $this->orderId, 'status' => $this->status];
    }
}
''',
    "shop/routes/channels.php": r'''<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\DB;

// {w_c_private}
Broadcast::channel('orders.{orderId}', function (User $user, int $orderId) {
    return DB::table('orders')->where('id', $orderId)->where('user_id', $user->id)->exists();
});
''',
    "shop/routes/console.php": r'''<?php

use App\Events\OrderStatusChanged;
use Illuminate\Support\Facades\Artisan;

Artisan::command('shop:status {order} {status}', function (int $order, string $status) {
    // ... the order's status is saved in the database here ...
    OrderStatusChanged::dispatch($order, $status);
    $this->line(strtr('{w_d_changed}', ['{order}' => $order, '{status}' => $status]));
});
''',
    "watch.ts": '''import { readFileSync } from "node:fs";

// {w_c_client}
// {w_c_key}
const key = /^REVERB_APP_KEY=(.*)$/m.exec(readFileSync("shop/.env", "utf8"))?.[1];
const socket = new WebSocket(`ws://localhost:8080/app/${key}?protocol=7`);

socket.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.event === "pusher:connection_established") {
    // {w_c_subscribe}
    const subscribe = { event: "pusher:subscribe", data: { channel: "orders.1001" } };
    socket.send(JSON.stringify(subscribe));
  } else {
    console.log(message.event, message.channel ?? "", message.data ?? "");
  }
});
setTimeout(() => socket.close(), Number(process.argv[2] ?? 3000));
''',
}


def prepare_cache():
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["composer", "create-project", "--no-install", "--no-scripts", "-q",
                        "laravel/laravel", f"{tmp}/skeleton"], check=True)
        subprocess.run(["bash", "-c", "composer require --no-install --no-scripts -q laravel/reverb"],
                       cwd=f"{tmp}/skeleton", env=CLEAN, check=True)
        seed_lock(f"{tmp}/skeleton/composer.lock")


def record(folder, t):
    shop = folder / "shop"
    s = Session(shop)
    s.note(t["w_s_install"])
    s.run("php artisan install:broadcasting --reverb --without-node --no-interaction --no-ansi 2>&1 "
          "| grep -E 'INFO|Reverb' | head -6", shown="php artisan install:broadcasting --reverb")
    s.run("grep -E '^(BROADCAST_CONNECTION|REVERB_)' .env | sed -E 's/(REVERB_APP_(KEY|SECRET|ID))=.*/\\1=…/'",
          shown="grep -E '^(BROADCAST_CONNECTION|REVERB_)' .env")
    s.save(folder / "install.sh")
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    s.run("vendor/bin/pint --quiet app routes")
    s.lines.clear()

    with Server("php artisan reverb:start --no-ansi", shop, "http://localhost:8080/"):
        subprocess.Popen("node watch.ts 2500 > .t1 2>&1", shell=True, cwd=folder, env=CLEAN)
        time.sleep(1)
        s.note(t["w_s_change"])
        s.run("php artisan shop:status 1001 paid")
        s.run("php artisan shop:status 1001 shipped")
        s.save(folder / "watch-2.sh")
        time.sleep(2)
        s.note(t["w_s_watch"])
        s.add("$ node watch.ts")
        s.add((folder / ".t1").read_text())
        s.save(folder / "watch.sh")
        (folder / ".t1").unlink()

    env = shop / ".env"
    env.write_text(env.read_text().replace("APP_DEBUG=true", "APP_DEBUG=false"))
    with Server("php artisan serve --no-ansi", shop, "http://localhost:8000/up"):
        s.note(t["w_s_auth"])
        s.run("curl -s -o /dev/null -w '%{http_code}\\n' -X POST localhost:8000/broadcasting/auth "
              "-d 'socket_id=1234.5678&channel_name=private-orders.1001'")
        s.save(folder / "auth.sh")


prepare_cache()
for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    Session(folder).run("composer create-project laravel/laravel shop --no-interaction -q")
    (folder / "node_modules").symlink_to(B3 / "node_modules")
    record(folder, t)
    (folder / "node_modules").unlink()
    shop = folder / "shop"
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
