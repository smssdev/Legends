<?php

// One coach buying a player, in a process of its own (LeagueClaimRaceTest): boots the app on the test database,
// waits for the shared start moment, and prints "won", "taken" or the error.

use App\Market\Market;
use Illuminate\Contracts\Console\Kernel;
use Symfony\Component\HttpKernel\Exception\HttpException;

require __DIR__.'/../../vendor/autoload.php';
$app = require __DIR__.'/../../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

[, $clubId, $playerId, $startAt] = $argv;
while (microtime(true) < (float) $startAt) {
    usleep(500);
}

try {
    Market::buy((int) $clubId, (int) $playerId, "race:{$clubId}");
    echo 'won';
} catch (HttpException $e) {
    // Too late: either the update found him gone, or he is already on the winner's team.
    $late = ['سبقك مدرب آخر إلى هذا اللاعب.', 'اللاعب في فريق مدرب آخر.'];
    echo $e->getStatusCode() === 409 && in_array($e->getMessage(), $late, true) ? 'taken' : 'error: '.$e->getMessage();
} catch (Throwable $e) {
    echo 'error: '.get_class($e).': '.$e->getMessage();
}
