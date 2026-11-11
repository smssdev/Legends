<?php

use App\Http\Controllers\Api\AdController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AllianceController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\AppReleaseController;
use App\Http\Controllers\Api\AssistantController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ClubBoardController;
use App\Http\Controllers\Api\CspReportController;
use App\Http\Controllers\Api\DataController;
use App\Http\Controllers\Api\DataEditorController;
use App\Http\Controllers\Api\DealsController;
use App\Http\Controllers\Api\FriendlyController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\HomeController;
use App\Http\Controllers\Api\HonoursController;
use App\Http\Controllers\Api\IdeasController;
use App\Http\Controllers\Api\IntegrityController;
use App\Http\Controllers\Api\LeagueController;
use App\Http\Controllers\Api\MarketController;
use App\Http\Controllers\Api\MatchController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PressController;
use App\Http\Controllers\Api\QuestController;
use App\Http\Controllers\Api\ScoutController;
use App\Http\Controllers\Api\SimulatorController;
use App\Http\Controllers\Api\SpecialistController;
use App\Http\Controllers\Api\SpyController;
use App\Http\Controllers\Api\StadiumController;
use App\Http\Controllers\Api\StoreController;
use App\Http\Controllers\Api\SupportController;
use App\Http\Controllers\Api\TeamController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\TimedEventController;
use App\Http\Controllers\Api\TournamentController;
use App\Http\Controllers\Api\TrainingController;
use App\Http\Controllers\Api\TransferController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Broadcasting\BroadcastController;
use Illuminate\Support\Facades\Route;

// Every route here is served under /api/v1 (see bootstrap/app.php) and is
// documented in docs/api/openapi.yaml in the same PR.

Route::get('health', [HealthController::class, 'show']);
Route::post('health/ping', [HealthController::class, 'ping'])->middleware('throttle:10,1,ping');
// [Sprint 53 F1] The app's private channels (a live match, a club, a chat group, the inbox): signed with its token. The
// web signs them with its session at /broadcasting/auth; the same rules (routes/channels.php) decide.
Route::post('broadcasting/auth', [BroadcastController::class, 'authenticate'])->middleware(['auth:sanctum', 'throttle:240,1,broadcast-auth']);
// [Sprint 51 B2] The report-only Content-Security-Policy's violations, from the browser (App\Http\Security\SecurityPolicy).
Route::post('csp-report', [CspReportController::class, 'store'])->middleware('throttle:30,1,csp-report');

// Accounts [PLAN 2.17]: the web by session cookie, the app by token. Login attempts are limited
// per email and per address (AppServiceProvider, "auth").
Route::prefix('auth')->controller(AuthController::class)->group(function () {
    Route::middleware('throttle:auth')->group(function () {
        Route::post('register', 'register');
        Route::post('login', 'login');
        Route::post('token', 'token');
        Route::post('google/token', 'googleToken');
        // [Sprint 50 M5] Playing as a guest (the app), then keeping the account.
        Route::post('guest', 'guest')->middleware('throttle:5,60,guest');
        Route::post('forgot-password', 'forgot');
        Route::post('reset-password', 'reset');
    });
    // A username's check as it is typed, with suggestions [X11].
    Route::get('username', 'usernameCheck')->middleware('throttle:30,1,username');
    Route::post('logout', 'logout');
    // [Sprint 30 Q11] Who is signed in, open to a guest too (204, no error in the console).
    Route::get('me', 'me');
    Route::middleware('auth:sanctum')->group(function () {
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
        Route::post('guest/keep', 'keepGuest')->middleware('throttle:auth');
        Route::post('guest/google', 'keepGuestWithGoogle')->middleware('throttle:auth');
    });
});

// An account's picture [X4]: public like a crest, so an <img> shows it anywhere.
Route::get('users/{user}/avatar', [AuthController::class, 'showAvatar'])->whereNumber('user')->middleware('throttle:240,1,avatar-show');

// The real clubs and players [PLAN 2.6], read-only and public: league templates, squads, badges.
// [Sprint 30 Q12] The game's fixed data: kept by the browser an hour, and asked again with its ETag (304, nothing sent).
Route::prefix('data')->controller(DataController::class)->middleware(['throttle:120,1,data', 'cache.headers:private;max_age=3600;etag'])->group(function () {
    Route::get('templates', 'templates');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'show')->whereNumber('club');
    Route::get('clubs/{club}/crest.svg', 'crest')->whereNumber('club');
    Route::get('glossary', 'glossary');
    Route::get('quick-orders', 'quickOrders');
});
Route::get('data/formations', [TeamController::class, 'formations'])->middleware(['throttle:120,1,data', 'cache.headers:private;max_age=3600;etag']);

// [Sprint 29] Tournaments: the catalog (templates, national teams, clubs), making one, its page and its draw, which
// anyone signed in may watch live or replay. Coaches join it by its code as a league (/leagues/join).
Route::prefix('tournaments')->middleware(['auth:sanctum', 'throttle:120,1,tournaments'])->controller(TournamentController::class)->group(function () {
    Route::get('/', 'index');
    Route::get('catalog', 'catalog');
    Route::get('clubs', 'clubs');
    Route::post('/', 'store')->middleware('throttle:league-create');
    Route::get('{league}', 'show')->whereNumber('league');
    Route::get('{league}/draw', 'draw')->whereNumber('league');
    // [X68] Entering a tournament whose teams the draw shares out, and the organizer naming teams' coaches.
    Route::post('{league}/entry', 'enter')->whereNumber('league')->middleware('throttle:20,1,tournament-entry');
    Route::delete('{league}/entry', 'leave')->whereNumber('league');
    Route::put('{league}/owners', 'owners')->whereNumber('league');
    // [X66] The live draw's chat and reactions.
    Route::get('{league}/draw/chat', 'chat')->whereNumber('league');
    Route::post('{league}/draw/chat', 'say')->whereNumber('league')->middleware('throttle:60,1,draw-chat');
    Route::delete('{league}/draw/chat/{message}', 'unsay')->whereNumber(['league', 'message']);
});

// [Sprint 29] Chat groups, as in WhatsApp: any coaches, and every league's own.
Route::prefix('groups')->middleware(['auth:sanctum', 'throttle:240,1,groups'])->controller(ChatController::class)->group(function () {
    Route::get('/', 'index');
    Route::post('/', 'store')->middleware('throttle:10,1,group-create');
    Route::post('join/{code}', 'join')->where('code', '[a-z0-9]{10}')->middleware('throttle:20,1,group-join');
    Route::get('league/{league}', 'league')->whereNumber('league');
    Route::get('{group}', 'show')->whereNumber('group');
    Route::patch('{group}', 'update')->whereNumber('group');
    Route::get('{group}/messages', 'messages')->whereNumber('group');
    Route::post('{group}/messages', 'send')->whereNumber('group')->middleware('throttle:60,1,group-send');
    Route::post('{group}/media', 'sendMedia')->whereNumber('group')->middleware('throttle:20,1,group-media');
    Route::get('{group}/media/{message}', 'media')->whereNumber(['group', 'message'])->middleware('throttle:600,1,group-media-show');
    Route::delete('{group}/messages/{message}', 'destroyMessage')->whereNumber(['group', 'message']);
    // [Sprint 50 M8] A quick reaction on a message.
    Route::post('{group}/messages/{message}/reaction', 'react')->whereNumber(['group', 'message'])->middleware('throttle:60,1,chat-react');
    // [Sprint 30 G6] A report to the admins.
    Route::post('{group}/messages/{message}/report', 'reportMessage')->whereNumber(['group', 'message'])->middleware('throttle:20,1,chat-report');
    Route::post('{group}/read', 'read')->whereNumber('group');
    Route::post('{group}/members', 'addMembers')->whereNumber('group');
    Route::delete('{group}/members/{user}', 'removeMember')->whereNumber(['group', 'user']);
    Route::put('{group}/members/{user}/admin', 'admin')->whereNumber(['group', 'user']);
    Route::post('{group}/leave', 'leave')->whereNumber('group');
});

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
    // [Sprint 43 W1] The contract with his club, signed once a season.
    Route::post('{league}/contract', 'signContract')->whereNumber('league');
    Route::get('{league}/fixtures', 'fixtures')->whereNumber('league');
    Route::get('{league}/standings', 'standings')->whereNumber('league');
    Route::get('{league}/cup', 'cup')->whereNumber('league');
    Route::get('{league}/stats', 'stats')->whereNumber('league');
    Route::get('{league}/clubs', 'clubs')->whereNumber('league');
    // The hall of fame [Sprint 33].
    Route::get('{league}/honours', [HonoursController::class, 'league'])->whereNumber('league');
    Route::get('{league}/awards', [HonoursController::class, 'awards'])->whereNumber('league');
    // My club: the squad, the lineup and the set-piece takers [Sprint 16].
    Route::controller(TeamController::class)->prefix('{league}/team')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::get('suggestion', 'suggestion');
        // [Sprint 48 T1] The squad's season: goals and ratings by round, and the league's transfers.
        Route::get('season', 'season');
        Route::put('lineup', 'saveLineup');
        Route::delete('lineup', 'resetLineup');
        Route::put('formations/{number}', 'saveFormation')->whereNumber('number');
        Route::put('takers', 'saveTakers');
        Route::get('tactics', 'tactics');
        Route::put('tactics', 'saveTactics');
        Route::put('scenarios', 'saveScenarios');
        Route::get('next-match', 'nextMatch');
        // [Sprint 27 B2] Moving a match on its own day, with the other coach's answer.
        Route::post('moves', 'proposeMove')->middleware('throttle:20,1,moves');
        Route::post('moves/{move}/accept', 'acceptMove')->whereNumber('move')->middleware('throttle:20,1,moves');
        Route::post('moves/{move}/decline', 'declineMove')->whereNumber('move')->middleware('throttle:20,1,moves');
        Route::delete('moves/{move}', 'cancelMove')->whereNumber('move')->middleware('throttle:20,1,moves');
        // [Sprint 20 B1, B3] The club board in one request, and the matches the coach missed.
        Route::get('summary', [ClubBoardController::class, 'summary']);
        Route::get('missed', [ClubBoardController::class, 'missed']);
        Route::post('missed/seen', [ClubBoardController::class, 'seen'])->middleware('throttle:30,1,missed-seen');
        // Club money [Sprint 23].
        Route::get('finance', 'finance');
        Route::post('sponsors', 'signSponsor');
        Route::put('tickets', 'setTickets')->middleware('throttle:30,1,tickets');
        // [X61 E1] The contracts.
        Route::get('contracts', 'contracts');
        Route::post('contracts/{player}/release', 'release')->whereNumber('player')->middleware('throttle:20,1,release');
        Route::post('contracts/{player}/renew', 'renew')->whereNumber('player')->middleware('throttle:20,1,renew');
        Route::post('contracts/renew-ending', 'renewEnding')->middleware('throttle:10,1,renew-ending');
    });
    // The market: the pool and the bot clubs [Sprint 24].
    Route::controller(MarketController::class)->prefix('{league}/market')->whereNumber('league')->group(function () {
        Route::get('/', 'show');
        Route::post('buy', 'buy')->middleware('throttle:30,1,market');
        // [X61 E3] The youth academy.
        Route::get('academy', 'academy');
        Route::post('academy', 'signAcademy')->middleware('throttle:20,1,academy');
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
        // [X61 E2] Loans between coaches.
        Route::get('loans', 'loans');
        Route::post('loans', 'askLoan')->middleware('throttle:20,1,loans');
        Route::post('loans/{loan}/answer', 'answerLoan')->whereNumber('loan');
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
        // [Sprint 40 D2] The one who went on swaps players with the team he passed.
        Route::post('ties/{tie}/swap', 'swap')->whereNumber('tie')->middleware('throttle:20,1,alliance-swap');
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
    // [Sprint 20 B4] The friendlies.
    Route::get('{league}/friendlies', [FriendlyController::class, 'show'])->whereNumber('league');
    Route::post('{league}/friendlies', [FriendlyController::class, 'play'])->whereNumber('league')->middleware('throttle:10,1,friendlies');
    // [Sprint 20 B5] The weekly quests.
    Route::get('{league}/quests', [QuestController::class, 'show'])->whereNumber('league');
    Route::post('{league}/quests/claim', [QuestController::class, 'claim'])->whereNumber('league')->middleware('throttle:20,1,quests');
    // [Sprint 50 M18, M19, M21] Auctions, the release clause, the talk with a computer club, and the store's chests.
    Route::controller(DealsController::class)->whereNumber('league')->group(function () {
        Route::get('{league}/auctions', 'auctions');
        Route::post('{league}/auctions/{player}/bids', 'bid')->whereNumber('player')->middleware('throttle:60,1,auction-bid');
        Route::get('{league}/release/{player}', 'releaseQuote')->whereNumber('player');
        Route::post('{league}/release/{player}', 'release')->whereNumber('player')->middleware('throttle:10,1,release');
        Route::get('{league}/negotiations/{player}', 'negotiation')->whereNumber('player');
        Route::post('{league}/negotiations/{player}', 'negotiate')->whereNumber('player')->middleware('throttle:30,1,negotiate');
        Route::get('{league}/chests', 'chests');
        Route::post('{league}/chests/{chest}/open', 'openChest')->where('chest', '[a-z]{3,12}')->middleware('throttle:20,1,chests');
    });
    // [Sprint 50 M10] The daily tasks.
    Route::get('{league}/daily-tasks', [QuestController::class, 'daily'])->whereNumber('league');
    Route::post('{league}/daily-tasks/claim', [QuestController::class, 'claimDaily'])->whereNumber('league')->middleware('throttle:20,1,quests');
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
    // [Sprint 02 B1] What the Unity scene draws, once per match.
    Route::get('{match}/scene', 'scene')->whereNumber('match')->middleware('throttle:60,1,match-scene');
    Route::post('{match}/actions', 'order')->whereNumber('match')->middleware('throttle:120,1,match-orders');
    Route::post('{match}/ready', 'ready')->whereNumber('match')->middleware('throttle:60,1,match-ready');
    // [Sprint 50 M14] The coach's one timeout.
    Route::post('{match}/timeout', 'timeout')->whereNumber('match')->middleware('throttle:10,1,match-timeout');
    // The broadcast's reactions and side chat [X24].
    Route::post('{match}/reactions', 'react')->whereNumber('match')->middleware('throttle:90,1,match-react');
    Route::post('{match}/chat', 'chat')->whereNumber('match')->middleware('throttle:60,1,match-chat');
    Route::get('{match}/replay', 'replay')->whereNumber('match')->middleware('throttle:30,1,match-replay');
    Route::get('{match}/report', 'report')->whereNumber('match')->middleware('throttle:60,1,match-report');
    // [Sprint 24 B1] The quick recap for a coach who missed the match.
    Route::get('{match}/recap', 'recap')->whereNumber('match')->middleware('throttle:60,1,match-recap');
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
    Route::get('access', 'access');
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
        // [X62 E8] The game's data editor.
        Route::controller(DataEditorController::class)->prefix('data')->group(function () {
            Route::get('/', 'search');
            Route::get('leagues', 'leagues');
            Route::post('players', 'createPlayer')->middleware('throttle:30,1,data-edit');
            Route::patch('players/{id}', 'updatePlayer')->whereNumber('id')->middleware('throttle:60,1,data-edit');
            Route::delete('players/{id}', 'deletePlayer')->whereNumber('id');
            Route::post('clubs', 'createClub')->middleware('throttle:30,1,data-edit');
            Route::patch('clubs/{id}', 'updateClub')->whereNumber('id')->middleware('throttle:60,1,data-edit');
        });
        // [X65] The chat groups: how long their messages are kept, whether media may be sent, and a clean-up now.
        Route::get('chat', 'chat');
        Route::put('chat', 'setChat');
        Route::post('chat/prune', 'pruneChat');
        // [X54] Coins to any account by its number.
        Route::post('coins', 'giveCoins')->middleware('throttle:30,1,admin-coins');
        // [Sprint 15 D1] The app's versions: uploaded in pieces, then published as the latest.
        Route::get('app-releases', [AppReleaseController::class, 'index']);
        Route::post('app-releases', [AppReleaseController::class, 'start'])->middleware('throttle:10,1,admin-app');
        Route::put('app-releases/{id}/chunk', [AppReleaseController::class, 'chunk'])->whereNumber('id')->middleware('throttle:600,1,admin-app-chunk');
        Route::post('app-releases/{id}/finish', [AppReleaseController::class, 'finish'])->whereNumber('id');
        Route::delete('app-releases/{id}', [AppReleaseController::class, 'destroy'])->whereNumber('id');
        // [Sprint 43 W2] The store: packages and timed offers, each by email to those who asked.
        Route::get('store', [StoreController::class, 'adminIndex']);
        Route::post('store', [StoreController::class, 'store'])->middleware('throttle:30,1,admin-store');
        Route::post('store/{id}', [StoreController::class, 'update'])->whereNumber('id')->middleware('throttle:60,1,admin-store');
        Route::delete('store/{id}', [StoreController::class, 'destroy'])->whereNumber('id');
        Route::post('store/{id}/email', [StoreController::class, 'email'])->whereNumber('id')->middleware('throttle:5,1,admin-store-email');
        // [Sprint 20 S4] The game's own rewarded ads.
        Route::get('house-ads', 'houseAds');
        Route::post('house-ads', 'storeHouseAd');
        Route::patch('house-ads/{id}', 'updateHouseAd')->whereNumber('id');
        Route::delete('house-ads/{id}', 'deleteHouseAd')->whereNumber('id');
        // [Sprint 30 P3] The test texts players can see, and the button that removes them.
        // [Sprint 30 G6] The groups' moderation queue, a writer let back in, and the admins' scopes.
        Route::get('reports', 'reports');
        Route::post('reports/{message}/decide', 'decideReport')->whereNumber('message');
        Route::delete('users/{user}/chat-ban', 'chatUnban')->whereNumber('user');
        Route::put('users/{user}/scope', 'setScope')->whereNumber('user');
        Route::get('junk', 'junk');
        Route::post('junk/purge', 'purgeJunk');
        // [Sprint 23] The timed events: transfer madness, extreme progression, the market's discount and its special players.
        Route::get('events', [TimedEventController::class, 'index']);
        Route::post('events', [TimedEventController::class, 'store'])->middleware('throttle:30,1,admin-events');
        Route::patch('events/{id}', [TimedEventController::class, 'update'])->whereNumber('id');
        Route::delete('events/{id}', [TimedEventController::class, 'destroy'])->whereNumber('id');
        // [Sprint 28] The coaches' suggestions (the answer and its reward) and the polls on what to build next.
        Route::controller(IdeasController::class)->group(function () {
            Route::get('ideas', 'adminSuggestions');
            Route::post('ideas/{id}/decide', 'decide')->whereNumber('id')->middleware('throttle:60,1,admin-ideas');
            Route::get('polls', 'adminPolls');
            Route::post('polls', 'openPoll')->middleware('throttle:20,1,admin-polls');
            Route::delete('polls/{id}', 'closePoll')->whereNumber('id');
        });
    });
});

// [Sprint 15 D1] The app to download from the site (public): the latest version, and the Android file.
Route::get('app', [AppReleaseController::class, 'show'])->middleware('throttle:60,1,app');
Route::get('app/android.apk', [AppReleaseController::class, 'download'])->middleware('throttle:20,1,app-download');

// [Sprint 43 W2] The store for the coaches (bought by WhatsApp), and its pictures (public, for an <img> and the emails).
Route::get('store', [StoreController::class, 'index'])->middleware(['auth:sanctum', 'throttle:60,1,store']);
Route::get('store/{id}/image', [StoreController::class, 'image'])->whereNumber('id')->middleware('throttle:240,1,store-image');

// [X54] The developers' announcements as cards, and their pictures (public like a crest, for an <img>).
Route::get('announcements', [AnnouncementController::class, 'index'])->middleware(['auth:sanctum', 'throttle:60,1,announcements']);
Route::get('announcements/{id}/image', [AnnouncementController::class, 'image'])->whereNumber('id')->middleware('throttle:240,1,announcement-image');

// [Sprint 20 S4] A watch of one of the game's own rewarded ads.
Route::post('ads/start', [AdController::class, 'start'])->middleware(['auth:sanctum', 'throttle:20,1,ads-start']);

// [Sprint 21 E7.7] The coach's conversation with the game's developers.
Route::prefix('support')->middleware(['auth:sanctum', 'throttle:60,1,support'])->controller(SupportController::class)->group(function () {
    Route::get('/', 'show');
    Route::post('/', 'write')->middleware('throttle:10,1,support-write');
});

// [Sprint 28] The development ideas: a suggestion to the developers, the polls on what to build next, the honour roll.
Route::prefix('ideas')->middleware(['auth:sanctum', 'throttle:60,1,ideas'])->controller(IdeasController::class)->group(function () {
    Route::get('/', 'show');
    Route::post('suggestions', 'suggest')->middleware('throttle:10,1,ideas-suggest');
    Route::post('polls/{poll}/vote', 'vote')->whereNumber('poll')->middleware('throttle:30,1,ideas-vote');
});

// Notifications [Sprint 36]: the kinds wanted and this browser's subscription.
Route::prefix('notifications')->middleware(['auth:sanctum', 'throttle:30,1,notifications'])->controller(NotificationController::class)->group(function () {
    Route::get('/', 'show');
    Route::put('/', 'update');
    Route::post('subscriptions', 'subscribe');
    Route::delete('subscriptions', 'unsubscribe');
});

// [X59] The game's guide, public: the "how to play" page for visitors and search engines.
Route::get('guide', [AssistantController::class, 'guide'])->middleware('throttle:60,1,guide');

// [Sprint 22] The Assistant Coach (Manager Bot): the conversation's opening on a page, and one answer (each smart
// answer counts against the coach's day; the guide's answers are free).
Route::prefix('assistant')->middleware(['auth:sanctum'])->controller(AssistantController::class)->group(function () {
    Route::get('start', 'start')->middleware('throttle:60,1,assistant-start');
    Route::post('ask', 'ask')->middleware('throttle:20,1,assistant-ask');
    Route::post('feedback', 'feedback')->middleware('throttle:10,1,assistant-feedback');
});

// The coins wallet [Sprint 34].
Route::prefix('wallet')->middleware(['auth:sanctum', 'throttle:60,1,wallet'])->controller(WalletController::class)->group(function () {
    Route::get('/', 'show');
    Route::post('daily', 'daily');
});

// The coach's home screen and the coaches' global ranking [X18].
Route::middleware(['auth:sanctum', 'throttle:60,1,home'])->controller(HomeController::class)->group(function () {
    Route::get('home', 'show');
    Route::post('home/starter-gift', 'claimStarter');
    Route::get('home/achievements', 'achievements');
    Route::get('rankings/coaches', 'ranking');
    // [Sprint 24 B3] Open a locked slot now for coins.
    Route::post('home/slots/{slot}/unlock', 'unlock')->whereNumber('slot');
});

// A coach's profile: titles, objectives and record [Sprint 33].
Route::get('coaches/{user}', [HonoursController::class, 'coach'])->middleware(['auth:sanctum', 'throttle:60,1,coaches'])->whereNumber('user');

// Simulator: development (and admin, later) only. See docs/MATCH_VIEW.md 8.
Route::prefix('sim')->middleware('simulator')->controller(SimulatorController::class)->group(function () {
    Route::get('leagues', 'leagues');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'club');
    Route::post('matches', 'store')->middleware(['throttle:20,1,sim-store', 'throttle:sim-guest']);
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
