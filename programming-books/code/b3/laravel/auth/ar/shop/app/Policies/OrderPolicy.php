<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class OrderPolicy
{
    public function view(User $user, Order $order): Response
    {
        // طلب غيرك «غير موجود» لا «غير مسموح»: لا يُكشف وجوده
        return $user->id === $order->user_id || $user->isAdmin()
            ? Response::allow()
            : Response::denyAsNotFound();
    }
}
