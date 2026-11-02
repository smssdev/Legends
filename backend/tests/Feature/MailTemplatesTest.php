<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\GameUpdateNotice;
use App\Notifications\ResetPasswordNotice;
use App\Notifications\StoreDealNotice;
use App\Notifications\VerifyEmailNotice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

/** [Sprint 39 M1-M3] The game's emails share one frame, in Arabic (right to left) or English. */
class MailTemplatesTest extends TestCase
{
    use RefreshDatabase;

    public function test_every_email_carries_the_game_s_name_in_its_frame(): void
    {
        $coach = User::factory()->create(['name' => 'كريم']);
        foreach ([(new VerifyEmailNotice)->toMail($coach), (new ResetPasswordNotice('t0ken'))->toMail($coach)] as $mail) {
            $html = $mail->render();
            $this->assertStringContainsString('GAME LEGEND', $html);
            $this->assertStringContainsString('المدرب الأسطورة', $html);
            $this->assertStringContainsString('dir="rtl"', $html);
            $this->assertStringContainsString(e($mail->actionUrl), $html);
        }
        $coach->forceFill(['locale' => 'en'])->save();
        $html = (new VerifyEmailNotice)->toMail($coach)->render();
        $this->assertStringContainsString('dir="ltr"', $html);
        $this->assertStringNotContainsString('المدرب الأسطورة', $html);
    }

    public function test_a_match_summary_shows_the_score_and_leads_to_the_report(): void
    {
        $coach = User::factory()->create();
        $mail = GameUpdateNotice::matchSummary(false, 'الأهلي', 2, 1, 'الزمالك', 'الدوري', ["صلاح 23'"], 77)->toMail($coach);
        $this->assertSame('انتهت المباراة: الأهلي 2 – 1 الزمالك', $mail->subject);
        $this->assertStringEndsWith('/live/77/report', $mail->actionUrl);
        $html = $mail->render();
        // In Arabic the home side is on the right with its goals beside it: shown left to right as away – home.
        $this->assertStringContainsString('1 – 2', $html);
        $this->assertStringContainsString(e("صلاح 23'"), $html);

        $alert = GameUpdateNotice::alert(true, 'Your player was sold', 'A club bought him.', '/market', [['Price', '2,400,000']])->toMail($coach);
        $this->assertStringContainsString('2,400,000', $alert->render());
    }

    public function test_a_store_deal_lists_its_packs_and_how_to_stop_them(): void
    {
        $coach = User::factory()->create();
        $html = (new StoreDealNotice('عرض', 'اشحن بزيادة', 'هذا الأسبوع', [['name' => '500', 'gives' => '500 كوينز', 'price' => '$4.99', 'was' => '$6.99', 'badge' => '-30%']], 'الأحد'))
            ->toMail($coach)->render();
        $this->assertStringContainsString('<s', $html);
        $this->assertStringContainsString('حتى الأحد', $html);
        $this->assertStringContainsString('لإيقافها', $html);
        $this->expectException(HttpException::class);
        new StoreDealNotice('x', 'x', 'x', []);
    }
}
