<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\DB;

// التمرين 4: زبون الطلب وحده يستمع إلى قناته الخاصة
Broadcast::channel('orders.{orderId}', function (User $user, int $orderId) {
    return DB::table('orders')->where('id', $orderId)->where('user_id', $user->id)->exists();
});
