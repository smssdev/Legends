<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A club's team sheet [PLAN 2.15, 2.16]: its lineup (a formation from App\League\FormationBook or one of
 * its own), who stands in each slot and on the bench, up to 3 custom formations, and the set-piece takers.
 * A club without a row is picked automatically ("تحسين"), as the bots are.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lineups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->unique()->constrained()->cascadeOnDelete();
            // A book name ("4-3-3A") or "custom:N" for the club's own formation N.
            $table->string('formation', 16);
            $table->timestamps();
        });

        Schema::create('lineup_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lineup_id')->constrained()->cascadeOnDelete();
            // 0..10 the starters in the formation's slot order (0 = goalkeeper), 11.. the bench.
            $table->unsignedTinyInteger('position');
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();

            $table->unique(['lineup_id', 'position']);
            $table->unique(['lineup_id', 'player_id']);
        });

        Schema::create('custom_formations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('number');
            $table->string('name', 30);
            // The ten outfield cells, [row, column]: rows def, dm, am, att; columns 1 (right) to 5 (left).
            $table->json('cells');
            $table->timestamps();

            $table->unique(['club_id', 'number']);
        });

        Schema::create('set_piece_takers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->unique()->constrained()->cascadeOnDelete();
            // Empty = chosen automatically from the starters [PLAN 2.16].
            foreach (['captain_id', 'penalty_id', 'free_kick_id', 'corner_id'] as $col) {
                $table->foreignId($col)->nullable()->constrained('players')->nullOnDelete();
            }
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('set_piece_takers');
        Schema::dropIfExists('custom_formations');
        Schema::dropIfExists('lineup_slots');
        Schema::dropIfExists('lineups');
    }
};
