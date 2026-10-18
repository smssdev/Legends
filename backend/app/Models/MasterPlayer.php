<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MasterPlayer extends Model
{
    protected $guarded = [];

    public function club(): BelongsTo
    {
        return $this->belongsTo(MasterClub::class, 'master_club_id');
    }
}
