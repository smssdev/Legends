<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X62 E8] Every change the developers make to the game's data from the admin panel: who, what, and the fields
// before and after.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('data_edits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('kind', 12);      // player or club
            $table->unsignedBigInteger('target_id');
            $table->string('action', 8);     // create, update, delete
            $table->json('changes');
            $table->timestamp('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('data_edits');
    }
};
