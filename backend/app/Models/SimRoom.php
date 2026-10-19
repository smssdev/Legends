<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SimRoom extends Model
{
    use HasUlids;

    protected $guarded = [];

    public function hostClub(): BelongsTo
    {
        return $this->belongsTo(MasterClub::class, 'host_club_id');
    }

    public function guestClub(): BelongsTo
    {
        return $this->belongsTo(MasterClub::class, 'guest_club_id');
    }
}
