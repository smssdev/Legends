<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Read-only source data (docs/PLAN.md 2.6). Every league copies what it needs
 * into its own clubs/players tables later, so these rows never change in play.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('master_clubs', function (Blueprint $table) {
            $table->id();
            $table->string('data_version', 16);
            $table->string('source', 16)->default('imported');
            $table->string('name');
            $table->string('code', 4);
            $table->string('league_name');
            $table->unsignedSmallInteger('strength_cp');
            $table->string('color_primary', 7);
            $table->string('color_secondary', 7);
            $table->string('logo_path')->nullable();
            $table->timestamps();

            $table->unique(['data_version', 'name']);
            $table->index(['data_version', 'league_name']);
        });

        Schema::create('master_players', function (Blueprint $table) {
            $table->id();
            $table->string('data_version', 16);
            $table->string('source', 16)->default('imported');
            $table->unsignedBigInteger('external_id');
            $table->foreignId('master_club_id')->constrained('master_clubs')->cascadeOnDelete();
            $table->string('name');
            $table->string('position', 4);
            $table->string('line', 3);
            $table->string('alt_positions')->nullable();
            $table->unsignedTinyInteger('age');
            $table->string('nationality')->nullable();
            $table->string('preferred_foot', 5)->nullable();
            $table->unsignedTinyInteger('overall');
            $table->unsignedTinyInteger('potential');
            foreach (['pac', 'sho', 'pas', 'dri', 'def', 'phy'] as $attr) {
                $table->unsignedTinyInteger($attr)->nullable();
            }
            foreach (['gk_diving', 'gk_handling', 'gk_kicking', 'gk_positioning', 'gk_reflexes'] as $attr) {
                $table->unsignedTinyInteger($attr)->nullable();
            }
            foreach (['penalties', 'free_kick', 'crossing', 'heading', 'stamina', 'aggression'] as $attr) {
                $table->unsignedTinyInteger($attr)->nullable();
            }
            $table->timestamps();

            $table->unique(['data_version', 'external_id']);
            $table->index(['master_club_id', 'overall']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('master_players');
        Schema::dropIfExists('master_clubs');
    }
};
