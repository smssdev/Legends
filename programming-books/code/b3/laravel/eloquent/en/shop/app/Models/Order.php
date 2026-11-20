<?php

namespace App\Models;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Order extends Model
{
    protected $fillable = ['customer_id', 'status'];

    protected function casts(): array
    {
        return ['status' => OrderStatus::class]; // the column holds text; the model gives you the enum
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function products(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'order_items')->withPivot('quantity', 'price');
    }

    // a reusable condition: Order::query()->shipped()
    #[Scope]
    protected function shipped(Builder $query): void
    {
        $query->where('status', OrderStatus::Shipped);
    }

    // The total, computed from the items: piastres, as stored.
    protected function total(): Attribute
    {
        return Attribute::get(fn () => $this->products->sum(
            fn (Product $p) => $p->pivot->quantity * $p->pivot->price,
        ));
    }
}
