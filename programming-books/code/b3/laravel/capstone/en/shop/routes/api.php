<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use App\Http\Middleware\Measure;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Route;

Route::post('auth/register', [AuthController::class, 'register']);
Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');
Route::get('products', [ProductController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('orders', [OrderController::class, 'store']);
    Route::get('orders/{id}', [OrderController::class, 'show'])->whereNumber('id');
});

// ready means the database and Redis both answer; /up only says the process is alive
Route::get('ready', function () {
    try {
        DB::select('SELECT 1');
        Redis::ping();

        return ['ready' => true];
    } catch (Throwable) {
        return response()->json(['ready' => false], 503);
    }
});
Route::get('metrics', [Measure::class, 'metrics']);
