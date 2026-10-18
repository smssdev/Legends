<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Simulator matches (docs/MATCH_VIEW.md 8). The setup and the applied orders
 * are kept so a match can be replayed exactly from its seed.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sim_matches', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->unsignedInteger('seed');
            $table->json('setup');
            $table->json('control');
            $table->longText('state');
            $table->longText('ticks');
            $table->json('pending')->nullable();
            $table->json('applied')->nullable();
            $table->json('ball');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sim_matches');
    }
};
