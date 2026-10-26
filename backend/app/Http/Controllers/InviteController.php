<?php

namespace App\Http\Controllers;

use App\Models\League;
use Illuminate\Http\Response;

/**
 * The invite link /join/{code} [PLAN 2.1, Sprint 14 B2]. WhatsApp reads the page's Open Graph tags for
 * its card: og-invite.png with the league's name and owner in Arabic. A person who opens it gets the
 * app, and the Vue router shows the join screen with the code filled in.
 */
class InviteController extends Controller
{
    public function show(string $code): Response
    {
        $code = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', $code));
        $league = League::where('code', $code)->with('owner')->first();
        $brand = config('game.brand.name', 'لعبة المدرب الأسطورة');
        $title = $league ? "انضم لـ{$league->name} في {$brand}" : "دعوة إلى {$brand}";
        $description = $league
            ? ($league->owner ? "{$league->owner->name} يدعوك" : 'دعوة').' لدوري خاص من '.$league->team_count.' فريقاً على '.$league->template.'. اختر ناديك وأدِره ضد أصحابك. الكود: '.$code
            : 'كرة القدم مع أصحابك: دوري خاص، ومباريات تديرها حية.';
        $meta = collect([
            ['property' => 'og:type', 'content' => 'website'],
            ['property' => 'og:site_name', 'content' => $brand],
            ['property' => 'og:title', 'content' => $title],
            ['property' => 'og:description', 'content' => $description],
            ['property' => 'og:url', 'content' => url('/join/'.$code)],
            ['property' => 'og:image', 'content' => url('/brand/og-invite.png')],
            ['property' => 'og:image:width', 'content' => '1200'],
            ['property' => 'og:image:height', 'content' => '630'],
            ['property' => 'og:locale', 'content' => 'ar_AR'],
            ['name' => 'twitter:card', 'content' => 'summary_large_image'],
            ['name' => 'description', 'content' => $description],
        ])->map(fn ($m) => '<meta '.collect($m)->map(fn ($v, $k) => $k.'="'.e($v).'"')->implode(' ').'>')->implode("\n    ");

        $index = public_path('index.html');
        $html = is_file($index) ? file_get_contents($index) : '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><title></title></head><body><a href="/join?code='.e($code).'">'.e($title).'</a></body></html>';
        $html = preg_replace('#<title>.*?</title>#s', '<title>'.e($title).'</title>', $html, 1);
        $html = str_replace('</head>', "    {$meta}\n  </head>", $html);

        return response($html, 200, ['Content-Type' => 'text/html; charset=UTF-8', 'Cache-Control' => 'no-cache']);
    }
}
