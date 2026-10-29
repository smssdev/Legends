<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * [SEO] What Google gets: each public page built with its own tags (web/scripts/seo.mjs) goes out as itself, any
 * other screen gets the app's index.html, and the invite link's card replaces the page's tags instead of doubling them.
 */
class SeoPagesTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    /** @var list<string> the files this test wrote into public/, removed after it */
    private array $written = [];

    private function page(string $path, string $title): void
    {
        $file = public_path(ltrim($path, '/'));
        if (is_file($file)) {
            $this->markTestSkipped("public/{$path} is a real build here");
        }
        File::ensureDirectoryExists(dirname($file));
        File::put($file, "<!doctype html><html lang=\"ar\"><head>\n    <!-- seo: test -->\n    <title>{$title}</title>\n    <meta name=\"description\" content=\"{$title}\" />\n    <!-- /seo -->\n  </head><body></body></html>");
        $this->written[] = $file;
    }

    /** The HTML a page gets (the app's files go out as files). */
    private function served(string $uri): string
    {
        return file_get_contents($this->get($uri)->assertOk()->assertHeader('Content-Type', 'text/html; charset=UTF-8')->baseResponse->getFile()->getPathname());
    }

    protected function tearDown(): void
    {
        foreach ($this->written as $file) {
            File::delete($file);
            if (basename(dirname($file)) === 'register') {
                @rmdir(dirname($file));
            }
        }
        parent::tearDown();
    }

    public function test_a_public_page_goes_out_with_its_own_tags_and_any_other_screen_gets_the_app(): void
    {
        $this->page('index.html', 'الرئيسية');
        $this->page('register/index.html', 'إنشاء حساب مجاني');

        $this->assertStringContainsString('<title>إنشاء حساب مجاني</title>', $this->served('/register'));
        $this->assertStringContainsString('<title>الرئيسية</title>', $this->served('/'));
        $this->assertStringContainsString('<title>الرئيسية</title>', $this->served('/club'));
        $this->assertStringContainsString('<title>الرئيسية</title>', $this->served('/register/../club'));
    }

    public function test_the_invite_card_replaces_the_pages_tags(): void
    {
        $this->page('index.html', 'الرئيسية');
        $this->template();
        $league = $this->makeLeague(User::factory()->create(), ['starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);

        $html = $this->get('/join/'.$league['code'])->assertOk()->getContent();
        $this->assertSame(1, substr_count($html, '<title>'));
        $this->assertSame(1, substr_count($html, 'name="description"'));
        $this->assertStringNotContainsString('<!-- seo', $html);
        $this->assertStringContainsString('<meta name="robots" content="noindex">', $html);
        $this->assertStringContainsString('og:title', $html);
    }
}
