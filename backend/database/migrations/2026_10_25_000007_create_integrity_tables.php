<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** The integrity system [X28]: the owner's switch, bribes, security checks and double agents, FA cases, and their marks on a club. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', fn (Blueprint $t) => $t->boolean('integrity')->default(false));
        Schema::table('clubs', function (Blueprint $t) {
            $t->timestamp('market_banned_until')->nullable();
            // The next home match's crowd cut after a scandal, in basis points.
            $t->unsignedSmallInteger('attendance_cut_bp')->default(0);
        });
        Schema::create('bribes', function (Blueprint $t) {
            $t->id();
            $t->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            $t->unsignedBigInteger('money');
            // null until kick-off; then clean (the referee leans) or var (caught, lost).
            $t->string('outcome', 5)->nullable();
            $t->timestamp('created_at');
            $t->unique(['fixture_id', 'club_id']);
        });
        Schema::create('integrity_actions', function (Blueprint $t) {
            $t->id();
            $t->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            // security (look for spies), double (a spy turned).
            $t->string('kind', 8);
            $t->foreignId('spy_report_id')->nullable()->constrained()->cascadeOnDelete();
            $t->timestamp('created_at');
            $t->unique(['fixture_id', 'club_id', 'kind', 'spy_report_id']);
        });
        Schema::create('fa_cases', function (Blueprint $t) {
            $t->id();
            $t->foreignId('season_id')->constrained()->cascadeOnDelete();
            $t->foreignId('bribe_id')->unique()->constrained()->cascadeOnDelete();
            $t->foreignId('accuser_club_id')->constrained('clubs')->cascadeOnDelete();
            $t->foreignId('accused_club_id')->constrained('clubs')->cascadeOnDelete();
            $t->unsignedBigInteger('fine');
            $t->unsignedTinyInteger('points');
            $t->timestamp('created_at');
            $t->index(['season_id', 'accused_club_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fa_cases');
        Schema::dropIfExists('integrity_actions');
        Schema::dropIfExists('bribes');
        Schema::table('clubs', fn (Blueprint $t) => $t->dropColumn(['market_banned_until', 'attendance_cut_bp']));
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn('integrity'));
    }
};
