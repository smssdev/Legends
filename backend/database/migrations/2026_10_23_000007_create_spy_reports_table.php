<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Spying on the next opponent [docs/features/spy.md, Sprint 30]: one report per club and fixture, as it was then. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('spy_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('target_club_id')->constrained('clubs')->cascadeOnDelete();
            $table->json('report');
            $table->unsignedBigInteger('cost');
            $table->timestamps();

            $table->unique(['club_id', 'fixture_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('spy_reports');
    }
};
