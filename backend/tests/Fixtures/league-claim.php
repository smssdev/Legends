<?php

// One coach reaching for a club, in a process of its own (LeagueClaimRaceTest). It boots the app
// on the test database, waits for the shared start moment, and prints "won", "taken" or the error.

use App\League\Joining;
use App\Models\League;
use App\Models\User;
use Illuminate\Contracts\Console\Kernel;
use Symfony\Component\HttpKernel\Exception\HttpException;

require __DIR__.'/../../vendor/autoload.php';
$app = require __DIR__.'/../../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

[, $userId, $leagueId, $clubId, $startAt] = $argv;
$user = User::findOrFail($userId);
$league = League::findOrFail($leagueId);
while (microtime(true) < (float) $startAt) {
    usleep(500);
}

try {
    Joining::claim($user, $league, (int) $clubId);
    echo 'won';
} catch (HttpException $e) {
    echo $e->getStatusCode() === 409 && $e->getMessage() === 'الفريق أُخذ، اختر فريقاً آخر.' ? 'taken' : 'error: '.$e->getMessage();
} catch (Throwable $e) {
    echo 'error: '.get_class($e).': '.$e->getMessage();
}
