<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // A live match: each coach's device holds a secret seat, and only that seat gives orders for its side.
        Schema::table('sim_matches', function (Blueprint $table) {
            $table->json('seats')->nullable();
        });
        Schema::table('sim_rooms', function (Blueprint $table) {
            $table->string('host_seat', 64)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('sim_rooms', fn (Blueprint $table) => $table->dropColumn('host_seat'));
        Schema::table('sim_matches', fn (Blueprint $table) => $table->dropColumn('seats'));
    }
};
