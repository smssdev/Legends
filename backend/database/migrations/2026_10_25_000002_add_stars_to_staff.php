<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Staff by stars [X20]: each contract has 1 to 5 stars (the old ones count as 3), and the coach hears when one
 * ends and the specialist leaves.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('staff_specialists', function (Blueprint $table) {
            $table->unsignedTinyInteger('stars')->default(3);
            $table->timestamp('left_notified_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('staff_specialists', fn (Blueprint $table) => $table->dropColumn(['stars', 'left_notified_at']));
    }
};
