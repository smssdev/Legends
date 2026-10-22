<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** A league's own copy of a real club [PLAN 4]. No user = a bot runs it. */
class Club extends Model
{
    protected $guarded = [];

    public function league(): BelongsTo
    {
        return $this->belongsTo(League::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function master(): BelongsTo
    {
        return $this->belongsTo(MasterClub::class, 'master_club_id');
    }

    public function players(): HasMany
    {
        return $this->hasMany(Player::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(ClubTransaction::class);
    }

    public function isBot(): bool
    {
        return $this->user_id === null;
    }
}
