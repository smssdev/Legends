<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 34 V1] A club's change kit: its shirt colour and pattern (null: none set, the screens pick white or navy),
 * worn when its first kit is too close to the other side's. Set in the data editor; every league reads it. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('master_clubs', function (Blueprint $table) {
            $table->string('away_color', 7)->nullable();
            $table->string('away_pattern', 12)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('master_clubs', fn (Blueprint $table) => $table->dropColumn(['away_color', 'away_pattern']));
    }
};
