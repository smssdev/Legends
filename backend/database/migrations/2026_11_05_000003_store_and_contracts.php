<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 43 W1, W2, Hamza 2026-11-05] The store: base packages that stay until the admin edits or deletes them, and
 * offers that end at a time the admin sets; each with its picture cut to one size. And the contract a coach signs once
 * a season when he takes his club. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_items', function (Blueprint $table) {
            $table->id();
            $table->string('kind', 8);                 // package | offer
            $table->string('title', 80);
            $table->text('description');
            $table->unsignedInteger('price');
            $table->unsignedInteger('old_price')->nullable();
            $table->string('currency', 12);
            $table->boolean('visible')->default(true);
            $table->boolean('has_image')->default(false);
            $table->unsignedSmallInteger('sort')->default(0);
            $table->timestamp('ends_at')->nullable();  // an offer's end
            $table->timestamp('emailed_at')->nullable();
            $table->timestamps();
            $table->index(['visible', 'kind']);
        });
        Schema::create('store_item_images', function (Blueprint $table) {
            $table->unsignedBigInteger('store_item_id')->primary();
            $table->binary('image');
            $table->timestamp('created_at')->nullable();
        });
        Schema::create('league_contracts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->timestamp('signed_at');
            $table->unique(['season_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('league_contracts');
        Schema::dropIfExists('store_item_images');
        Schema::dropIfExists('store_items');
    }
};
