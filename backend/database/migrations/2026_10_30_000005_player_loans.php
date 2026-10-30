<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X61 E2] A player lent between two coaches' clubs for some league rounds, for a fee: asked, then active until its
// round (he goes home), or turned down.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('player_loans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->foreignId('owner_club_id')->constrained('clubs')->cascadeOnDelete();
            $table->foreignId('borrower_club_id')->constrained('clubs')->cascadeOnDelete();
            $table->unsignedTinyInteger('rounds');
            $table->unsignedBigInteger('fee');
            $table->string('status', 10)->default('pending');   // pending, active, returned, rejected
            $table->unsignedSmallInteger('until_round')->nullable();
            $table->timestamps();
            $table->index(['season_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('player_loans');
    }
};
