<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // A room for a match between two friends: the host waits, the guest joins and the match starts.
        Schema::create('sim_rooms', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('host_name', 24);
            $table->foreignId('host_club_id')->constrained('master_clubs');
            $table->string('guest_name', 24)->nullable();
            $table->foreignId('guest_club_id')->nullable()->constrained('master_clubs');
            $table->foreignUlid('sim_match_id')->nullable()->constrained('sim_matches');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sim_rooms');
    }
};
