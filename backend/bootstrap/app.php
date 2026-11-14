<?php

use App\Http\Errors\ApiErrors;
use App\Http\Middleware\AdminOnly;
use App\Http\Middleware\CompressJson;
use App\Http\Middleware\LeagueActivity;
use App\Http\Middleware\NotSuspended;
use App\Http\Middleware\RecordActivity;
use App\Http\Middleware\SecurityHeaders;
use App\Http\Middleware\SetLocale;
use App\Http\Middleware\SimulatorEnabled;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api/v1',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // The web app signs in with Sanctum's session cookie; the app sends a Bearer token.
        $middleware->statefulApi();
        // [Sprint 51 B2] The browser's CSP reports carry no XSRF token.
        // [Sprint 66 B1] And the devices' errors: no session, nothing it could change for anyone.
        $middleware->validateCsrfTokens(except: ['api/v1/csp-report', 'api/v1/client-errors']);
        $middleware->alias(['simulator' => SimulatorEnabled::class, 'league.activity' => LeagueActivity::class, 'admin' => AdminOnly::class]);
        // Every signed-in request counts for the activity indicators of the admin panel [Sprint 37].
        $middleware->appendToGroup('api', RecordActivity::class);
        // [UP2] The server's words in the coach's language.
        $middleware->appendToGroup('api', SetLocale::class);
        // Security headers on every answer, and big JSON gzipped [E1].
        $middleware->append(SecurityHeaders::class);
        $middleware->appendToGroup('api', CompressJson::class);
        // [Sprint 21 E7.3] A suspended account is told why and kept out.
        $middleware->appendToGroup('api', NotSuspended::class);
        // Whose X-Forwarded-* headers count (https, the public host, the player's address): this machine by default; on
        // our server Docker's network, where the server's nginx comes from [Sprint 52 B8] (start.sh, compose.yml), as a
        // comma list of addresses or ranges. A Codespace sets TRUSTED_PROXIES=* (.devcontainer/env.sh).
        $proxies = (string) env('TRUSTED_PROXIES', '');
        $middleware->trustProxies(at: $proxies === '*' ? '*' : (array_values(array_filter(array_map('trim', explode(',', $proxies)))) ?: ['127.0.0.1', '::1']));
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(fn (Throwable $e, Request $request) => ApiErrors::render($e, $request));
    })->create();
