<?php

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
        // the rate limits are counted in Redis, shared by every copy of the app; Measure wraps every request, so it also sees the 401s and 429s of the middleware
        $middleware->throttleWithRedis();
        $middleware->append(Measure::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // every error under /api leaves as Problem Details
        $exceptions->render(function (Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                return Problem::from($e)->render($request);
            }
        });
    })->create();
