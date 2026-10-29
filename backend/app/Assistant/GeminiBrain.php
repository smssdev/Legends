<?php

namespace App\Assistant;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * The Assistant Coach's mind [Sprint 22 B4]: Gemini on its free tier, given the game's guide and one tool, the reading
 * of the coach's own club (ClubReader), which it calls as it needs. The numbers it speaks are the ones our code read:
 * it understands the question, picks what to read and words the answer. Null when it cannot answer (no key, the
 * free day used up on every model, an error or a timeout), so the guide answers instead.
 */
class GeminiBrain
{
    public static function available(): bool
    {
        return (string) config('services.gemini.key') !== '' && config('services.gemini.models');
    }

    /**
     * @param  array  $contents  the conversation, oldest first: ['role' => 'user'|'model', 'text' => ...]
     * @param  callable|null  $read  fn (string $part): array, or null when the coach has no club here
     */
    public function answer(string $system, array $contents, ?callable $read): ?string
    {
        $turns = array_map(fn ($m) => ['role' => $m['role'], 'parts' => [['text' => $m['text']]]], $contents);
        $body = ['systemInstruction' => ['parts' => [['text' => $system]]],
            'generationConfig' => ['temperature' => 0.4, 'maxOutputTokens' => 1200]];
        if ($read) {
            $body['tools'] = [['functionDeclarations' => [[
                'name' => 'read_club',
                'description' => 'Reads one part of the coach\'s own club, exactly as his own screen shows it. '.ClubReader::ABOUT,
                'parameters' => ['type' => 'object', 'properties' => ['part' => ['type' => 'string', 'enum' => ClubReader::PARTS]], 'required' => ['part']],
            ]]]];
        }
        $reads = (int) config('game.manager_bot.reads_max');
        foreach (config('services.gemini.models') as $model) {
            $history = $turns;
            for ($round = 0; $round <= $reads; $round++) {
                $parts = $this->call($model, $body + ['contents' => $history]);
                if ($parts === null) {
                    continue 2; // this model cannot answer now: the next one
                }
                $calls = array_values(array_filter($parts, fn ($p) => isset($p['functionCall'])));
                if (! $calls || ! $read || $round === $reads) {
                    $text = trim(implode('', array_map(fn ($p) => $p['text'] ?? '', $parts)));

                    return $text === '' ? null : $text;
                }
                $history[] = ['role' => 'model', 'parts' => $parts];
                $history[] = ['role' => 'user', 'parts' => array_map(fn ($c) => ['functionResponse' => [
                    'name' => $c['functionCall']['name'],
                    'response' => ['content' => $c['functionCall']['name'] === 'read_club' ? $read((string) ($c['functionCall']['args']['part'] ?? '')) : ['error' => 'unknown tool']],
                ]], $calls)];
            }
        }

        return null;
    }

    /** One request to a model: its answer's parts, or null when it has none (limit, error, timeout). */
    private function call(string $model, array $body): ?array
    {
        try {
            $r = Http::timeout((int) config('services.gemini.timeout'))->acceptJson()
                ->withHeaders(['x-goog-api-key' => (string) config('services.gemini.key')])
                ->post(config('services.gemini.url')."/{$model}:generateContent", $body);
        } catch (ConnectionException) {
            return null;
        }
        if (! $r->successful()) {
            // 429: this model's free day (or minute) is used up. Logged without the key or the question.
            Log::warning('manager-bot: gemini answered '.$r->status(), ['model' => $model]);

            return null;
        }
        $parts = $r->json('candidates.0.content.parts');

        return is_array($parts) && $parts ? $parts : null;
    }
}
