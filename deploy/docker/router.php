<?php

// The web server's router (php -S, start.sh) [X45]. PHP's built-in server takes every request on one of a
// few workers, so what does not need Laravel never reaches it:
// - The built files (the hashed /assets/, the logos, the brand, the art) go out with a year's cache and, when the
//   browser takes it, their gzip copy made at build time (Dockerfile): one download per version, a third the size.
// - A page of the Vue app (any other GET that is not the API's or Laravel's own) is index.html, never cached, so a new
//   version is picked up at once, without booting Laravel or touching the session.
// - Everything else is Laravel (public/index.php), as Laravel's own server.php does.

$public = realpath(__DIR__.'/public') ?: __DIR__.'/public';
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/');
$file = realpath($public.$uri);

// Laravel's own paths: the API, sign-in, broadcasting, the links opened from emails and WhatsApp, the health check.
const LARAVEL = ['/api/', '/sanctum/', '/broadcasting/', '/auth/google/', '/email/verify/', '/join/', '/up'];

const TYPES = ['js' => 'text/javascript; charset=utf-8', 'mjs' => 'text/javascript; charset=utf-8', 'css' => 'text/css; charset=utf-8',
    'json' => 'application/json; charset=utf-8', 'svg' => 'image/svg+xml', 'webp' => 'image/webp', 'png' => 'image/png',
    'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'ico' => 'image/x-icon', 'woff2' => 'font/woff2', 'woff' => 'font/woff',
    'webmanifest' => 'application/manifest+json', 'txt' => 'text/plain; charset=utf-8', 'html' => 'text/html; charset=utf-8',
    'wasm' => 'application/wasm', 'data' => 'application/octet-stream'];

// Files whose name or folder changes with their content: kept for a year.
const LASTING = ['/assets/', '/logos/', '/brand/', '/art/', '/unity/'];

function send(string $path, string $cache): void
{
    $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    header('Content-Type: '.(TYPES[$ext] ?? (mime_content_type($path) ?: 'application/octet-stream')));
    header('Cache-Control: '.$cache);
    header('Vary: Accept-Encoding');
    $zip = $path.'.gz';
    if (str_contains($_SERVER['HTTP_ACCEPT_ENCODING'] ?? '', 'gzip') && is_file($zip)) {
        header('Content-Encoding: gzip');
        $path = $zip;
    }
    header('Content-Length: '.filesize($path));
    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        readfile($path);
    }
}

// No broadcasting server here (BROADCAST_CONNECTION=log): the browsers' WebSocket tries (/app/<key>) get a quick no,
// never Laravel or the app's page, and fall back to asking the API.
if (str_starts_with($uri, '/app/')) {
    http_response_code(404);

    return true;
}

$laravel = false;
foreach (LARAVEL as $prefix) {
    if ($uri === rtrim($prefix, '/') || str_starts_with($uri, $prefix)) {
        $laravel = true;
        break;
    }
}

if (! $laravel && $uri !== '/' && $file !== false && str_starts_with($file, $public.'/') && is_file($file) && ! str_ends_with($file, '.php')) {
    $lasting = false;
    foreach (LASTING as $prefix) {
        $lasting = $lasting || str_starts_with($uri, $prefix);
    }
    // Media with ranges (the commentary's audio) and anything not listed: PHP's own server, which answers ranges.
    if (! isset(TYPES[strtolower(pathinfo($file, PATHINFO_EXTENSION))])) {
        return false;
    }
    send($file, $lasting ? 'public, max-age=31536000, immutable' : 'public, max-age=300');

    return true;
}

if (! $laravel && in_array($_SERVER['REQUEST_METHOD'], ['GET', 'HEAD'], true) && is_file($public.'/index.html')) {
    send($public.'/index.html', 'no-cache');

    return true;
}

require $public.'/index.php';
