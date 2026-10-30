<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 26 B3] How the coach looks on the touchline, kept with the account so every screen and Unity's bench show
 * the same: one of the approved characters C1 to C3 (config game.characters.looks).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('coach_look', 4)->default('C1');
        });
    }

    public function down(): void
    {
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('coach_look'));
    }
};
