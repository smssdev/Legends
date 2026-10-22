<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DataController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\LeagueController;
use App\Http\Controllers\Api\SimulatorController;
use Illuminate\Support\Facades\Route;

// Every route here is served under /api/v1 (see bootstrap/app.php) and is
// documented in docs/api/openapi.yaml in the same PR.

Route::get('health', [HealthController::class, 'show']);
Route::post('health/ping', [HealthController::class, 'ping'])->middleware('throttle:10,1');

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
        Route::post('email/resend', 'resend')->middleware('throttle:3,1');
        Route::delete('token', 'revoke');
    });
});

// The real clubs and players [PLAN 2.6], read-only and public: league templates, squads, badges.
Route::prefix('data')->controller(DataController::class)->middleware('throttle:120,1')->group(function () {
    Route::get('templates', 'templates');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'show')->whereNumber('club');
    Route::get('clubs/{club}/crest.svg', 'crest')->whereNumber('club');
});

// Private leagues [PLAN 2.1, 2.3]: make one, ask to join by its code, the owner approves, take a club.
Route::prefix('leagues')->middleware(['auth:sanctum', 'throttle:120,1', 'league.activity'])->controller(LeagueController::class)->group(function () {
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
    Route::get('{league}/clubs/{club}', 'club')->whereNumber(['league', 'club']);
    Route::post('{league}/clubs/{club}/claim', 'claim')->whereNumber(['league', 'club']);
});

// Simulator: development (and admin, later) only. See docs/MATCH_VIEW.md 8.
Route::prefix('sim')->middleware('simulator')->controller(SimulatorController::class)->group(function () {
    Route::get('leagues', 'leagues');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'club');
    Route::post('matches', 'store');
    Route::get('matches/{match}', 'show');
    Route::post('matches/{match}/actions', 'order')->middleware('throttle:120,1');
    Route::post('matches/{match}/ticks', 'ticks');
    Route::post('matches/{match}/start', 'start');
    Route::get('matches/{match}/live', 'live')->middleware('throttle:360,1');
    Route::post('matches/{match}/reactions', 'react')->middleware('throttle:90,1');
    Route::get('matches/{match}/report', 'report');
    Route::post('rooms', 'roomStore')->middleware('throttle:30,1');
    Route::get('rooms/{room}', 'roomShow')->middleware('throttle:240,1');
    Route::post('rooms/{room}/join', 'roomJoin')->middleware('throttle:30,1');
});
