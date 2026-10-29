<?php

use App\Http\Controllers\Api\AdController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AllianceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DataController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\HomeController;
use App\Http\Controllers\Api\HonoursController;
use App\Http\Controllers\Api\IntegrityController;
use App\Http\Controllers\Api\LeagueController;
use App\Http\Controllers\Api\MarketController;
use App\Http\Controllers\Api\MatchController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PressController;
use App\Http\Controllers\Api\ScoutController;
use App\Http\Controllers\Api\SimulatorController;
use App\Http\Controllers\Api\SpecialistController;
use App\Http\Controllers\Api\SpyController;
use App\Http\Controllers\Api\StadiumController;
use App\Http\Controllers\Api\SupportController;
use App\Http\Controllers\Api\TeamController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\TrainingController;
use App\Http\Controllers\Api\TransferController;
use App\Http\Controllers\Api\WalletController;
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
    // A username's check as it is typed, with suggestions [X11].
    Route::get('username', 'usernameCheck')->middleware('throttle:30,1,username');
    Route::post('logout', 'logout');
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', 'me');
        Route::patch('me', 'update');
        Route::delete('me', 'destroy')->middleware('throttle:auth');
        Route::put('password', 'password')->middleware('throttle:auth');
        Route::post('email/resend', 'resend')->middleware('throttle:3,1,resend');
        Route::delete('token', 'revoke');
        Route::post('avatar', 'avatar')->middleware('throttle:10,1,avatar');
        Route::delete('avatar', 'removeAvatar');
        Route::post('vacation', 'vacation');
        // [UP6] The WhatsApp code that verifies the account and frees the welcome coins.
        Route::post('verify-account', 'verifyAccount')->middleware('throttle:10,1,verify-account');
        // [Sprint 21 E2.4] The code by email: three a quarter-hour per account.
        Route::post('verify-account/send', 'sendVerificationCode')->middleware('throttle:3,15,verify-send');
        Route::delete('vacation', 'endVacation');
    });
});

// An account's picture [X4]: public like a crest, so an <img> shows it anywhere.
Route::get('users/{user}/avatar', [AuthController::class, 'showAvatar'])->whereNumber('user')->middleware('throttle:240,1,avatar-show');

// The real clubs and players [PLAN 2.6], read-only and public: league templates, squads, badges.
Route::prefix('data')->controller(DataController::class)->middleware('throttle:120,1,data')->group(function () {
    Route::get('templates', 'templates');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'show')->whereNumber('club');
    Route::get('clubs/{club}/crest.svg', 'crest')->whereNumber('club');
    Route::get('glossary', 'glossary');
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
    // The live draw [X26].
    Route::get('{league}/draw', 'draw')->whereNumber('league');
    Route::put('{league}/draw', 'scheduleDraw')->whereNumber('league');
    Route::delete('{league}/request', 'cancel')->whereNumber('league');
    Route::get('{league}/requests', 'requests')->whereNumber('league');
    Route::post('{league}/requests/{joinRequest}/approve', 'approve')->whereNumber(['league', 'joinRequest']);
    Route::post('{league}/requests/{joinRequest}/reject', 'reject')->whereNumber(['league', 'joinRequest']);
    Route::post('{league}/vacation', 'vacation')->whereNumber('league');
    Route::delete('{league}/vacation', 'endVacation')->whereNumber('league');
    Route::post('{league}/members/{membership}/vacation/approve', 'approveVacation')->whereNumber(['league', 'membership']);
    Route::post('{league}/members/{membership}/vacation/reject', 'rejectVacation')->whereNumber(['league', 'membership']);
    Route::post('{league}/members/{membership}/kick', 'kick')->whereNumber(['league', 'membership']);
    Route::post('{league}/resign', 'resign')->whereNumber('league');
    Route::get('{league}/fixtures', 'fixtures')->whereNumber('league');
    Route::get('{league}/standings', 'standings')->whereNumber('league');
    Route::get('{league}/cup', 'cup')->whereNumber('league');
    Route::get('{league}/stats', 'stats')->whereNumber('league');
    Route::get('{league}/clubs', 'clubs')->whereNumber('league');
    // The hall of fame [Sprint 33].
    Route::get('{league}/honours', [HonoursController::class, 'league'])->whereNumber('league');
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
        Route::put('scenarios', 'saveScenarios');
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
        Route::get('quote', 'quote')->middleware('throttle:120,1,market-quote');
        // [UP11] The deal before it is made, and the transfers made.
        Route::get('buy-quote', 'buyQuote')->middleware('throttle:120,1,market-quote');
        Route::get('done', 'done')->middleware('throttle:60,1,market');
    });
    // [UP12] The league's media: the press conference, the predictions, the newspaper and its articles.
    Route::controller(PressController::class)->prefix('{league}')->whereNumber('league')->group(function () {
        Route::get('press/{fixture}', 'conference')->whereNumber('fixture');
        Route::post('press/{fixture}', 'say')->whereNumber('fixture')->middleware('throttle:20,1,press');
        Route::get('predictions', 'predictions');
        Route::post('predictions', 'predict')->middleware('throttle:60,1,predict');
        Route::get('newspaper', 'newspaper');
        Route::post('newspaper/articles', 'write')->middleware('throttle:6,1,articles');
        Route::post('newspaper/articles/{article}/decide', 'decide')->whereNumber('article');
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
        Route::post('finish', 'finish')->middleware('throttle:30,1,finish');
    });
    // Specialists [Sprint 31].
    Route::controller(SpecialistController::class)->prefix('{league}/specialists')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('/', 'hire')->middleware('throttle:20,1,specialists');
    });
    // The integrity system [X28].
    Route::controller(IntegrityController::class)->prefix('{league}/integrity')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('bribe', 'bribe')->middleware('throttle:20,1,integrity');
        Route::post('security', 'security')->middleware('throttle:20,1,integrity');
        Route::post('spies/{spy}/turn', 'turn')->whereNumber('spy')->middleware('throttle:20,1,integrity');
        Route::post('spies/{spy}/accuse', 'accuse')->whereNumber('spy')->middleware('throttle:20,1,integrity');
    });
    // The alliance tournament [X27].
    Route::controller(AllianceController::class)->prefix('{league}/alliance')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('/', 'store')->middleware('throttle:10,1,alliance');
        Route::post('ties/{tie}/decide', 'decide')->whereNumber('tie');
    });
    // Tickets to cheer at the other clubs' matches [X25].
    Route::controller(TicketController::class)->prefix('{league}/tickets')->whereNumber('league')->group(function () {
        Route::get('/', 'index');
        Route::post('/', 'store')->middleware('throttle:30,1,tickets');
    });
    // Spying on the next opponent [Sprint 30].
    Route::controller(SpyController::class)->prefix('{league}/spy')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('/', 'send')->middleware('throttle:20,1,spy');
    });
    // The stadium [Sprint 29].
    Route::controller(StadiumController::class)->prefix('{league}/stadium')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('/', 'start')->middleware('throttle:20,1,stadium');
        Route::post('finish', 'finish')->middleware('throttle:30,1,finish');
    });
    // Training [Sprint 27].
    Route::controller(TrainingController::class)->prefix('{league}/training')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('/', 'add')->middleware('throttle:30,1,training');
        Route::delete('{line}', 'remove')->whereIn('line', ['gk', 'def', 'mid', 'att']);
        Route::post('{line}/finish', 'finish')->whereIn('line', ['gk', 'def', 'mid', 'att'])->middleware('throttle:30,1,finish');
    });
    // [Sprint 21 E9] A verified rewarded video cuts a training or stadium time (off until the owner picks a provider).
    Route::post('{league}/ads/reward', [AdController::class, 'reward'])->whereNumber('league')->middleware('throttle:20,1,ads');
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
    Route::post('{match}/ready', 'ready')->whereNumber('match')->middleware('throttle:60,1,match-ready');
    // The broadcast's reactions and side chat [X24].
    Route::post('{match}/reactions', 'react')->whereNumber('match')->middleware('throttle:90,1,match-react');
    Route::post('{match}/chat', 'chat')->whereNumber('match')->middleware('throttle:60,1,match-chat');
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

// The admin panel [Sprint 37]: the admin only, and after the two-step code (from the site's session).
Route::prefix('admin')->middleware(['auth:sanctum', 'throttle:60,1,admin'])->controller(AdminController::class)->group(function () {
    Route::get('2fa', 'status');
    Route::post('2fa/setup', 'setup');
    Route::post('2fa/confirm', 'confirm')->middleware('throttle:10,1,admin-2fa');
    Route::post('2fa/verify', 'verify')->middleware('throttle:10,1,admin-2fa');
    Route::middleware('admin')->group(function () {
        Route::get('overview', 'overview');
        Route::get('alliances', 'alliances');
        Route::post('alliances/{id}/review', 'reviewAlliance')->whereNumber('id');
        Route::get('users', 'users');
        Route::get('leagues', 'leagues');
        Route::get('backups', 'backups');
        Route::post('backups', 'backupNow');
        Route::get('backups/{name}/download', 'downloadBackup')->where('name', '\d{4}-\d{2}-\d{2}_\d{6}');
        Route::get('commentary', 'commentary');
        Route::post('mail-test', 'mailTest')->middleware('throttle:10,1,mail-test');
        Route::post('users/{user}/official', 'official')->whereNumber('user');
        Route::post('users/{user}/verification-code', 'verificationCode')->whereNumber('user');
        // [UP13] The long holidays waiting for the developers.
        Route::get('vacations', 'vacations');
        Route::post('vacations/{id}/decide', 'decideVacation')->whereNumber('id');
        Route::post('announcements', 'announce');
        // [Sprint 21 E7] The announcements as sent, the accounts' suspension and deletion, the activity, and the
        // developers' conversations with the coaches.
        Route::get('announcements', 'announcements');
        Route::post('users/{user}/suspend', 'suspend')->whereNumber('user');
        Route::delete('users/{user}/suspend', 'unsuspend')->whereNumber('user');
        Route::delete('users/{user}', 'deleteUser')->whereNumber('user');
        Route::get('activity', 'activity');
        Route::get('conversations', 'conversations');
        Route::get('conversations/{user}', 'conversation')->whereNumber('user');
        Route::post('conversations/{user}', 'writeTo')->whereNumber('user')->middleware('throttle:30,1,admin-write');
        // [Sprint 20 S4] The game's own rewarded ads.
        Route::get('house-ads', 'houseAds');
        Route::post('house-ads', 'storeHouseAd');
        Route::patch('house-ads/{id}', 'updateHouseAd')->whereNumber('id');
        Route::delete('house-ads/{id}', 'deleteHouseAd')->whereNumber('id');
    });
});

// [Sprint 20 S4] A watch of one of the game's own rewarded ads.
Route::post('ads/start', [AdController::class, 'start'])->middleware(['auth:sanctum', 'throttle:20,1,ads-start']);

// [Sprint 21 E7.7] The coach's conversation with the game's developers.
Route::prefix('support')->middleware(['auth:sanctum', 'throttle:60,1,support'])->controller(SupportController::class)->group(function () {
    Route::get('/', 'show');
    Route::post('/', 'write')->middleware('throttle:10,1,support-write');
});

// Notifications [Sprint 36]: the kinds wanted and this browser's subscription.
Route::prefix('notifications')->middleware(['auth:sanctum', 'throttle:30,1,notifications'])->controller(NotificationController::class)->group(function () {
    Route::get('/', 'show');
    Route::put('/', 'update');
    Route::post('subscriptions', 'subscribe');
    Route::delete('subscriptions', 'unsubscribe');
});

// The coins wallet [Sprint 34].
Route::prefix('wallet')->middleware(['auth:sanctum', 'throttle:60,1,wallet'])->controller(WalletController::class)->group(function () {
    Route::get('/', 'show');
    Route::post('daily', 'daily');
});

// The coach's home screen and the coaches' global ranking [X18].
Route::middleware(['auth:sanctum', 'throttle:60,1,home'])->controller(HomeController::class)->group(function () {
    Route::get('home', 'show');
    Route::get('rankings/coaches', 'ranking');
});

// A coach's profile: titles, objectives and record [Sprint 33].
Route::get('coaches/{user}', [HonoursController::class, 'coach'])->middleware(['auth:sanctum', 'throttle:60,1,coaches'])->whereNumber('user');

// Simulator: development (and admin, later) only. See docs/MATCH_VIEW.md 8.
Route::prefix('sim')->middleware('simulator')->controller(SimulatorController::class)->group(function () {
    Route::get('leagues', 'leagues');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'club');
    Route::post('matches', 'store')->middleware('throttle:20,1,sim-store');
    Route::get('matches/{match}', 'show');
    Route::post('matches/{match}/actions', 'order')->middleware('throttle:120,1,sim-orders');
    Route::post('matches/{match}/ticks', 'ticks')->middleware('throttle:60,1,sim-ticks');
    Route::post('matches/{match}/start', 'start')->middleware('throttle:20,1,sim-start');
    Route::get('matches/{match}/live', 'live')->middleware('throttle:360,1,sim-live');
    Route::post('matches/{match}/reactions', 'react')->middleware('throttle:90,1,sim-react');
    Route::get('matches/{match}/report', 'report');
    Route::post('rooms', 'roomStore')->middleware('throttle:30,1,sim-rooms');
    Route::get('rooms/{room}', 'roomShow')->middleware('throttle:240,1,sim-room');
    Route::post('rooms/{room}/join', 'roomJoin')->middleware('throttle:30,1,sim-rooms');
});
