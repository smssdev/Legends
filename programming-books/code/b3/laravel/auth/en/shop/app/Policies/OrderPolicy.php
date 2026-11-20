<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class OrderPolicy
{
    public function view(User $user, Order $order): Response
    {
        // another customer's order is 'not found': its existence stays secret
        return $user->id === $order->user_id || $user->isAdmin()
            ? Response::allow()
            : Response::denyAsNotFound();
    }
}
