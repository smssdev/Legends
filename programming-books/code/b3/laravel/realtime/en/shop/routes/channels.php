<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\DB;

// exercise 4: only the order's customer may listen to its private channel
Broadcast::channel('orders.{orderId}', function (User $user, int $orderId) {
    return DB::table('orders')->where('id', $orderId)->where('user_id', $user->id)->exists();
});
