<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [X78] A finished match's scene as it was played (every minute with its frames, gzipped JSON in base64), so it is
 * watched again after the engine changes (App\League\MatchReplay::keep). One row a match. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_replays', function (Blueprint $table) {
            $table->unsignedBigInteger('match_id')->primary();
            $table->unsignedInteger('engine_version');
            $table->unsignedInteger('bytes');
            $table->longText('ticks');
            $table->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_replays');
    }
};
