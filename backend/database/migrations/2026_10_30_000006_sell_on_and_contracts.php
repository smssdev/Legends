<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X62] The sell-on clause (on an offer, then on the player until his next sale), and a contract that runs past the
// season: the last season number he stays with his club (null: the season's end sends him back to the data).
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transfer_offers', function (Blueprint $table) {
            $table->unsignedSmallInteger('sell_on_bp')->default(0);
        });
        Schema::table('players', function (Blueprint $table) {
            $table->unsignedBigInteger('sell_on_club_id')->nullable();
            $table->unsignedSmallInteger('sell_on_bp')->nullable();
            $table->unsignedSmallInteger('contract_until')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('transfer_offers', function (Blueprint $table) {
            $table->dropColumn('sell_on_bp');
        });
        Schema::table('players', function (Blueprint $table) {
            $table->dropColumn(['sell_on_club_id', 'sell_on_bp', 'contract_until']);
        });
    }
};
