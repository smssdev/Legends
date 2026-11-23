<?php

// The web server's router (php -S, start.sh) [X45]. PHP's built-in server takes every request on one of a
// few workers, so what does not need Laravel never reaches it:
// - The built files (the hashed /assets/, the logos, the brand, the art) go out with a year's cache and, when the
//   browser takes it, their Brotli copy made at build time (Dockerfile), else their gzip one: one download per
//   version, a quarter to a third the size. [Sprint 30 Q12] Brotli is some 15-25% smaller than gzip on the JS.
// - A page of the Vue app (any other GET that is not the API's or Laravel's own) is index.html, never cached, so a new
//   version is picked up at once, without booting Laravel or touching the session.
// - Everything else is Laravel (public/index.php), as Laravel's own server.php does.

$public = realpath(__DIR__.'/public') ?: __DIR__.'/public';

// [Sprint 51 B1] The same security headers as Laravel's answers (App\Http\Security\SecurityPolicy, plain PHP): the
// game's page and its files leave from here, before Laravel, and went out without them.
require_once __DIR__.'/app/Http/Security/SecurityPolicy.php';
// [Sprint 75 W8] Which addresses are the app's pages (the rest answer 404).
require_once __DIR__.'/app/Support/AppPages.php';

/** The security headers, HSTS when the request came over HTTPS (nginx in front sets X-Forwarded-Proto). */
function security_headers(?string $html = null): void
{
    $secure = ($_SERVER['HTTPS'] ?? '') === 'on' || strtolower($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https';
    $hashes = $html === null ? [] : App\Http\Security\SecurityPolicy::inlineScriptHashes($html);
    foreach (App\Http\Security\SecurityPolicy::headers($secure, $hashes) as $name => $value) {
        header($name.': '.$value);
    }
    header_remove('X-Powered-By');
}
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/');

// [X70] One address for the game: a request on another public name (the old srv2100776.hstgr.cloud, www.gamelegendmanager.online)
// goes to the site's own (APP_URL, from PUBLIC_URL), permanently, the same path and query. The machine's own names
// (localhost, 127.0.0.1, an IP: the health checks inside the server) are left alone.
$site = parse_url((string) getenv('APP_URL'), PHP_URL_HOST);
$host = strtolower(preg_replace('/:\d+$/', '', $_SERVER['HTTP_HOST'] ?? ''));
if ($site && $host !== '' && $host !== strtolower($site) && $host !== 'localhost' && filter_var($host, FILTER_VALIDATE_IP) === false) {
    header('Location: https://'.$site.$_SERVER['REQUEST_URI'], true, 301);

    return true;
}
$file = realpath($public.$uri);

// Laravel's own paths: the API, sign-in, broadcasting, the links opened from emails and WhatsApp, the health check.
// [X57] And Google's /ads.txt, written from the AdSense account set on the server.
// [Sprint 62 B1] And Android's /.well-known/assetlinks.json, from the release key's fingerprint set on the server.
const LARAVEL = ['/api/', '/sanctum/', '/broadcasting/', '/auth/google/', '/email/verify/', '/join/', '/up', '/ads.txt', '/.well-known/'];

const TYPES = ['js' => 'text/javascript; charset=utf-8', 'mjs' => 'text/javascript; charset=utf-8', 'css' => 'text/css; charset=utf-8',
    'json' => 'application/json; charset=utf-8', 'svg' => 'image/svg+xml', 'webp' => 'image/webp', 'png' => 'image/png',
    'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'ico' => 'image/x-icon', 'woff2' => 'font/woff2', 'woff' => 'font/woff',
    'webmanifest' => 'application/manifest+json', 'txt' => 'text/plain; charset=utf-8', 'xml' => 'application/xml; charset=utf-8', 'html' => 'text/html; charset=utf-8',
    'wasm' => 'application/wasm', 'data' => 'application/octet-stream',
    // [Sprint 15 D1] The Android app bundled with the site (web/public/downloads), downloaded as a file.
    'apk' => 'application/vnd.android.package-archive'];

// Files whose name or folder changes with their content: kept for a year.
const LASTING = ['/assets/', '/unity/', '/crests/'];
// [Sprint 58 B3, W-P08] Fixed names whose content may change (a club's logo, the brand, the art, the characters, the
// sounds, the commentary): an hour, then asked again with their ETag (a 304 when unchanged). They were a year and
// immutable, so a new logo never reached anyone who had seen the old one.
const HOURLY = ['/logos/', '/brand/', '/art/', '/characters/', '/sounds/', '/commentary/'];

function send(string $path, string $cache): void
{
    $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    security_headers($ext === 'html' ? (string) file_get_contents($path) : null);
    header('Content-Type: '.(TYPES[$ext] ?? (mime_content_type($path) ?: 'application/octet-stream')));
    header('Cache-Control: '.$cache);
    header('Vary: Accept-Encoding');
    // The file's own tag (its size and time): a browser that has it gets a 304 and nothing more.
    $etag = '"'.dechex((int) filemtime($path)).'-'.dechex((int) filesize($path)).'"';
    header('ETag: '.$etag);
    if (trim((string) ($_SERVER['HTTP_IF_NONE_MATCH'] ?? '')) === $etag) {
        http_response_code(304);

        return;
    }
    if ($ext === 'apk') {
        header('Content-Disposition: attachment; filename="'.basename($path).'"');
    }
    $accepts = $_SERVER['HTTP_ACCEPT_ENCODING'] ?? '';
    if (str_contains($accepts, 'br') && is_file($path.'.br')) {
        header('Content-Encoding: br');
        $path .= '.br';
    } elseif (str_contains($accepts, 'gzip') && is_file($path.'.gz')) {
        header('Content-Encoding: gzip');
        $path .= '.gz';
    }
    header('Content-Length: '.filesize($path));
    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        readfile($path);
    }
}

// No broadcasting server here (BROADCAST_CONNECTION=log): the browsers' WebSocket tries (/app/<key>) get a quick no,
// never Laravel or the app's page, and fall back to asking the API.
if (str_starts_with($uri, '/app/')) {
    security_headers();
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
    $lasting = $hourly = false;
    foreach (LASTING as $prefix) {
        $lasting = $lasting || str_starts_with($uri, $prefix);
    }
    foreach (HOURLY as $prefix) {
        $hourly = $hourly || str_starts_with($uri, $prefix);
    }
    // Media with ranges (the commentary's audio) and anything not listed: PHP's own server, which answers ranges.
    if (! isset(TYPES[strtolower(pathinfo($file, PATHINFO_EXTENSION))])) {
        return false;
    }
    // [Sprint 30 Q12] The fonts (fixed files, not hashed) a month; the rest five minutes.
    send($file, $lasting ? 'public, max-age=31536000, immutable' : ($hourly ? 'public, max-age=3600' : (str_starts_with($uri, '/fonts/') ? 'public, max-age=2592000' : 'public, max-age=300')));

    return true;
}

if (! $laravel && in_array($_SERVER['REQUEST_METHOD'], ['GET', 'HEAD'], true) && is_file($public.'/index.html')) {
    // [SEO] A public page built with its own tags (web/scripts/seo.mjs: /register/index.html...) goes out as itself.
    // [Sprint 75 W9, WEB-09] And in English with ?lang=en (its index.en.html beside it): the crawlers and the share
    // previews that run no script read the English title, description and language, not the Arabic ones.
    $base = $file !== false && str_starts_with($file.'/', $public.'/') ? $file : $public;
    $english = ($_GET['lang'] ?? '') === 'en';
    $page = $public.'/'.($english && is_file($public.'/index.en.html') ? 'index.en.html' : 'index.html');
    foreach ($english ? ['index.en.html', 'index.html'] : ['index.html'] as $name) {
        if (is_file($base.'/'.$name)) {
            $page = $base.'/'.$name;
            break;
        }
    }
    // [Sprint 75 W8, WEB-08] An address that is no page of the app (web/public/app-routes.json) still shows the app's
    // «not found», but answers 404 and noindex: Google and the monitors see a broken link as broken. Without the list
    // (a build before it), every address is a page, as before.
    $routes = json_decode((string) @file_get_contents($public.'/app-routes.json'), true)['paths'] ?? null;
    $found = ! is_array($routes) || App\Support\AppPages::known($uri, $routes);
    // [X57] With the owner's AdSense account set (ADSENSE_CLIENT), every page carries Google's code in its head, as
    // AdSense asks to check the site; the Vue app (src/lib/adsense.ts) finds it there and places the units.
    $client = (string) getenv('ADSENSE_CLIENT');
    $adsense = preg_match('/^ca-pub-\d{10,20}$/', $client) === 1;
    if ($adsense || ! $found) {
        $html = (string) file_get_contents($page);
        if (! $found) {
            $html = preg_replace('/<meta name="robots" content="[^"]*" \/>/', '<meta name="robots" content="noindex" />', $html, 1, $count) ?? $html;
            if ($count === 0) {
                $html = str_replace('</head>', '<meta name="robots" content="noindex" /></head>', $html);
            }
            http_response_code(404);
        }
        if ($adsense) {
            $test = filter_var(getenv('ADSENSE_TEST'), FILTER_VALIDATE_BOOLEAN) ? ' data-adbreak-test="on"' : '';
            $html = str_replace('</head>', '<meta name="google-adsense-account" content="'.$client.'" />'
                .'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='.$client.'" crossorigin="anonymous" data-ad-frequency-hint="30s"'.$test.'></script></head>',
                $html);
        }
        security_headers($html);
        header('Content-Type: text/html; charset=utf-8');
        header('Cache-Control: no-cache');
        header('Content-Length: '.strlen($html));
        if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
            echo $html;
        }

        return true;
    }
    send($page, 'no-cache');

    return true;
}

require $public.'/index.php';
