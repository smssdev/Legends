<?php

use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use App\Http\Middleware\Idempotent;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::apiResource('products', ProductController::class)
        ->only(['index', 'show', 'update']);

    Route::controller(OrderController::class)->group(function () {
        Route::post('orders', 'store')->middleware(Idempotent::class)->name('orders.store');
        Route::get('orders/{order}', 'show')->name('orders.show');
        Route::post('orders/{order}/cancel', 'cancel')->name('orders.cancel');
    });
});
