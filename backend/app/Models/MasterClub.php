<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MasterClub extends Model
{
    protected $guarded = [];

    public function players(): HasMany
    {
        return $this->hasMany(MasterPlayer::class);
    }

    /** Strength for display: the average of the best 18, one decimal. */
    public function strength(): float
    {
        return $this->strength_cp / 100;
    }
}
