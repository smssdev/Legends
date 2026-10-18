<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sim_matches', function (Blueprint $table) {
            // Live (two-device) matches: the server keeps the clock. Null for solo matches.
            $table->json('live')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('sim_matches', fn (Blueprint $table) => $table->dropColumn('live'));
    }
};
