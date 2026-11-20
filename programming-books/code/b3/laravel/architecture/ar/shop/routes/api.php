<?php

use App\Orders\Http\PlaceOrderController;
use Illuminate\Support\Facades\Route;

Route::post('orders', PlaceOrderController::class);
