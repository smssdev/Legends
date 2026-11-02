<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [X76] A club's kit pattern (plain, stripes, hoops, halves or sash; null is plain), set from the admin panel's data
 * editor by the owner's decision (2026-11-02). On the data clubs only: every league reads it from there. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('master_clubs', function (Blueprint $table) {
            $table->string('kit_pattern', 12)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('master_clubs', fn (Blueprint $table) => $table->dropColumn('kit_pattern'));
    }
};
