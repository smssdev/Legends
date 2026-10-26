<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [UP9] The owner's spec (4, 2026-10-26): a league with the standard settings is free, and changing any of them
 * costs coins once (the coins paid are kept here). [UP12] The press conferences, on by default, are a setting too.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $table) {
            $table->unsignedInteger('custom_coins')->default(0);
            $table->boolean('press_conferences')->default(true);
        });
    }

    public function down(): void
    {
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn(['custom_coins', 'press_conferences']));
    }
};
