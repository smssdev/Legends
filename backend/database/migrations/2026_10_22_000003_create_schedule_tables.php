<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A season's calendar [PLAN 2.4, 2.5, 4]: every league round and cup tie with its time (UTC), the cup's
 * bracket, and the two windows when the market pool is renewed. Made by App\League\SeasonScheduler.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixtures', function (Blueprint $table) {
            $table->id();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->string('competition', 6);
            // League: the round (1..R). Cup: the stage's order (1 = the first stage played).
            $table->unsignedTinyInteger('round');
            $table->timestamp('scheduled_at');
            // Empty while a cup tie waits for its teams; a league rest has only home_id.
            $table->foreignId('home_id')->nullable()->constrained('clubs')->cascadeOnDelete();
            $table->foreignId('away_id')->nullable()->constrained('clubs')->cascadeOnDelete();
            $table->boolean('is_bye')->default(false);
            $table->string('referee_strictness', 8)->nullable();
            $table->string('status', 10)->default('scheduled');
            // Kept here when the match ends, for the table [PLAN 2.4]; the match itself has the details.
            $table->unsignedTinyInteger('home_goals')->nullable();
            $table->unsignedTinyInteger('away_goals')->nullable();
            $table->timestamps();

            $table->index(['season_id', 'competition', 'round']);
            $table->index(['status', 'scheduled_at']);
        });

        Schema::create('cup_ties', function (Blueprint $table) {
            $table->id();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->string('stage', 12);
            $table->unsignedTinyInteger('slot');
            $table->foreignId('home_id')->nullable()->constrained('clubs')->cascadeOnDelete();
            $table->foreignId('away_id')->nullable()->constrained('clubs')->cascadeOnDelete();
            $table->foreignId('winner_id')->nullable()->constrained('clubs')->cascadeOnDelete();
            // The winner moves on to this tie, on this side.
            $table->foreignId('next_tie_id')->nullable()->constrained('cup_ties')->nullOnDelete();
            $table->string('next_side', 4)->nullable();
            $table->foreignId('fixture_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();

            $table->unique(['season_id', 'stage', 'slot']);
        });

        Schema::create('transfer_windows', function (Blueprint $table) {
            $table->id();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->string('kind', 6);
            $table->timestamp('opens_at');
            $table->timestamp('closes_at');
            $table->timestamps();

            $table->unique(['season_id', 'kind']);
        });

        Schema::table('seasons', function (Blueprint $table) {
            $table->timestamp('ends_at')->nullable()->after('starts_at');
        });
    }

    public function down(): void
    {
        Schema::table('seasons', fn (Blueprint $table) => $table->dropColumn('ends_at'));
        Schema::dropIfExists('transfer_windows');
        Schema::dropIfExists('cup_ties');
        Schema::dropIfExists('fixtures');
    }
};
