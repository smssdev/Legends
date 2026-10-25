<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A round in two time slots [X31]: the league's gap to the second slot, each fixture's slot, the round's one lock
 * time, the night's big match and the reminder; and the squad frozen with each sheet at the lock.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', fn (Blueprint $t) => $t->unsignedSmallInteger('second_slot_minutes')->nullable());
        Schema::table('fixtures', function (Blueprint $t) {
            $t->unsignedTinyInteger('slot')->default(1);
            $t->timestamp('lock_at')->nullable();
            $t->boolean('match_of_day')->default(false);
            $t->timestamp('reminded_at')->nullable();
        });
        Schema::table('fixture_sheets', fn (Blueprint $t) => $t->json('squad')->nullable());
    }

    public function down(): void
    {
        Schema::table('fixture_sheets', fn (Blueprint $t) => $t->dropColumn('squad'));
        Schema::table('fixtures', fn (Blueprint $t) => $t->dropColumn(['slot', 'lock_at', 'match_of_day', 'reminded_at']));
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn('second_slot_minutes'));
    }
};
