<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

class SimMatch extends Model
{
    use HasUlids;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'setup' => 'array', 'control' => 'array', 'state' => 'array', 'ticks' => 'array',
            'pending' => 'array', 'applied' => 'array', 'ball' => 'array',
        ];
    }
}
