<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\OrderController;
use Illuminate\Support\Facades\Route;

Route::controller(AuthController::class)->group(function () {
    Route::post('auth/register', 'register');
    Route::post('auth/login', 'login')->middleware('throttle:login');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', 'logout');
        Route::post('auth/logout-all', 'logoutAll');
        Route::get('me', 'me');
    });
});

Route::middleware('auth:sanctum')
    ->controller(OrderController::class)
    ->group(function () {
        Route::get('orders', 'index');
        Route::get('orders/{order}', 'show');
        Route::get('admin/users', 'users')->middleware('can:admin');
    });
