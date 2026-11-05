<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 43 A3] The World Cup of 48 (Hamza's decision 2026-11-05): the best third-placed teams of the groups go on to
 * the knockout with the first two. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $t) {
            $t->unsignedTinyInteger('best_thirds')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn('best_thirds'));
    }
};
