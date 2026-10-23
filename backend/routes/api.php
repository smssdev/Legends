<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DataController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\LeagueController;
use App\Http\Controllers\Api\MarketController;
use App\Http\Controllers\Api\MatchController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\ScoutController;
use App\Http\Controllers\Api\SimulatorController;
use App\Http\Controllers\Api\TeamController;
use App\Http\Controllers\Api\TransferController;
use Illuminate\Support\Facades\Route;

// Every route here is served under /api/v1 (see bootstrap/app.php) and is
// documented in docs/api/openapi.yaml in the same PR.

Route::get('health', [HealthController::class, 'show']);
Route::post('health/ping', [HealthController::class, 'ping'])->middleware('throttle:10,1,ping');

// Accounts [PLAN 2.17]: the web by session cookie, the app by token. Login attempts are limited
// per email and per address (AppServiceProvider, "auth").
Route::prefix('auth')->controller(AuthController::class)->group(function () {
    Route::middleware('throttle:auth')->group(function () {
        Route::post('register', 'register');
        Route::post('login', 'login');
        Route::post('token', 'token');
        Route::post('google/token', 'googleToken');
        Route::post('forgot-password', 'forgot');
        Route::post('reset-password', 'reset');
    });
    Route::post('logout', 'logout');
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', 'me');
        Route::patch('me', 'update');
        Route::delete('me', 'destroy')->middleware('throttle:auth');
        Route::put('password', 'password')->middleware('throttle:auth');
        Route::post('email/resend', 'resend')->middleware('throttle:3,1,resend');
        Route::delete('token', 'revoke');
    });
});

// The real clubs and players [PLAN 2.6], read-only and public: league templates, squads, badges.
Route::prefix('data')->controller(DataController::class)->middleware('throttle:120,1,data')->group(function () {
    Route::get('templates', 'templates');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'show')->whereNumber('club');
    Route::get('clubs/{club}/crest.svg', 'crest')->whereNumber('club');
});
Route::get('data/formations', [TeamController::class, 'formations'])->middleware('throttle:120,1,data');

// Private leagues [PLAN 2.1, 2.3]: make one, ask to join by its code, the owner approves, take a club.
Route::prefix('leagues')->middleware(['auth:sanctum', 'throttle:120,1,leagues', 'league.activity'])->controller(LeagueController::class)->group(function () {
    Route::get('/', 'index');
    Route::post('/', 'store')->middleware('throttle:league-create');
    Route::post('join', 'join')->middleware('throttle:league-code');
    Route::get('{league}', 'show')->whereNumber('league');
    Route::patch('{league}', 'update')->whereNumber('league');
    Route::post('{league}/start', 'start')->whereNumber('league');
    Route::delete('{league}/request', 'cancel')->whereNumber('league');
    Route::get('{league}/requests', 'requests')->whereNumber('league');
    Route::post('{league}/requests/{joinRequest}/approve', 'approve')->whereNumber(['league', 'joinRequest']);
    Route::post('{league}/requests/{joinRequest}/reject', 'reject')->whereNumber(['league', 'joinRequest']);
    Route::post('{league}/vacation', 'vacation')->whereNumber('league');
    Route::delete('{league}/vacation', 'endVacation')->whereNumber('league');
    Route::post('{league}/members/{membership}/kick', 'kick')->whereNumber(['league', 'membership']);
    Route::get('{league}/fixtures', 'fixtures')->whereNumber('league');
    Route::get('{league}/standings', 'standings')->whereNumber('league');
    Route::get('{league}/cup', 'cup')->whereNumber('league');
    Route::get('{league}/clubs', 'clubs')->whereNumber('league');
    // My club: the squad, the lineup and the set-piece takers [Sprint 16].
    Route::controller(TeamController::class)->prefix('{league}/team')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::get('suggestion', 'suggestion');
        Route::put('lineup', 'saveLineup');
        Route::delete('lineup', 'resetLineup');
        Route::put('formations/{number}', 'saveFormation')->whereNumber('number');
        Route::put('takers', 'saveTakers');
        Route::get('tactics', 'tactics');
        Route::put('tactics', 'saveTactics');
        Route::get('next-match', 'nextMatch');
        // Club money [Sprint 23].
        Route::get('finance', 'finance');
        Route::post('sponsors', 'signSponsor');
    });
    // The market: the pool and the bot clubs [Sprint 24].
    Route::controller(MarketController::class)->prefix('{league}/market')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('buy', 'buy')->middleware('throttle:30,1,market');
        Route::post('sell', 'sell')->middleware('throttle:30,1,market');
    });
    // The market between coaches: the transfer list and the offers [Sprint 25].
    Route::controller(TransferController::class)->prefix('{league}/transfers')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('listings', 'list')->middleware('throttle:30,1,transfers');
        Route::delete('listings/{player}', 'unlist')->whereNumber('player');
        Route::post('offers', 'offer')->middleware('throttle:30,1,transfers');
        Route::post('offers/{offer}/accept', 'accept')->whereNumber('offer');
        Route::post('offers/{offer}/reject', 'reject')->whereNumber('offer');
        Route::post('offers/{offer}/cancel', 'cancel')->whereNumber('offer');
        Route::post('offers/{offer}/counter', 'counter')->whereNumber('offer')->middleware('throttle:30,1,transfers');
    });
    // The scout [Sprint 26].
    Route::controller(ScoutController::class)->prefix('{league}/scout')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('/', 'ask')->middleware('throttle:20,1,scout');
    });
    Route::get('{league}/clubs/{club}', 'club')->whereNumber(['league', 'club']);
    Route::post('{league}/clubs/{club}/claim', 'claim')->whereNumber(['league', 'club']);
});

// League matches [Sprints 18 to 20]: the viewer for the league's members, and each coach's orders for his side.
// Every throttle has its own name: unnamed ones share one count per user, and the live poll would use up the rest.
Route::prefix('matches')->middleware(['auth:sanctum'])->controller(MatchController::class)->group(function () {
    Route::get('live', 'mine')->middleware('throttle:120,1,match-mine');
    Route::get('{match}', 'show')->whereNumber('match')->middleware('throttle:120,1,match-show');
    Route::get('{match}/live', 'live')->whereNumber('match')->middleware('throttle:720,1,match-live');
    Route::post('{match}/actions', 'order')->whereNumber('match')->middleware('throttle:120,1,match-orders');
    Route::get('{match}/replay', 'replay')->whereNumber('match')->middleware('throttle:30,1,match-replay');
    Route::get('{match}/report', 'report')->whereNumber('match')->middleware('throttle:60,1,match-report');
});

// The inbox [Sprint 22]: the account's messages; new ones and reads also arrive on App.Models.User.{id}.
Route::prefix('messages')->middleware(['auth:sanctum', 'throttle:120,1,messages'])->controller(MessageController::class)->group(function () {
    Route::get('/', 'index');
    Route::get('unread', 'unread');
    Route::post('read-all', 'readAll');
    Route::post('{message}/read', 'read')->whereNumber('message');
});

// Simulator: development (and admin, later) only. See docs/MATCH_VIEW.md 8.
Route::prefix('sim')->middleware('simulator')->controller(SimulatorController::class)->group(function () {
    Route::get('leagues', 'leagues');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'club');
    Route::post('matches', 'store');
    Route::get('matches/{match}', 'show');
    Route::post('matches/{match}/actions', 'order')->middleware('throttle:120,1,sim-orders');
    Route::post('matches/{match}/ticks', 'ticks');
    Route::post('matches/{match}/start', 'start');
    Route::get('matches/{match}/live', 'live')->middleware('throttle:360,1,sim-live');
    Route::post('matches/{match}/reactions', 'react')->middleware('throttle:90,1,sim-react');
    Route::get('matches/{match}/report', 'report');
    Route::post('rooms', 'roomStore')->middleware('throttle:30,1,sim-rooms');
    Route::get('rooms/{room}', 'roomShow')->middleware('throttle:240,1,sim-room');
    Route::post('rooms/{room}/join', 'roomJoin')->middleware('throttle:30,1,sim-rooms');
});
