<?php

namespace App\Simulator;

/**
 * [Sprint 57 B2] What one minute becomes on the match feed, decided on the server (it was web/src/match/feed/story.ts,
 * ported line by line, and checked against it on 50 matches by tests/Unit/MomentStoryTest): the scene to play and who is
 * in it, the commentator's lines, the bubble, and the timeline cards. The screens only draw it.
 *
 * The words stay keys of the game's dictionary (the Arabic text, as t() takes it), with the names as references, so
 * each screen writes them in its own language and with the coach's names switch:
 *   'نص'                 a text to translate
 *   ['t' => 'نص {v0}', 'v' => [...]]  a text with its parts
 *   ['p' => id]          a player's name, ['c' => 'home'] a club's, ['r' => '4-4-2'] as it is
 *   ['j' => [...], 'by' => part]      parts joined
 *   ['say' => {m, s, lang?, i}, 'vars' => {p, q, A, n}]  a line of voice.json (its key, slot, language and variant)
 *                                    with its names ({p} {q} {A} {B} {n})
 * The commentator's lines are references into voice.json too (the line, the slot and each language's variant): every
 * screen has the table, and its words never travel with the minute.
 *
 * Built from the minute as the screen asking may see it (after Simulator::redact): the other side's instructions are
 * not in it, so the coach's card names them only for their own coach (CLAUDE.md, privacy in a match).
 * The line's timing on a scene and the English bubble are the screen's (the scenes' lengths are drawn there).
 */
final class MomentStory
{
    private const TACTIC_NAMES = ['pressing' => 'الضغط', 'style' => 'الأسلوب', 'tempo' => 'الإيقاع', 'plan' => 'خطة اللعب', 'att' => 'تمركز المهاجمين', 'mid' => 'تمركز الوسط', 'def' => 'تمركز الدفاع', 'trap' => 'مصيدة التسلل', 'marking' => 'الرقابة', 'tackling' => 'قطع الكرة'];

    private int $a;

    /** @var array<int|string, array{name: string, no: int|string}> */
    private array $players = [];

    private array $out;

    private array $vars = ['p' => null, 'q' => null, 'A' => 'home', 'n' => ''];

    private bool $served;

    private ?array $voice;

    /** The minute with its story added (for the screens). */
    public static function attach(array $tick, int $seed): array
    {
        if (! isset($tick['events'], $tick['tick'], $tick['moment'])) {
            return $tick;
        }

        return $tick + ['story' => self::of($tick, $seed)];
    }

    public static function of(array $tick, int $seed): array
    {
        return (new self($tick, $seed))->build($tick);
    }

    private function __construct(array $tick, int $seed)
    {
        // The same draw as before (mulberry32 seeded by the match and the minute), in 32-bit integers.
        $this->a = self::u32(($seed ?: 1) * 31 + (int) $tick['tick'] * 977);
        foreach (['home', 'away'] as $side) {
            foreach ($tick['teams'][$side]['players'] ?? [] as $p) {
                $this->players[$p['id']] = ['name' => $p['name'], 'no' => $p['no']];
            }
        }
        $this->served = array_key_exists('voice', $tick);
        $this->voice = $tick['voice'] ?? null;
    }

    private static function u32(int $x): int
    {
        return (($x % 4294967296) + 4294967296) % 4294967296;
    }

    /** Math.imul for unsigned 32-bit values, without leaving PHP's integers. */
    private static function imul(int $a, int $b): int
    {
        return (($a * ($b & 0xFFFF)) + ((($a * ($b >> 16)) & 0xFFFF) << 16)) & 0xFFFFFFFF;
    }

    /** The next draw, as the 32-bit integer the old R() divided by 2^32. */
    private function next(): int
    {
        $this->a = ($this->a + 0x6D2B79F5) & 0xFFFFFFFF;
        $t = $this->a;
        $t = self::imul($t ^ ($t >> 15), $t | 1);
        $t = ($t ^ (($t + self::imul($t ^ ($t >> 7), $t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;

        return ($t ^ ($t >> 14)) & 0xFFFFFFFF;
    }

    private function pick(array $list): mixed
    {
        return $list[intdiv($this->next() * count($list), 4294967296)];
    }

    /** A scene's own seed: floor(R() * 1e9), exactly (1e9 / 2^32 = 1953125 / 2^23). */
    private function seed(): int
    {
        return intdiv($this->next() * 1953125, 8388608);
    }

    private function has(mixed $id): bool
    {
        return $id !== null && isset($this->players[$id]);
    }

    private function no(mixed $id): int|string
    {
        return $id !== null ? ($this->players[$id]['no'] ?? '') : '';
    }

    private static function nm(mixed $id): array
    {
        return ['p' => $id];
    }

    private static function club(string $side): array
    {
        return ['c' => $side];
    }

    private static function t(string $key, mixed ...$v): string|array
    {
        return $v ? ['t' => $key, 'v' => $v] : $key;
    }

    private static function other(string $s): string
    {
        return $s === 'home' ? 'away' : 'home';
    }

    private static function first(array $events, string $type): ?array
    {
        foreach ($events as $e) {
            if ($e['type'] === $type) {
                return $e;
            }
        }

        return null;
    }

    /** The variants whose names we have, one chosen by the seed (the minutes without the server's voice). */
    private function fill(array $list): ?int
    {
        $ok = array_keys(array_filter($list, fn ($l) => (! str_contains($l, '{p}') || $this->vars['p']) && (! str_contains($l, '{q}') || $this->vars['q'])));

        return $ok ? $this->pick($ok) : null;
    }

    /** Which variant, by the seed. */
    private function any(array $list): ?int
    {
        return $list ? $this->pick(array_keys($list)) : null;
    }

    /** The commentator's line: the build-up, the key moment and the reaction, and the bubble. */
    private function speak(string $key, array $at = []): void
    {
        $V = $this->voice;
        if ($this->served && ! $V) {
            return;
        }
        if ($V) {
            $key = $V['line'];
            $this->vars['p'] = $V['vars']['p'] ?? null;
            $this->vars['q'] = $V['vars']['q'] ?? null;
            $this->vars['A'] = $V['vars']['A'] ?? $this->vars['A'];
        }
        $L = Voice::lines()[$key] ?? null;
        if (! $L) {
            return;
        }
        $slot = function (string $name, float $t) use ($L, $V, $key) {
            $s = $L[$name] ?? null;
            if (! $s) {
                return;
            }
            $chosen = $V['pick'][$name] ?? null;
            // The variants by their place in the table (voice.json), which every screen has: its words are not sent.
            $en = $V ? ($chosen[0] ?? null) : $this->fill($s['en']);
            $ar = $V ? ($chosen[1] ?? null) : $this->any($s['ar']);
            if ($en !== null || $ar !== null) {
                $this->out['lines'][] = ['at' => $t, 'en' => $en, 'ar' => $ar, 'x' => ! empty($s['x']), 'vars' => $this->vars, 'm' => $key, 's' => $name];
            }
        };
        $slot('pre', 0.05);
        $slot('key', $at['key'] ?? 0.4);
        $slot('post', $at['post'] ?? 0.75);
        $b = $V ? ($V['pick']['bubble'] ?? null) : $this->fill($L['bubble'] ?? []);
        $this->out['bubble'] = $b !== null ? ['say' => ['m' => $key, 's' => 'bubble', 'i' => $b], 'vars' => $this->vars] : '';
        // [UP2] In English the bubble says the commentator's English line, with the names.
        $said = null;
        foreach ($this->out['lines'] as $l) {
            if (($l['s'] ?? null) === 'key' && $l['en'] !== null) {
                $said = $l;
                break;
            }
        }
        foreach ($said ? [] : $this->out['lines'] as $l) {
            if ($l['en'] !== null) {
                $said = $l;
                break;
            }
        }
        $this->out['bubble_en'] = $said ? ['say' => ['m' => $key, 's' => $said['s'], 'lang' => 'en', 'i' => $said['en']], 'vars' => $this->vars] : '';
    }

    private function item(string $side, string $icon, mixed $name, mixed $label, array $extra = []): void
    {
        $this->out['items'][] = ['side' => $side, 'icon' => $icon, 'name' => $name, 'label' => $label, 'minute' => $this->out['minute']] + $extra;
    }

    private function set(string $scene, string $side, array $data, mixed $head, mixed $who, mixed $sub): void
    {
        $this->out = array_replace($this->out, ['scene' => $scene, 'side' => $side, 'data' => ['side' => $side] + $data, 'head' => $head, 'who' => $who, 'sub' => $sub]);
    }

    private function before(mixed $head, mixed $who, mixed $sub): void
    {
        $this->out['pre'] = ['head' => $head, 'who' => $who, 'sub' => $sub];
    }

    /** The player's name, or a text when he is not on the sheet. */
    private function nmOr(mixed $id, mixed $else): mixed
    {
        return $this->has($id) ? self::nm($id) : $else;
    }

    private function build(array $tick): array
    {
        $ev = $tick['events'];
        $moment = $tick['moment'] ?? [];
        $m = $tick['minute'] ?? [0, 0];
        $minute = ! empty($m[1]) ? "{$m[0]}+{$m[1]}'" : "{$m[0]}'";
        $this->out = ['scene' => null, 'data' => (object) [], 'head' => '', 'who' => '', 'sub' => '', 'pre' => null, 'items' => [], 'lines' => [], 'bubble' => '', 'bubble_en' => '', 'goal' => false, 'side' => 'home', 'minute' => $minute];
        $attack = self::first($ev, 'attack');
        $goal = self::first($ev, 'goal');
        $card = self::first($ev, 'card');
        $foul = self::first($ev, 'foul');
        $pen = self::first($ev, 'penalty');
        $fk = self::first($ev, 'free_kick');
        $corner = self::first($ev, 'corner');
        $sub = self::first($ev, 'sub');
        $injury = self::first($ev, 'injury');
        $period = self::first($ev, 'period');
        $stoppage = self::first($ev, 'stoppage');
        $shootout = self::first($ev, 'shootout');
        $action = null;
        foreach ($ev as $e) {
            if ($e['type'] === 'action' && in_array($e['action']['type'] ?? null, ['tactics', 'formation'], true)) {
                $action = $e;
                break;
            }
        }
        $V = $this->voice;
        $kind = $moment['kind'] ?? 'quiet';
        $drama = $moment['drama'] ?? null;
        $t = fn (string $k, mixed ...$v) => self::t($k, ...$v);
        $nm = fn ($id) => self::nm($id);
        $club = fn ($s) => self::club($s);
        $other = fn ($s) => self::other($s);
        $assign = function (array $v) {
            $this->vars = array_replace($this->vars, $v);
        };

        if ($kind === 'goal' && $goal) {
            $s = $goal['team'];
            $header = ($attack['quality'] ?? null) === 'header';
            $assign(['p' => $goal['scorer'], 'q' => $goal['assist'] ?? null, 'A' => $s]);
            $assist = $goal['assist'] ?? null;
            $this->set('goal', $s, ['drama' => $drama, 'no' => $this->no($goal['scorer']), 'passNo' => $assist ? $this->no($assist) : '', 'defNo' => $this->no($attack['defender'] ?? null), 'lane' => $attack['lane'] ?? null, 'quality' => $attack['quality'] ?? null, 'v' => $this->seed()],
                $t('هدف'), $nm($goal['scorer']), $assist ? $t('صناعة {v0}', $nm($assist)) : $club($s));
            $this->before($header ? $t('عرضية') : $t('هجمة خطيرة'), $nm($goal['scorer']), $club($s));
            $this->speak($header ? 'header' : 'goal', ['key' => 0.36, 'post' => 0.62]);
            $this->item($s, 'goal', $nm($goal['scorer']), $assist ? $t('هدف · صناعة {v0}', $nm($assist)) : ($header ? $t('هدف · رأسية') : $t('هدف')), ['goal' => true]);
            $this->out['goal'] = true;
        } elseif (($kind === 'penalty' || $kind === 'free_kick') && ($pen || $fk)) {
            $sp = $pen ?? $fk;
            $s = $sp['team'];
            $scored = (bool) $goal;
            $keeper = $sp['keeper'] ?? null;
            $assign(['p' => $sp['taker'], 'q' => $keeper, 'A' => $s]);
            $isPen = $kind === 'penalty';
            $result = $scored ? 'goal' : ($keeper ? 'save' : 'miss');
            $this->set($isPen ? 'penalty' : 'freekick', $s, ['no' => $this->no($sp['taker']), 'scored' => $scored, 'saved' => $result === 'save', 'v' => $this->seed()],
                $scored ? $t('هدف') : ($isPen ? $t('ركلة جزاء') : $t('ضربة حرة')), $nm($sp['taker']),
                $scored ? ($isPen ? $t('ركلة جزاء') : $t('ضربة حرة مباشرة')) : ($result === 'save' ? $t('تصدى {v0}', $nm($keeper)) : $t('خارج المرمى')));
            $this->before($isPen ? $t('ركلة جزاء') : $t('ضربة حرة'), $nm($sp['taker']), $t('المنفذ يستعد... والجميع ينتظر'));
            $this->speak($isPen ? ($scored ? 'penalty_goal' : 'penalty_save') : "free_kick_{$result}", ['key' => $isPen ? 0.49 : 0.51, 'post' => 0.72]);
            if (! empty($foul['player'])) {
                $this->item($other($s), 'foul', $nm($foul['player']), $isPen ? $t('تسبب في ركلة جزاء') : $t('خطأ'));
            }
            $this->item($s, $scored ? 'goal' : ($isPen ? 'penalty' : 'miss'), $nm($sp['taker']),
                $scored ? ($isPen ? $t('هدف · ركلة جزاء') : $t('هدف · ضربة حرة')) : ($result === 'save' ? ($isPen ? $t('ركلة جزاء ضائعة') : $t('ضربة حرة · تصدٍّ')) : $t('ضربة حرة ضائعة')), ['goal' => $scored]);
            $this->out['goal'] = $scored;
        } elseif (($kind === 'red' || $kind === 'yellow') && $card) {
            $s = $card['team'];
            $red = $kind === 'red';
            $second = ! empty($card['second_yellow']);
            $assign(['p' => $card['player'], 'A' => $s]);
            // [Sprint 42 B2] The cartoon's telling (the moment's drama): the tackle before it, the victim's number.
            $victim = $foul && $foul['team'] === $s ? ($foul['victim'] ?? null) : null;
            $this->set('card', $s, ['no' => $this->no($card['player']), 'victimNo' => $victim ? $this->no($victim) : '', 'type' => $red ? 'red' : 'yellow', 'second' => $second, 'drama' => $drama ?? 'tackle', 'v' => $this->seed()],
                $red ? $t('بطاقة حمراء') : $t('بطاقة صفراء'), $nm($card['player']), $second ? $t('الإنذار الثاني') : $club($s));
            $this->before($t('خطأ'), $nm($card['player']), $t('الحكم يقترب...'));
            $this->speak($second ? 'second_yellow' : ($red ? 'red' : 'yellow'), ['key' => 0.3, 'post' => 0.65]);
            $this->item($s, $red ? 'red' : 'yellow', $nm($card['player']), $red ? ($second ? $t('إنذار ثانٍ وطرد') : $t('بطاقة حمراء')) : $t('بطاقة صفراء'));
        } elseif ($kind === 'foul' && $foul) {
            // [Sprint 42 B3] A foul told as its own scene: the tackle, or a dive it gives.
            $s = $foul['team'];
            $dive = $drama === 'dive';
            $assign(['p' => $foul['player'], 'q' => $foul['victim'] ?? null, 'A' => $s]);
            $this->set('foul', $s, ['no' => $this->no($foul['player']), 'victimNo' => $this->no($foul['victim'] ?? null), 'drama' => $dive ? 'dive' : 'tackle', 'v' => $this->seed()],
                $dive ? $t('سقوط مثير!') : $t('خطأ'), $nm($foul['victim'] ?? null), $dive ? $t('والحكم يحتسب خطأ') : $t('عرقلة من {v0}', $nm($foul['player'])));
            $this->speak('foul', ['key' => 0.3, 'post' => 0.7]);
            $this->item($s, 'foul', $nm($foul['player']), $t('خطأ على {v0}', $nm($foul['victim'] ?? null)));
        } elseif ($kind === 'save' && $attack) {
            $s = $attack['team'];
            $keeper = $attack['keeper'] ?? null;
            $assign(['p' => ($attack['shooter'] ?? null), 'q' => $keeper, 'A' => $s]);
            $this->set('save', $s, ['drama' => $drama, 'no' => $this->no(($attack['shooter'] ?? null)), 'passNo' => ($attack['creator'] ?? null) !== ($attack['shooter'] ?? null) ? $this->no($attack['creator'] ?? null) : '', 'defNo' => $this->no($attack['defender'] ?? null), 'lane' => $attack['lane'] ?? null, 'quality' => $attack['quality'] ?? null, 'corner' => ($attack['result'] ?? null) === 'corner', 'v' => $this->seed()],
                $t('تصدٍّ رائع'), $this->nmOr($keeper, $t('الحارس')), $t('أمام {v0}', $nm(($attack['shooter'] ?? null))));
            $this->before($t('تسديدة'), $nm(($attack['shooter'] ?? null)), $club($s));
            $this->speak('save', ['key' => 0.35, 'post' => 0.62]);
            $this->item($other($s), 'save', $this->nmOr($keeper, $t('الحارس')), $t('تصدٍّ أمام {v0}', $nm(($attack['shooter'] ?? null))));
            if (($attack['result'] ?? null) === 'corner') {
                $this->item($s, 'corner', $club($s), $t('ركنية'));
            }
        } elseif ($kind === 'miss' && $attack) {
            $s = $attack['team'];
            $blocked = ($attack['result'] ?? null) === 'blocked';
            $def = $attack['defender'] ?? null;
            $assign(['p' => ($attack['shooter'] ?? null), 'q' => $def, 'A' => $s]);
            $how = $blocked ? null : ($V['how'] ?? $this->pick(['wide', 'wide', 'over', 'post']));
            $look = ['passNo' => ($attack['creator'] ?? null) !== ($attack['shooter'] ?? null) ? $this->no($attack['creator'] ?? null) : '', 'lane' => $attack['lane'] ?? null, 'quality' => $attack['quality'] ?? null, 'v' => $this->seed()];
            // [Sprint 42 F1] A blocked big chance told as a clearance off the line.
            if ($blocked && $drama === 'clearance') {
                $this->set('clearance', $s, ['no' => $this->no(($attack['shooter'] ?? null)), 'defNo' => $this->no($def)] + $look, $t('أنقذها من على الخط!'), $this->nmOr($def, $club($other($s))), $t('أمام {v0}', $nm(($attack['shooter'] ?? null))));
            } elseif ($blocked) {
                $this->set('blocked', $s, ['no' => $this->no(($attack['shooter'] ?? null)), 'defNo' => $this->no($def)] + $look, $t('صدّها الدفاع'), $nm(($attack['shooter'] ?? null)), $this->has($def) ? $t('تدخل {v0}', $nm($def)) : $club($other($s)));
            } else {
                $this->set('miss', $s, ['no' => $this->no(($attack['shooter'] ?? null)), 'defNo' => $this->no($def), 'how' => $how] + $look, $how === 'post' ? $t('القائم!') : $t('فرصة ضائعة'), $nm(($attack['shooter'] ?? null)),
                    $how === 'over' ? $t('فوق العارضة') : ($how === 'post' ? $t('ارتطمت بالقائم') : $t('بجانب القائم')));
            }
            $this->before($t('تسديدة'), $nm(($attack['shooter'] ?? null)), $club($s));
            $this->speak($blocked ? 'blocked' : ($how === 'post' ? 'post' : 'miss'), ['key' => 0.4, 'post' => 0.68]);
            $this->item($s, 'miss', $nm(($attack['shooter'] ?? null)), $blocked ? $t('تسديدة محجوبة') : ($how === 'post' ? $t('القائم') : $t('فرصة ضائعة')));
        } elseif ($kind === 'var' && $attack) {
            // [Sprint 35 C3] A goal ruled out after a look at VAR (the moment's var: offside or foul).
            $s = $attack['team'];
            $who = $attack['shooter'] ?? $attack['receiver'] ?? null;
            $reason = ($moment['var'] ?? null) === 'foul' ? 'foul' : 'offside';
            $assign(['p' => $who, 'A' => $s]);
            $this->set('var', $s, ['no' => $this->no($who), 'passNo' => ($attack['creator'] ?? null) !== $who ? $this->no($attack['creator'] ?? null) : '', 'defNo' => $this->no($attack['defender'] ?? null), 'lane' => $attack['lane'] ?? null, 'quality' => $attack['quality'] ?? null, 'reason' => $reason, 'v' => $this->seed()],
                $t('هدف ملغى'), $nm($who), $reason === 'offside' ? $t('تسلل بعد العودة للفار') : $t('خطأ قبل الهدف بعد العودة للفار'));
            $this->before($t('هدف!'), $nm($who), $club($s));
            $this->speak('var_'.$reason, ['key' => 0.78, 'post' => 0.9]);
            $this->item($s, 'flag', $nm($who), $reason === 'offside' ? $t('هدف ملغى · تسلل (الفار)') : $t('هدف ملغى · خطأ (الفار)'));
        } elseif ($kind === 'offside' && $attack) {
            $s = $attack['team'];
            $who = $attack['receiver'] ?? $attack['shooter'] ?? null;
            $assign(['p' => $who, 'A' => $s]);
            // [Sprint 42 F3] The offside trap: the back line steps up together.
            $trap = $drama === 'trap';
            $this->set($trap ? 'trap' : 'offside', $s, ['no' => $this->no($who)], $trap ? $t('مصيدة التسلل!') : $t('تسلل'), $nm($who), $club($s));
            $this->before($t('كرة خلف الدفاع'), $nm($who), $club($s));
            $this->speak('offside', ['key' => 0.38, 'post' => 0.66]);
            $this->item($s, 'flag', $nm($who), $t('تسلل'));
        } elseif ($kind === 'corner' && $corner) {
            $s = $corner['team'];
            $won = ($corner['won'] ?? null) !== false;
            $header = $attack['shooter'] ?? null;
            $assign(['p' => $header, 'q' => $corner['taker'], 'A' => $s]);
            $this->set('corner', $s, ['no' => $this->no($header ?? $corner['taker']), 'scored' => false, 'claim' => ! $won, 'v' => $this->seed()],
                $t('ركنية'), $nm($won && $header ? $header : $corner['taker']), $won ? $t('رأسية فوق العارضة') : $t('الحارس يمسك الكرة'));
            $this->before($t('ركنية'), $nm($corner['taker']), $club($s));
            $this->speak($won ? 'corner_header' : 'corner_claim', ['key' => 0.4, 'post' => 0.7]);
            $this->item($s, 'corner', $nm($won && $header ? $header : $corner['taker']), $won ? $t('ركنية · رأسية') : $t('ركنية'));
        } elseif ($kind === 'sub' && $sub) {
            $s = $sub['team'];
            $assign(['p' => $sub['in'], 'q' => $sub['out'], 'A' => $s]);
            $swap = ['j' => [$nm($sub['in']), $nm($sub['out'])], 'by' => ['r' => ' ⇄ ']];
            $this->set('sub', $s, ['inNo' => $this->no($sub['in']), 'outNo' => $this->no($sub['out'])], $t('تبديل'), $swap, $club($s));
            $this->speak('sub', ['key' => 0.2, 'post' => 0.7]);
            $this->item($s, 'sub', $swap, ($sub['reason'] ?? null) === 'injury' ? $t('تبديل اضطراري') : $t('تبديل'));
        } elseif ($kind === 'injury' && $injury) {
            $s = $injury['team'];
            $assign(['p' => $injury['player'], 'A' => $s]);
            $this->set('injury', $s, ['no' => $this->no($injury['player'])], $t('إصابة'), $nm($injury['player']), $club($s));
            $this->speak('injury', ['key' => 0.15, 'post' => 0.6]);
            $this->item($s, 'injury', $nm($injury['player']), $t('إصابة'));
            foreach ($ev as $e) {
                if ($e['type'] === 'sub' && $e['team'] === $s) {
                    $this->item($s, 'sub', ['j' => [$nm($e['in']), $nm($e['out'])], 'by' => ['r' => ' ⇄ ']], $t('تبديل اضطراري'));
                    break;
                }
            }
        } elseif ($kind === 'coach' && $action) {
            // The other side's instructions are not in the minute this screen sees (redact): "new instructions" only.
            $s = $action['team'];
            $a = $action['action'];
            if ($a['type'] === 'formation') {
                $what = $t('الطريقة {v0}', ['r' => (string) $a['formation']]);
            } else {
                $names = array_map(fn ($k) => self::TACTIC_NAMES[$k] ?? $k, array_slice(array_keys($a['tactics'] ?? []), 0, 2));
                $what = $names ? ['j' => $names, 'by' => ' و'] : null;
            }
            $tactic = $what ? $t('تعليمات: {v0}', $what) : $t('تعليمات جديدة');
            $assign(['p' => null, 'A' => $s, 'n' => $tactic]);
            // [Sprint 42 F7] Or the megaphone: the coach shouts, the players sweat. No instruction shown.
            if ($drama === 'rant') {
                $this->set('rant', $s, [], $t('المدرب غاضب!'), $t('مدرب {v0}', $club($s)), $tactic);
            } else {
                $this->set('coach', $s, ['tactic' => $tactic], $t('تعليمات المدرب'), $t('مدرب {v0}', $club($s)), $tactic);
            }
            $this->speak('coach', ['key' => 0.25, 'post' => 0.7]);
            $this->out['bubble'] = $this->out['bubble_en'] = $t('مدرب {v0} يتحرك: {v1}', $club($s), $tactic);
            $this->item($s, 'coach', $t('مدرب {v0}', $club($s)), $tactic);
        } elseif ($kind === 'whistle' && $period) {
            $score = $tick['score'];
            $sc = ['j' => [$club('home'), ['r' => "{$score['home']} - {$score['away']}"], $club('away')], 'by' => ['r' => ' ']];
            $big = ['halftime' => 'استراحة', 'fulltime' => 'النهاية', 'extra_time' => 'وقت إضافي', 'extra_time_half' => 'استراحة قصيرة', 'penalties' => 'ركلات الترجيح'][$period['name']] ?? '';
            $head = ['halftime' => 'نهاية الشوط الأول', 'fulltime' => 'نهاية المباراة', 'extra_time' => 'الوقت الإضافي', 'extra_time_half' => 'منتصف الوقت الإضافي', 'penalties' => 'ركلات الترجيح'][$period['name']] ?? '';
            $assign(['n' => $sc]);
            $st = fn ($side) => $tick['teams'][$side]['stats'] ?? [];
            $rows = array_map(fn ($r) => [$r[0], $st('home')[$r[1]] ?? 0, $st('away')[$r[1]] ?? 0], [['الهجمات', 'attacks'], ['التسديدات', 'shots'], ['على المرمى', 'on_target'], ['الركنيات', 'corners']]);
            // The score as the scoreboard reads it is the screen's (its language's order): the two numbers here.
            $this->set('whistle', 'home', ['big' => $head, 'score' => [$score['home'], $score['away']], 'stats' => $rows, 'name' => $period['name']], $big, '', $sc);
            $this->speak(['halftime' => 'halftime', 'fulltime' => 'fulltime', 'extra_time' => 'extra_time', 'penalties' => 'penalties'][$period['name']] ?? 'halftime', ['key' => 0.25]);
            $this->item('home', 'whistle', $head, $sc, ['center' => true]);
        } elseif ($kind === 'slip' && $attack) {
            // [Sprint 42 F8] A slip in the rain: on his belly, and the ball is gone.
            $s = $attack['team'];
            $carrier = $attack['carrier'] ?? null;
            $def = $attack['defender'] ?? null;
            $assign(['p' => $carrier, 'q' => $def, 'A' => $s]);
            $this->set('slip', $s, ['no' => $this->no($carrier), 'defNo' => $this->no($def)], $t('انزلاق!'), $nm($carrier), $this->has($def) ? $t('والكرة لـ{v0}', $nm($def)) : $club($other($s)));
            $this->item($s, 'foul', $nm($carrier), $t('انزلق في المطر'));
        } elseif ($kind === 'stoppage' && $stoppage) {
            $assign(['n' => ['r' => (string) $stoppage['added']]]);
            $this->set('board', 'home', ['plus' => $stoppage['added']], $t('الوقت بدل الضائع'), ['r' => '+'.$stoppage['added']], $t('دقائق'));
            $this->speak('stoppage', ['key' => 0.15]);
        } elseif ($kind === 'shootout' && $shootout) {
            $kicks = $shootout['kicks'] ?? [];
            $last = $kicks ? $kicks[count($kicks) - 1] : null;
            $assign(['n' => ['r' => "{$shootout['score']['home']} - {$shootout['score']['away']}"], 'A' => $last['team'] ?? 'home']);
            $this->speak('shootout', ['key' => 0.1]);
            if ($last) {
                $this->item($last['team'], ! empty($last['scored']) ? 'goal' : 'miss', $nm($last['taker'] ?? null), ! empty($last['scored']) ? $t('ترجيح · سجّل') : $t('ترجيح · أضاع'));
            }
        } elseif ($attack && ($this->served ? ($V['line'] ?? null) === 'attack' : $this->next() < 1932735284)) {
            // (The old R() < 0.45, in integers.)
            $assign(['A' => $attack['team']]);
            $this->speak('attack', ['key' => 0.1]);
        }
        if ((int) $tick['tick'] === 1) {
            // The kick-off line (no m: the screens read it as voice.json's kickoff).
            array_unshift($this->out['lines'], ['at' => 0, 'en' => 0, 'ar' => 0, 'x' => false, 'vars' => $this->vars]);
            array_unshift($this->out['items'], ['side' => 'home', 'icon' => 'whistle', 'name' => 'انطلاق المباراة', 'label' => ['j' => [$club('home'), $club('away')], 'by' => ['r' => ' - ']], 'minute' => "1'", 'center' => true]);
            foreach (['bubble', 'bubble_en'] as $b) {
                $this->out[$b] = $this->out[$b] ?: ['say' => ['m' => 'kickoff', 's' => 'bubble', 'i' => 0], 'vars' => $this->vars];
            }
        }
        // [X41] A small moment (the moment's brief): no scene, only its card and the commentator's one line.
        if (! empty($moment['brief'])) {
            $this->out['scene'] = null;
            $this->out['pre'] = null;
            $key = array_values(array_filter($this->out['lines'], fn ($l) => ($l['s'] ?? null) === 'key'));
            $this->out['lines'] = array_map(fn ($l) => ['at' => 0.1] + $l, $key ?: array_slice($this->out['lines'], 0, 1));
        }

        return $this->out;
    }
}
