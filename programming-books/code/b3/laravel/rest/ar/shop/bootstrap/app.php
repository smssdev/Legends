<?php

use App\Http\Middleware\UnescapedJson;
use App\Http\Problems;
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
        $middleware->api(append: [UnescapedJson::class]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Every error in the API becomes Problem Details;
        // صفحات الويب تحتفظ بصفحات الخطأ المعتادة في Laravel.
        $exceptions->render(function (Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                return Problems::from($e)->render($request);
            }
        });
    })->create();
