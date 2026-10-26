<?php

namespace App\Models;

use App\Data\ClubLogo;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MasterClub extends Model
{
    protected $guarded = [];

    /** Every club sent to a screen carries its real logo where it has one [UP3]. */
    protected $appends = ['logo'];

    protected function logo(): Attribute
    {
        return Attribute::get(fn () => isset($this->attributes['name'], $this->attributes['league_name'])
            ? ClubLogo::path($this->attributes['league_name'], $this->attributes['name']) : null);
    }

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
