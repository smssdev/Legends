<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// A player's value in club money [PLAN 2.6], from App\Data\PlayerValuation. data:import fills it,
// and data:value works it out again after the numbers in config/game.php change.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('master_players', function (Blueprint $table) {
            $table->unsignedBigInteger('value')->default(0)->after('potential');
        });
    }

    public function down(): void
    {
        Schema::table('master_players', fn (Blueprint $table) => $table->dropColumn('value'));
    }
};
