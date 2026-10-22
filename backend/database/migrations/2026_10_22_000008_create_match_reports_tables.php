<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * What a match tells each coach [ENGINE 8, Sprint 20 B2]: the assistant's readings while it is played, and
 * the report after it ("why you won or lost"). Both are built from MatchFacts: the public events and the
 * coach's own side, never the other side's hidden tactics.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_readings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('tick');
            $table->unsignedTinyInteger('minute');
            $table->string('kind', 20);
            $table->string('text', 300);
            $table->timestamp('created_at');

            // A minute made again after a restart gives the same reading once.
            $table->unique(['match_id', 'club_id', 'tick']);
        });

        Schema::create('match_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->json('report');
            $table->timestamp('created_at');

            $table->unique(['match_id', 'club_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_reports');
        Schema::dropIfExists('match_readings');
    }
};
