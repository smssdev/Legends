<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** A coach in a league for one season, from taking a club until leaving it [PLAN 2.1, 2.2]. */
class LeagueMembership extends Model
{
    public const LEFT_REASONS = ['resigned', 'absent', 'kicked', 'deleted'];

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'joined_at' => 'datetime', 'left_at' => 'datetime', 'last_active_at' => 'datetime', 'absence_warned_at' => 'datetime',
            'vacation_from' => 'datetime', 'vacation_until' => 'datetime',
        ];
    }

    public function league(): BelongsTo
    {
        return $this->belongsTo(League::class);
    }

    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
