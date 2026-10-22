<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Season extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['starts_at' => 'datetime', 'winter_break_on' => 'date'];
    }

    public function league(): BelongsTo
    {
        return $this->belongsTo(League::class);
    }

    /** The last 25% of the league rounds: no new coach comes in [PLAN 2.1, 2.2]. */
    public function inLastQuarter(): bool
    {
        return $this->rounds_played + 1 >= $this->lock_from_round;
    }
}
