<?php

use App\Http\Errors\ApiErrors;
use App\Http\Middleware\AdminOnly;
use App\Http\Middleware\LeagueActivity;
use App\Http\Middleware\RecordActivity;
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
        $middleware->alias(['simulator' => SimulatorEnabled::class, 'league.activity' => LeagueActivity::class, 'admin' => AdminOnly::class]);
        // Every signed-in request counts for the activity indicators of the admin panel [Sprint 37].
        $middleware->appendToGroup('api', RecordActivity::class);
        // The public link (Tailscale Funnel) reaches the game through tailscaled on this machine: trust only
        // that local hop's X-Forwarded-* headers, so links and cookies are https on the public address.
        $middleware->trustProxies(at: ['127.0.0.1', '::1']);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(fn (Throwable $e, Request $request) => ApiErrors::render($e, $request));
    })->create();
