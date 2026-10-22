<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** A league's own copy of a real player. Attributes come from master_players plus training_bonus [PLAN 4]. */
class Player extends Model
{
    protected $guarded = [];

    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }

    public function master(): BelongsTo
    {
        return $this->belongsTo(MasterPlayer::class, 'master_player_id');
    }
}
