<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * How the coach watches his matches, kept with the account so every device plays the same [2026-10-25]:
 * the Arabic commentator (the sixth voice is the default) [X9], and the simulator, cartoon or Unity [X10].
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('commentator', 16)->default('voice-6');
            $table->string('match_view', 10)->default('cartoon');
        });
    }

    public function down(): void
    {
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn(['commentator', 'match_view']));
    }
};
