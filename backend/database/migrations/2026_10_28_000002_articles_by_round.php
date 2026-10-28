<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 21 E4.5] An article's season and round: each coach writes one article a round.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('league_articles', function (Blueprint $table) {
            $table->foreignId('season_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedSmallInteger('round')->nullable();
            $table->index(['league_id', 'user_id', 'season_id', 'round']);
        });
    }

    public function down(): void
    {
        Schema::table('league_articles', function (Blueprint $table) {
            $table->dropIndex(['league_id', 'user_id', 'season_id', 'round']);
            $table->dropConstrainedForeignId('season_id');
            $table->dropColumn('round');
        });
    }
};
