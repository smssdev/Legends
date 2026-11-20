<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

use Monolog\Formatter\FormatterInterface;
use Monolog\Handler\StreamHandler;
use Monolog\Level;
use Monolog\Logger;
use Monolog\LogRecord;

// one JSON object per line: machines can search it, people can still read it
final class JsonLines implements FormatterInterface
{
    public function format(LogRecord $record): string
    {
        $line = ['time' => $record->datetime->format('H:i:s.v'),
            'level' => strtolower($record->level->name)] + $record->extra
            + ['msg' => $record->message] + $record->context;

        return json_encode($line, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)."\n";
    }

    public function formatBatch(array $records): string
    {
        return implode('', array_map($this->format(...), $records));
    }
}

$start = hrtime(true);
$port = (int) $_SERVER['SERVER_PORT'];
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// the trace id comes from the caller's traceparent header, or starts here
$trace = explode('-', $_SERVER['HTTP_TRACEPARENT'] ?? '')[1] ?? bin2hex(random_bytes(16));

$handler = new StreamHandler('php://stderr', Level::Info);
$handler->setFormatter(new JsonLines);
$log = new Logger('shop', [$handler]);
$log->pushProcessor(fn (LogRecord $r) => $r->with(extra: ['service' => "shop:$port", 'trace' => $trace]));

$db = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 1,
]);
$redis = new Predis\Client('tcp://localhost:6379');

function reply(int $status, array $body): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
}

$quiet = in_array($path, ['/health', '/ready', '/metrics'], true);
$route = $path;
if (! $quiet) {
    // only what is useful: the method and the address, not every header
    $log->info('incoming request', ['req' => ['method' => $method, 'url' => $_SERVER['REQUEST_URI']]]);
}

try {
    if (preg_match('#^/products/(\d+)$#', $path, $m)) {
        $route = '/products/:id';
        $query = $db()->prepare('SELECT id, name, price FROM products WHERE id = ?');
        $query->execute([$m[1]]);
        $product = $query->fetch(PDO::FETCH_ASSOC);
        $product ? reply(200, $product) : reply(404, ['title' => 'Not found']);
    } elseif (preg_match('#^/stock/(\d+)$#', $path, $m)) {
        $route = '/stock/:id';
        $query = $db()->prepare('SELECT stock FROM products WHERE id = ?');
        $query->execute([$m[1]]);
        reply(200, ['stock' => (int) $query->fetchColumn()]);
    } elseif ($path === '/checkout') {
        $log->info('checkout started');
        // the next service gets the same trace id, so its logs join this request's
        $span = bin2hex(random_bytes(8));
        $context = stream_context_create(['http' => ['header' => "traceparent: 00-$trace-$span-01"]]);
        $stock = json_decode(file_get_contents('http://localhost:8001/stock/1', false, $context), true)['stock'];
        $log->info('stock checked', ['stock' => $stock]);
        reply(200, ['ok' => $stock > 0]);
    } elseif ($path === '/boom') {
        throw new RuntimeException('payment provider timed out');
    } elseif ($path === '/health') {
        // alive: the process answers (restart it if not)
        reply(200, ['status' => 'ok']);
    } elseif ($path === '/ready') {
        // ready: it can do its job, so send it traffic (stop sending if not)
        try {
            $db()->query('SELECT 1');
            reply(200, ['status' => 'ready']);
        } catch (PDOException) {
            reply(503, ['status' => 'database unavailable']);
        }
    } elseif ($path === '/metrics') {
        header('Content-Type: text/plain; version=0.0.4');
        echo metrics($redis);
    } else {
        reply(404, ['title' => 'Not found']);
    }
} catch (Throwable $e) {
    $log->error($e->getMessage(), ['err' => ['type' => $e::class, 'at' => basename($e->getFile()).':'.$e->getLine()]]);
    reply(500, ['title' => 'Server error', 'trace' => $trace]);
}

if (! $quiet) {
    $ms = (hrtime(true) - $start) / 1e6;
    $log->info('request completed', ['res' => ['status' => http_response_code()], 'responseTime' => round($ms, 2)]);
}

// after the response is sent: count it, without making the client wait
register_shutdown_function(function () use ($redis, $method, $route, $start, $quiet) {
    if ($quiet) {
        return;
    }
    // PHP forgets everything after each request: the counters live in Redis
    $seconds = (hrtime(true) - $start) / 1e9;
    $redis->hincrby('metrics:requests', "$method $route ".http_response_code(), 1);
    foreach ([0.01, 0.05, 0.1, 0.5, 1, '+Inf'] as $le) {
        if ($le === '+Inf' || $seconds <= $le) {
            $redis->hincrby('metrics:duration', "$route $le", 1);
        }
    }
    $redis->hincrbyfloat('metrics:duration', "$route sum", $seconds);
});

function metrics(Predis\Client $redis): string
{
    $out = "# HELP http_requests_total Requests by route and status\n# TYPE http_requests_total counter\n";
    foreach ($redis->hgetall('metrics:requests') as $key => $count) {
        [$method, $route, $status] = explode(' ', $key);
        $out .= "http_requests_total{method=\"$method\",route=\"$route\",status=\"$status\"} $count\n";
    }
    $out .= "# HELP http_request_duration_seconds How long requests took\n";
    $out .= "# TYPE http_request_duration_seconds histogram\n";
    $fields = $redis->hgetall('metrics:duration');
    $order = function (string $key) {
        [$route, $le] = explode(' ', $key);

        return [$route, $le === 'sum', $le === '+Inf' ? INF : (float) $le];
    };
    uksort($fields, fn ($a, $b) => $order($a) <=> $order($b));
    foreach ($fields as $key => $value) {
        [$route, $le] = explode(' ', $key);
        $out .= $le === 'sum'
            ? "http_request_duration_seconds_sum{route=\"$route\"} $value\n"
            : "http_request_duration_seconds_bucket{route=\"$route\",le=\"$le\"} $value\n";
    }

    return $out;
}
