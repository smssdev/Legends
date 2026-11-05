<?php

use App\League\ClubStrength;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

// [X98] Every club's strength from its squad as it is now: until this, the number stayed as the league began whatever
// was bought, sold or trained. Only clubs.strength_snapshot changes; nothing is removed.
return new class extends Migration
{
    public function up(): void
    {
        foreach (DB::table('leagues')->pluck('id') as $leagueId) {
            ClubStrength::refreshLeague((int) $leagueId);
        }
    }

    public function down(): void
    {
        // Nothing to undo: the strength is recomputed from the squads.
    }
};
