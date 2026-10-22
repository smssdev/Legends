<?php

namespace App\Models;

use App\Support\GameClock;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * A private league [PLAN 2.1, 2.3]. "waiting" until its start time, then "running": from then on its
 * settings are locked. "finished" when the owner chose to end it after a season.
 */
class League extends Model
{
    public const STATUSES = ['waiting', 'running', 'finished'];

    public const END_MODES = ['renew', 'end'];

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'round_times' => 'array',
            'starts_at' => 'datetime',
            'settings_locked_at' => 'datetime',
            'fair_league' => 'boolean',
            'is_dev' => 'boolean',
        ];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function clubs(): HasMany
    {
        return $this->hasMany(Club::class);
    }

    public function seasons(): HasMany
    {
        return $this->hasMany(Season::class);
    }

    /** The season being played, or about to be. */
    public function season(): HasOne
    {
        return $this->hasOne(Season::class)->latestOfMany('number');
    }

    public function memberships(): HasMany
    {
        return $this->hasMany(LeagueMembership::class);
    }

    public function requests(): HasMany
    {
        return $this->hasMany(LeagueJoinRequest::class);
    }

    public function isOwner(?User $user): bool
    {
        return $user !== null && $this->owner_id === $user->id;
    }

    public function isLocked(): bool
    {
        return $this->settings_locked_at !== null;
    }

    /** Time to start: the scheduler (leagues:start) or the dev "start now" button. */
    public function isDue(): bool
    {
        return $this->status === 'waiting' && $this->starts_at->lte(GameClock::now());
    }
}
