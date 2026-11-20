<?php

use App\Http\Controllers\ProductController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('products/{product}/stock', [ProductController::class, 'stock'])
    ->whereNumber('product')
    ->name('products.stock');

Route::apiResource('products', ProductController::class)
    // only numbers: /api/products/abc never reaches the controller
    ->where(['product' => '[0-9]+']);
