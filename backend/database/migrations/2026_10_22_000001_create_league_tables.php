<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Private leagues [PLAN 2.1, 2.3, 4]: a league copies the strongest N clubs of a template into its own
 * clubs and players (the master tables never change), coaches ask to join by code, the owner approves,
 * and a coach takes a club with one conditional update. Club money lives in club_transactions.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('leagues', function (Blueprint $table) {
            $table->id();
            // The league goes on when its owner deletes the account: the bots fill every seat anyway.
            $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('code', 8)->unique();
            $table->string('name', 60);
            $table->string('template');
            $table->string('data_version', 16);
            $table->unsignedTinyInteger('team_count');
            $table->unsignedTinyInteger('rounds_per_day');
            $table->json('round_times');
            $table->unsignedTinyInteger('prep_days');
            $table->timestamp('starts_at');
            $table->string('season_end_mode', 8);
            $table->unsignedBigInteger('starting_budget');
            $table->boolean('fair_league')->default(false);
            $table->boolean('is_dev')->default(false);
            // Season length ÷ 37 days in basis points [PLAN 2.10]; set by the scheduler (Sprint 15).
            $table->unsignedInteger('timer_scale')->nullable();
            $table->string('status', 10)->default('waiting');
            $table->timestamp('settings_locked_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'starts_at']);
        });

        Schema::create('seasons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('number');
            $table->timestamp('starts_at');
            $table->date('winter_break_on')->nullable();
            $table->unsignedTinyInteger('rounds');
            // Coaches cannot come in (or resign) from this league round on [PLAN 2.1, 2.2].
            $table->unsignedTinyInteger('lock_from_round');
            // League rounds played so far; the scheduler moves it on (Sprint 15).
            $table->unsignedTinyInteger('rounds_played')->default(0);
            $table->string('status', 10)->default('upcoming');
            $table->timestamps();

            $table->unique(['league_id', 'number']);
        });

        Schema::create('clubs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('master_club_id')->constrained('master_clubs');
            // Empty = a bot runs it. A deleted account hands its club back to the bots.
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('code', 4);
            $table->string('color_primary', 7);
            $table->string('color_secondary', 7);
            $table->unsignedSmallInteger('strength_snapshot');
            $table->string('bot_personality', 12);
            // The sum of club_transactions, kept here for quick reads and changed in the same transaction.
            // It can go below zero (wages), and then nothing can be spent [PLAN 2.7].
            $table->bigInteger('balance')->default(0);
            $table->timestamps();

            $table->unique(['league_id', 'master_club_id']);
            // One club per account in each league.
            $table->unique(['league_id', 'user_id']);
        });

        Schema::create('players', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            // Empty = in the league's market pool.
            $table->foreignId('club_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('master_player_id')->constrained('master_players');
            $table->unsignedTinyInteger('overall');
            $table->unsignedBigInteger('base_value');
            $table->unsignedSmallInteger('training_bonus')->default(0);
            $table->unsignedTinyInteger('fitness')->default(100);
            $table->unsignedTinyInteger('injured_matches')->default(0);
            $table->unsignedTinyInteger('suspended_matches')->default(0);
            $table->unsignedBigInteger('value');
            $table->timestamps();

            $table->unique(['league_id', 'master_player_id']);
            $table->index('club_id');
        });

        Schema::create('league_join_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('status', 10)->default('pending');
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();

            $table->unique(['league_id', 'user_id']);
        });

        Schema::create('league_memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('club_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('joined_at');
            $table->timestamp('left_at')->nullable();
            $table->string('left_reason', 10)->nullable();
            $table->string('kick_reason', 200)->nullable();
            $table->timestamp('last_active_at')->nullable();
            $table->timestamp('vacation_from')->nullable();
            $table->timestamp('vacation_until')->nullable();
            $table->timestamps();

            // Who leaves cannot come back to the same league in the same season [PLAN 2.1].
            $table->unique(['user_id', 'league_id', 'season_id']);
            $table->index(['user_id', 'left_at']);
        });

        // Never changed or deleted: a club's balance is the sum of its rows [PLAN 2.7].
        Schema::create('club_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('type', 24);
            $table->bigInteger('amount');
            $table->bigInteger('balance_after');
            $table->string('idempotency_key', 80)->unique();
            $table->string('reference', 80)->nullable();
            $table->timestamp('created_at');

            $table->index(['club_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('club_transactions');
        Schema::dropIfExists('league_memberships');
        Schema::dropIfExists('league_join_requests');
        Schema::dropIfExists('players');
        Schema::dropIfExists('clubs');
        Schema::dropIfExists('seasons');
        Schema::dropIfExists('leagues');
    }
};
