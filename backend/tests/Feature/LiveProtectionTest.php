<?php

namespace Tests\Feature;

use App\Events\MatchMinute;
use App\League\LiveDegrade;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/** The live broadcast under load [Sprint 21 E8.7]: the degradation ladder and the log rotation. */
class LiveProtectionTest extends TestCase
{
    public function test_the_ladder_gives_up_the_summary_then_the_voice_then_the_pace(): void
    {
        Cache::flush();
        $this->assertSame([true, true, null], [LiveDegrade::summary(), LiveDegrade::voice(), LiveDegrade::pollMs()]);
        $tick = ['tick' => 3, 'minute' => [3, 0], 'score' => ['home' => 0, 'away' => 0], 'moment' => ['kind' => 'calm', 'ms' => 3000],
            'finished' => false, 'events' => [], 'voice' => ['line' => 'x']];
        $minute = fn () => (new MatchMinute((object) [], 9, $tick))->broadcastWith();
        $this->assertSame(['line' => 'x'], $minute()['voice']);

        $this->artisan('matches:degrade', ['level' => 1])->assertSuccessful();
        $this->assertSame([false, true, null], [LiveDegrade::summary(), LiveDegrade::voice(), LiveDegrade::pollMs()]);
        $this->artisan('matches:degrade', ['level' => 2])->assertSuccessful();
        $this->assertSame([false, false, null], [LiveDegrade::summary(), LiveDegrade::voice(), LiveDegrade::pollMs()]);
        $this->assertNull($minute()['voice']);
        $this->artisan('matches:degrade', ['level' => 3])->assertSuccessful();
        $this->assertSame(3000, LiveDegrade::pollMs());
        // The match itself never degrades: the minute, the score and the events still go.
        $this->assertSame(3, $minute()['tick']);

        $this->artisan('matches:degrade', ['level' => 7])->assertFailed();
        $this->artisan('matches:degrade', ['--reset' => true])->assertSuccessful();
        $this->assertSame(0, LiveDegrade::level());
        config(['game.live.degrade.level' => 2]);
        $this->assertFalse(LiveDegrade::voice());
    }

    public function test_a_log_over_the_limit_is_rotated_and_written_on(): void
    {
        $dir = sys_get_temp_dir().'/legends-logs-'.getmypid();
        @mkdir($dir);
        config(['game.logs.max_mb' => 1]);
        file_put_contents("{$dir}/matches.log", str_repeat('x', 1024 * 1024 + 1));
        file_put_contents("{$dir}/queue.log", 'small');
        // A writer that holds the file open, appending like the container's >>.
        $writer = fopen("{$dir}/matches.log", 'a');

        $this->artisan('logs:trim', ['--dir' => $dir])->expectsOutput('Rotated matches.log')->assertSuccessful();
        fwrite($writer, 'after');
        fclose($writer);
        clearstatcache();
        $this->assertSame('after', file_get_contents("{$dir}/matches.log"));
        $this->assertSame(1024 * 1024 + 1, filesize("{$dir}/matches.log.1"));
        $this->assertSame('small', file_get_contents("{$dir}/queue.log"));
        array_map('unlink', glob("{$dir}/*"));
        rmdir($dir);
    }
}
