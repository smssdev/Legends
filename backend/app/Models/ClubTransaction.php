<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** One movement of club money. Written once by App\League\ClubLedger and never changed [PLAN 2.7]. */
class ClubTransaction extends Model
{
    public const UPDATED_AT = null;

    protected $guarded = [];

    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }
}
