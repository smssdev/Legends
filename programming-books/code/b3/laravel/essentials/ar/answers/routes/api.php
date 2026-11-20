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
    // الأرقام فقط: /api/products/abc لا يصل إلى المتحكم أبداً
    ->where(['product' => '[0-9]+']);
