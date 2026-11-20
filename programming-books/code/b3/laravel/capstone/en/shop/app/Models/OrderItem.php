<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['product_id', 'quantity', 'price'])]
class OrderItem extends Model
{
    public $timestamps = false;

    public $incrementing = false;

    protected $primaryKey = null;
}
