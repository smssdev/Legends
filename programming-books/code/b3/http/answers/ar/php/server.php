<?php
// واجهة متجر Bit بلغة PHP وحدها.
// التشغيل: php -S localhost:8000 server.php

// تطبيق الويب المسموح له باستدعاء هذه الواجهة من المتصفح
const ORIGINS = ['http://localhost:5173'];
const MAX_BODY = 1024; // bytes
const DATA = __DIR__ . '/products.json';

// لا تخبر المهاجمين بإصدار PHP الذي يعمل هنا
header_remove('X-Powered-By');
$start = hrtime(true);
register_shutdown_function(function () use ($start) {
    $ms = intdiv(hrtime(true) - $start, 1_000_000);
    $status = http_response_code();
    $request = "{$_SERVER['REQUEST_METHOD']} {$_SERVER['REQUEST_URI']}";
    error_log("$request $status {$ms}ms");
});

function send(int $status, mixed $body = null, array $headers = []): void
{
    $text = $body === null ? '' : json_encode($body, JSON_UNESCAPED_UNICODE);
    header('Vary: Accept-Encoding');
    $accepts = $_SERVER['HTTP_ACCEPT_ENCODING'] ?? '';
    if (strlen($text) >= 100 && preg_match('/\bgzip\b/', $accepts)) {
        $text = gzencode($text);
        header('Content-Encoding: gzip');
    }
    http_response_code($status);
    if ($text === '') {
        header('Content-Type:'); // لا محتوى، فلا نوع
    } else {
        header('Content-Type: application/json; charset=utf-8');
    }
    // الدالة strlen تعدّ البايتات لا الحروف
    header('Content-Length: ' . strlen($text));
    foreach ($headers as $name => $value) {
        header("$name: $value");
    }
    echo $text;
}

function fail(int $status, string $code, string $message,
              array $extra = [], array $headers = []): void
{
    $error = ['code' => $code, 'message' => $message] + $extra;
    send($status, ['error' => $error], $headers);
}

function products(): array
{
    // تنسى PHP كل شيء حين ينتهي الطلب، لذلك تعيش المنتجات في ملف.
    return json_decode(file_get_contents(DATA), true);
}

function handle(): void
{
    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $origin = $_SERVER['HTTP_ORIGIN'] ?? null;
    if ($origin && in_array($origin, ORIGINS, true)) {
        header("Access-Control-Allow-Origin: $origin");
        header('Vary: Origin');
    }

    if ($method === 'OPTIONS') {
        send(204, null, [
            'Access-Control-Allow-Methods' => 'GET, POST',
            'Access-Control-Allow-Headers' => 'Content-Type',
            'Access-Control-Max-Age' => '600',
        ]);
        return;
    }

    if ($path === '/products') {
        if ($method === 'GET' || $method === 'HEAD') {
            $max = (int) ($_GET['max_price'] ?? PHP_INT_MAX);
            $cheap = array_filter(products(), fn ($p) => $p['price'] <= $max);
            $list = array_values($cheap);
            $hash = md5(json_encode($list, JSON_UNESCAPED_UNICODE));
            $etag = '"' . substr($hash, 0, 16) . '"';
            if (($_SERVER['HTTP_IF_NONE_MATCH'] ?? null) === $etag) {
                send(304, null, ['ETag' => $etag]);
                return;
            }
            send(200, $list, ['ETag' => $etag, 'Cache-Control' => 'no-cache']);
            return;
        }
        if ($method === 'POST') {
            create();
            return;
        }
        fail(405, 'method_not_allowed', 'استخدم GET أو POST هنا', [],
             ['Allow' => 'GET, HEAD, POST']);
        return;
    }

    if (preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'DELETE') {
        $file = fopen(DATA, 'r+');
        flock($file, LOCK_EX);
        $list = json_decode(stream_get_contents($file), true);
        $id = (int) $m[1];
        $left = array_values(array_filter($list, fn ($p) => $p['id'] !== $id));
        if (count($left) < count($list)) {
            ftruncate($file, 0);
            rewind($file);
            fwrite($file, json_encode($left, JSON_UNESCAPED_UNICODE));
        }
        flock($file, LOCK_UN);
        fclose($file);
        if (count($left) === count($list)) {
            fail(404, 'not_found', 'لا يوجد منتج بهذا الرقم');
            return;
        }
        send(204);
        return;
    }

    if (preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'GET') {
        foreach (products() as $product) {
            if ($product['id'] === (int) $m[1]) {
                send(200, $product);
                return;
            }
        }
        fail(404, 'not_found', 'لا يوجد منتج بهذا الرقم');
        return;
    }
    fail(404, 'not_found', 'لا شيء هنا');
}

function create(): void
{
    if (!str_starts_with($_SERVER['CONTENT_TYPE'] ?? '', 'application/json')) {
        fail(415, 'unsupported_media_type', 'أرسل JSON');
        return;
    }
    if ((int) ($_SERVER['CONTENT_LENGTH'] ?? 0) > MAX_BODY) {
        fail(413, 'too_large', 'الحد الأقصى 1 KB');
        return;
    }
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
        fail(400, 'bad_json', 'المحتوى ليس JSON صالحاً');
        return;
    }

    $name = $data['name'] ?? null;
    $price = $data['price'] ?? null;
    $errors = [];
    if (!is_string($name) || trim($name) === '') {
        $errors['name'] = 'مطلوب';
    }
    if (!is_int($price) || $price <= 0) {
        $errors['price'] = 'عدد صحيح من القروش أكبر من 0';
    }
    if ($errors) {
        fail(422, 'invalid', 'راجع الحقول', ['fields' => $errors]);
        return;
    }

    $file = fopen(DATA, 'r+');
    flock($file, LOCK_EX); // لا يجوز أن يكتب طلبان في الملف في الوقت نفسه
    $list = json_decode(stream_get_contents($file), true);
    $next = __DIR__ . '/next-id.txt'; // لا يُعاد استخدامه أبداً، حتى بعد الحذف
    $id = (int) file_get_contents($next); // يبدأ الملف بالرقم 4
    file_put_contents($next, $id + 1);
    $product = [
        'id' => $id,
        'name' => trim($name),
        'price' => $price,
    ];
    $list[] = $product;
    ftruncate($file, 0);
    rewind($file);
    fwrite($file, json_encode($list, JSON_UNESCAPED_UNICODE));
    flock($file, LOCK_UN);
    fclose($file);
    send(201, $product, ['Location' => "/products/{$product['id']}"]);
}

try {
    handle();
} catch (Throwable $error) {
    error_log((string) $error); // التفاصيل تبقى في سجل الخادم
    if (!headers_sent()) {
        fail(500, 'server_error', 'حدث خطأ عندنا');
    }
}
