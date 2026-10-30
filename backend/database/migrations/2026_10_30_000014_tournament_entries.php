<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [X68] How a tournament's teams find their coaches: each coach picks his (the organizer approves, as in a league),
 * the live draw shares them among the players who entered, or the organizer names each team's coach. The entries
 * keep who entered, the team the draw gave him and the ball it came on.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $t) {
            $t->string('entry_mode', 8)->nullable();
        });
        Schema::create('tournament_entries', function (Blueprint $t) {
            $t->id();
            $t->foreignId('league_id')->constrained()->cascadeOnDelete();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('club_id')->nullable()->constrained()->nullOnDelete();
            $t->unsignedSmallInteger('position')->nullable();
            $t->timestamp('created_at')->nullable();
            $t->unique(['league_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tournament_entries');
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn('entry_mode'));
    }
};
