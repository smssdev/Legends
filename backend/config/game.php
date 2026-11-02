<?php

// Calibratable game values (README.md section 3). Anything the engine reads
// is an integer (basis points for ratios) and is copied into each match's
// config_snapshot, so editing this file never changes a running match.

return [
    'match' => [
        'half_length' => 45, 'extra_half_length' => 15,
        'tick_ms' => 3000, 'halftime_seconds' => 30,
        // A match between friends kicks off this long after it is made or started: both coaches see the
        // preview and can change their plan before the whistle (the half-time break is as long).
        'kickoff_ms' => 30000,
        // A live minute is made this long before it starts, so both screens have it in time and play it together.
        'live_lead_ms' => 1200,
        // A coach's reactions in a match between friends: at most one this often.
        'reaction_gap_ms' => 1200,
        'reactions' => ['fire', 'clap', 'wow', 'laugh', 'angry', 'pray', 'unlucky', 'coming', 'easy', 'focus'],
        // The league broadcast [X24]: a boo or a cheer for one side at most this often per viewer, the side chat's
        // pace and length, and how many of each the live poll carries.
        'cheer_gap_ms' => 30000, 'chat_gap_ms' => 2000, 'chat_max' => 140, 'chat_kept' => 50, 'reactions_kept' => 20,
        // A breath after each scene before the next minute: the timeline and the clock on screen (not after quiet minutes).
        'scene_gap_ms' => 1800,
        // [UP17] A window before extra time and between its halves, as long as the others.
        'extra_time_tick_ms' => 2000, 'extra_time_break_seconds' => 30,
        'stoppage_first_half' => [1, 3], 'stoppage_second_half' => [2, 6], 'stoppage_extra_time' => [0, 2],
        'lock_minutes_before' => 5, 'referee_minutes_before' => 30,
        'subs' => 3, 'extra_time_subs' => 1,
        // [X42] The coach's windows, the owner's (2026-10-26): play stops this long after these minutes, and only then
        // (and before kick-off and at half-time) may a coach change his line-up, tactics or players (CoachWindows).
        'windows' => [15, 30, 60, 75], 'window_seconds' => 30,
        // [UP17] The owner's spec (11): a window ends as soon as both coaches are ready (a computer's side is ready
        // after ready_bot_ms). An injured player stops play for emergency_sub_seconds: his coach alone picks who comes
        // on (a substitution of him only); without a pick, the best on the bench (the engine, at the next minute).
        'ready_bot_ms' => 2000, 'emergency_sub' => true, 'emergency_sub_seconds' => 15,
        // كل النسب بنقاط الأساس (10000 = 100%) لأن المحرك يعمل بأرقام صحيحة فقط
        'favourite_win_rate_bp' => 6700,       // الهدف للمعايرة
        'captain_bonus_bp' => 100, 'captain_min_fitness' => 50,
        'home_base_bp' => 500,                     // ميزة أساسية لكل فريق على أرضه
        'home_pitch_bp' => [0, 100, 200, 300],    // فوقها حسب مرحلة أرضية الملعب [PLAN 2.9، السبرنت 29]
        // [X35] The live broadcast's pace, the owner's (2026-10-25): 18 minutes of football in one real minute, so a minute
        // lasts 60000/18 ms and a half two and a half minutes, the clock running on screen as on TV; an extra-time half
        // half a minute (15 minutes of 2000 ms) and the whole shootout half a minute. A match made with these keys plays
        // every minute at this fixed length (MomentClock); one made before keeps moment_ms below (its config_snapshot).
        'minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000,
        // [X41] The broadcast as on TV, the owner's (2026-10-26), in place of the fixed pace above for the matches made
        // from now on: fewer scenes and each one its real length (MomentClock), the commentator finishing what he says.
        // A half about three and a half minutes: quiet minutes pass quickly, a goal takes 20 s with its replay; a small
        // chance ('brief') is its card and one line. MomentClockTest checks a match's length.
        'broadcast_ms' => [
            'quiet' => 2200, 'attack' => 2800, 'brief' => 4200, 'stoppage' => 5000, 'whistle' => 10000, 'coach' => 5000,
            'sub' => 6000, 'injury' => 6000, 'offside' => 4200, 'corner' => 8000, 'miss' => 10000, 'save' => 11000,
            'goal' => 20000, 'yellow' => 8500, 'red' => 11000, 'free_kick' => 11000, 'free_kick_goal' => 19000,
            'penalty' => 14000, 'penalty_goal' => 20000,
            // [Sprint 36 F5] A half's end (whistle, 10 s): its board, then the walk to the tunnel or the handshakes.
            // [Sprint 35 C3] A goal ruled out by VAR: the ball in, the check, no goal, and the coaches.
            'var' => 16000,
        ],
        // مدة عرض كل دقيقة حسب لقطتها [MATCH_VIEW 4.5، MOMENTS.md]: الهادئة سريعة، واللقطة تأخذ وقتها
        'moment_ms' => [
            // A whole match plays in about three minutes (PLAN 2.24): quiet minutes fly by, each scene has its length.
            'quiet' => 450, 'attack' => 1100, 'stoppage' => 2200, 'shootout' => 2600, 'whistle' => 3200, 'coach' => 4200,
            'offside' => 4000, 'miss' => 7000, 'save' => 7600, 'corner' => 4200, 'goal' => 8400,
            'yellow' => 4400, 'red' => 5600, 'free_kick' => 5800, 'free_kick_goal' => 7000,
            'penalty' => 6600, 'penalty_goal' => 7400, 'sub' => 3800, 'injury' => 3800, 'var' => 8600,
        ],
    ],
    'league' => [
        'lock_last_bp' => 2500, 'absence_days' => 3,
        'absence_warning_hours' => 48, 'max_active_teams' => 8,   // the coach's slots: a team in each of up to 8 leagues [X18; Sprint 24: 8]
        // [Sprint 24 B3] The slots open with the account's age: `open` from the start, then one every `every_days`;
        // or at once, in order, for unlock_coins (by slot number; the owner's first model, 2026-10-29). Teams held before it all stay.
        'slots' => ['open' => 2, 'every_days' => 10, 'unlock_coins' => [3 => 50, 4 => 100, 5 => 150, 6 => 200, 7 => 250, 8 => 300]],
        'vacation_max_days' => 7, 'vacation_per_season' => 1,
        'min_teams' => 4, 'max_teams' => 20, 'code_length' => 8,
        'reference_season_days' => 37, 'strength_top_players' => 18,
        // What the owner may choose [PLAN 2.3]. [UP9, UP17] The owner's spec (2026-10-26): one round a day; two days
        // to get ready in a free league, four or six in a customized one; at least half the real league's clubs.
        'prep_days' => [2, 6], 'prep_days_options' => [2, 4, 6], 'free_prep_days' => 2, 'rounds_per_day' => [1, 1], 'starts_within_days' => 7,
        'min_teams_share_bp' => 5000,
        // [UP9] A league with the free settings costs nothing; a customized one this many coins per club, once. Its
        // rounds start at default_kickoff in the creator's own time zone unless the owner picks the hour (customized).
        'custom_coins_per_club' => 20, 'default_kickoff' => '21:00',
        // [Sprint 27 B1] Days off a week with no matches (e.g. Friday), chosen before the start, free.
        'rest_days_max' => 3,
        // Tries at a league code per account each minute [PLAN 2.1]
        'join_attempts_per_minute' => 10,
    ],
    // [Sprint 27 B2] A match moved by whole hours on its own day when both coaches agree: both times at least
    // lead_minutes away (the referee comes 30 minutes before), the new one gap_minutes from either club's other matches,
    // and at most max_hours either way.
    'match_moves' => ['lead_minutes' => 60, 'gap_minutes' => 60, 'max_per_fixture' => 2, 'max_hours' => 6],
    // League matches [PLAN 2.8, 2.12] (read by App\League, not by the engine).
    'matches' => [
        'missed_live_minutes' => 10,      // up to this late a match still starts live; later it is simulated at once
        'rest_recovery' => 30,            // fitness back for a player who rests in his club's match
        'played_recovery' => 8,           // and for one who played, between that match and the next [X21]
        'injury_matches' => [1, 3],       // an injury keeps a player out this many of his club's matches
        'red_card_matches' => 1,
        'runner_sleep_ms' => 200,         // how often matches:run looks at the clock
        // [X45] And with no match live and none starting within runner_busy_ahead_s: every runner_idle_ms, so a free
        // server's tenth of a CPU and the trips to Supabase are kept for the players (35 queries a second before).
        'runner_idle_ms' => 2000, 'runner_busy_ahead_s' => 90,
        // A live match more than this behind (the runner was stopped) goes on from now.
        'stalled_ms' => 5000,
        // A coach whose screen has not asked for his match in this long is away: his assistant manages [ENGINE 7].
        'assistant_after_ms' => 30000,
        // One runner at a time: another one waits this long after the first one stops before it takes over.
        'claim_seconds' => 10,
        // The assistant's live reading to his coach [ENGINE 8.2]: about this often in minutes of play, and at once
        // after a goal, a red card or a line under 60% fitness.
        'reading_minutes' => 15,
    ],
    // [Sprint 30 Q6] fits_starters: a line's usual starters; a listed player stronger than the weakest of them «fits».
    'economy' => ['fits_starters' => ['gk' => 1, 'def' => 4, 'mid' => 3, 'att' => 3],
        'starting_budget' => 3_000_000,
        'starting_budget_min' => 1_000_000, 'starting_budget_max' => 10_000_000,   // what the owner may choose
        'handover_min' => 500_000,               // والحد الأعلى = starting_budget
        // من جهة المدرب
        'buy_from_pool_bp' => 10000, 'sell_to_pool_bp' => 7000,
        'buy_from_bot_bp' => 12500,
        'human_trade_min_bp' => 5000, 'human_trade_max_bp' => 20000,
        'pair_net_transfer_cap_bp' => 2500,   // من ميزانية البداية، لكل ناديين في الموسم
        'same_pair_player_moves_per_season' => 1,
        'offer_hours' => 48,                // an offer between coaches waits this long for an answer
        'debt_rounds_before_forced_sale' => 3,
        'min_squad' => 16,                  // a forced sale never leaves fewer players than this
        'bot_min_squad' => 18, 'min_keepers' => 2,   // a bot club sells no lower than this [PLAN 2.7]
        'pool_size' => 300,
        // The pool renews every pool_hours from the players of every league in the data [X6], as strong as this
        // league: from its pool_level_from_pct percentile of strength to its best, in pool_lines shares per line.
        // [UP11] The owner's spec (5): the offers renew every 2 to 4 hours, with a countdown on the market.
        'pool_hours' => 3, 'pool_level_from_pct' => 40,
        // [UP11] Buying: the club's cash pays the price, and the coach 1 or 2 coins to register the deal (2 from
        // doc_big_from). With at least compensate_min_bp of the price in cash, the rest may be paid in coins:
        // one coin for each money_per_coin missing (60M with 40M in cash: 20M, so 100 coins).
        'transfer_doc_coins' => 1, 'transfer_doc_coins_big' => 2, 'doc_big_from' => 10_000_000,
        'compensate_min_bp' => 5000, 'money_per_coin' => 200_000,
        'pool_lines' => ['gk' => 10, 'def' => 30, 'mid' => 35, 'att' => 25],
        // [UP11] The owner's spec (5): from mid-season (pool_stars_from_bp of the rounds played) every renewal brings
        // pool_stars stars from the parallel leagues, up to pool_stars_above above the league's best player.
        'pool_stars' => 6, 'pool_stars_from_bp' => 5000, 'pool_stars_above' => 4,
        // Selling [X6]: the instant sale pays the full value for coins (in a fair league, this share of the value);
        // a listing asks up to the sale cap (130% of the value, the value alone for a player the club bought), and a
        // buyer from outside takes it after a wait from this table (price in bp of value => hours, before the
        // season's scale), give or take jitter_bp.
        'quick_sale_fee_bp' => 1000,
        // [Sprint 23, the owner's decision 2026-10-29] The cap is 250% of the value (OSM's), and the wait grows
        // steeply past the value: about a day at 150%, four at 200%, eight at the cap. The buyer's demand then
        // moves it by the player's age and rating (demand: wait in bp, below 10000 sooner): the young and the
        // good-but-not-great go first, the old and the weak last. A player the club bought still sells at his value.
        'sale_cap_bp' => 25000,
        'virtual_buyer' => ['hours_at_bp' => [5000 => 1, 10000 => 6, 15000 => 24, 20000 => 96, 25000 => 192], 'jitter_bp' => 2000,
            // age (up to) => wait bp, and rating (up to) => wait bp
            'demand_age' => [21 => 7000, 23 => 8000, 27 => 10000, 30 => 12500, 99 => 16000],
            'demand_overall' => [64 => 14000, 69 => 11000, 85 => 8500, 99 => 10000]],
        // [Sprint 23] What keeps the economy whole at 250%, with age in training and the events: a club lists at most
        // max_listings players at a time, and its profit selling outside the league in a season (over what it paid,
        // or the value at the season's start for its own; with what its listings already ask over it) stays under
        // this share of the league's money scale, about a season's gate and sponsors (sim:economy). The cap of a
        // listing and the instant sale's pay shrink to fit (App\Market\Buyer).
        'max_listings' => 4,
        // [X62] The sell-on clause a buyer may promise the selling coach: up to this share of the player's next sale.
        'sell_on_max_bp' => 2000,
        'sale_profit_bp_per_season' => 500,
        // Sprint 23 (first numbers, checked by sim:economy; docs/sprints/sprint-23.md). "Scale" is the league's
        // average squad value when it starts, so a small league's money is small like its prices.
        // Wages: this share of the squad's value over a season, paid each league round.
        'wages_bp_per_season' => 300,
        // A home match brings this share of the scale over a season (split over the home matches): sponsors
        // take sponsor_share of it, the tickets the rest at full attendance.
        'home_income_bp_per_season' => 450,
        'sponsor_share_bp' => 5500,
        // The four sectors of the stadium, each with its sponsor, and its share of the sponsors' money.
        'sectors' => ['main' => 3500, 'opposite' => 2500, 'north' => 2000, 'south' => 2000],
        // The sponsor offers per sector: a fixed part of the sector's money each home match, plus a part on a home win.
        'sponsor_offers' => [
            'steady' => ['fixed_bp' => 10000, 'win_bp' => 0],
            'bonus' => ['fixed_bp' => 7000, 'win_bp' => 7000],
            'ambitious' => ['fixed_bp' => 4000, 'win_bp' => 13000],
        ],
        // The stadium at stage 0 (Sprint 29 builds on it): seats, and attendance from the club's strength in its league.
        'stadium' => ['capacity' => 20000, 'attendance_min_bp' => 6000, 'attendance_max_bp' => 10000],
        // [X61] The ticket price the coach sets, four levels: the seat's price (bp of the usual) and the crowd it
        // moves (bp of the seats, up to full). Cheap fills the stands, dear empties them, so the best level earns about
        // 5% more than the usual one, and only for a club that fills its stadium: the economy stays closed.
        'ticket_levels' => [
            'popular' => ['price_bp' => 7500, 'attendance_bp' => 1500],
            'normal' => ['price_bp' => 10000, 'attendance_bp' => 0],
            'high' => ['price_bp' => 12500, 'attendance_bp' => -1500],
            'premium' => ['price_bp' => 15000, 'attendance_bp' => -3000],
        ],
        // A league match's result, as a share of the scale: a bonus for a win, a smaller one for a draw, and a
        // deduction for a loss [X14].
        'win_bonus_bp' => 8, 'draw_bonus_bp' => 3, 'loss_penalty_bp' => 2,
        // Season prizes as a share of the scale: the league by place (from the champion down), and the cup.
        'league_prize_bp' => [100, 70, 50, 35, 25, 15, 10, 5],
        'cup_prize_bp' => ['winner' => 50, 'final' => 25, 'sf' => 10],
        // sim:economy's targets for a season: no mass bankruptcy, and no clear inflation.
        'sim_targets' => ['broke_%_max' => 10, 'median_end_ratio' => [0.7, 2.5], 'money_growth_max' => 2.0],
    ],
    // A player's value in club money [PLAN 2.6]: from his rating, then his age, line and room to grow.
    // Integers only; each multiplier in basis points. Calibrated in Sprint 11 (docs/sprints/sprint-11.md).
    'valuation' => [
        // rating => value; between two points the value runs in a straight line
        'by_overall' => [40 => 10_000, 50 => 30_000, 55 => 60_000, 60 => 120_000, 65 => 250_000, 70 => 500_000,
            75 => 1_100_000, 80 => 2_500_000, 85 => 6_000_000, 88 => 11_000_000, 91 => 20_000_000, 99 => 45_000_000],
        // age => multiplier from that age up
        'age_bp' => [0 => 13000, 20 => 12500, 22 => 11500, 24 => 10000, 28 => 9000, 30 => 8000, 31 => 7000, 32 => 6000, 33 => 5000, 34 => 4000],
        'line_bp' => ['gk' => 8000, 'def' => 9000, 'mid' => 10000, 'att' => 11000],
        'potential_bp_per_point' => 150,      // each point of room to grow
        'round_to' => [100_000 => 1_000, 1_000_000 => 10_000, PHP_INT_MAX => 100_000],
    ],
    // Training [PLAN 2.8, Sprint 27]: a session every tick_hours (scaled by the season's length), about
    // season_sessions of them in a season. Calibrated by sim:training (docs/sprints/sprint-27.md).
    // [Sprint 21 E6, the owner's decision 2026-10-28] Every session lasts tick_hours, the same in every league (no
    // longer scaled by the season's length), and a line trains only with its coach in the technical staff.
    'training' => ['slots' => 4, 'tick_hours' => 6, 'progress_scale' => 10000, 'season_sessions' => 111,
        // rating => about how many sessions a +1 takes; between two points in a straight line
        'sessions_by_overall' => [55 => 4, 65 => 6, 75 => 14, 80 => 19, 85 => 23, 89 => 25, 92 => 30, 99 => 40],
        'step_bp' => [5000, 15000],      // each session moves the bar by half to one and a half of the average
        // [Sprint 23] Age, the strongest factor: each session's step in bp by the player's age (up to): the young
        // grow fastest, from 29 slower and slower.
        'age_step_bp' => [19 => 13000, 21 => 11500, 23 => 10000, 26 => 8500, 28 => 7500, 30 => 6000, 32 => 4500, 99 => 3500],
        'cost_bp_per_season' => 40,      // one slot busy all season costs this share of the league's money scale
        'season_gain_target' => [3, 5],
        // Open training [X16]: no stop at the potential. Above it each +1 takes this many times the sessions, one more
        // time for every point beyond (at the potential ×3, one above ×5...), up to the ceiling.
        'over_potential_factor' => 2, 'ceiling' => 99],
    // [Sprint 23] The admin's timed events (App\TimedEvents\TimedEvents): each runs from its start to its end, set in the
    // admin panel, in every league or in one. power is per kind (with its default and range), count the special
    // players each market renewal brings while it runs.
    'timed_events' => ['max_days' => 14, 'kinds' => [
        // The outside buyers and the market's renewal this many times as fast (bp: 20000 = twice).
        'madness' => ['power' => 20000, 'min' => 12500, 'max' => 40000],
        // Every training step this many times as big (bp).
        'progression' => ['power' => 20000, 'min' => 12500, 'max' => 30000],
        // The world's players (the pool) this much cheaper (bp of the price).
        'discount' => ['power' => 2500, 'min' => 500, 'max' => 5000],
        // Special offers: count players of each renewal at this discount (bp), until the next renewal.
        'offers' => ['power' => 3000, 'min' => 1000, 'max' => 5000, 'count' => 8, 'count_max' => 20],
        // Players of the week: count players of each renewal in form, this many points above their rating (it stays with them).
        'in_form' => ['power' => 3, 'min' => 1, 'max' => 5, 'count' => 6, 'count_max' => 20],
        // Legends: count players of each renewal from the league's best up to this many points over it, at price_bp of their value.
        'legends' => ['power' => 8, 'min' => 1, 'max' => 15, 'count' => 4, 'count_max' => 10, 'price_bp' => 15000],
    ]],
    // [UP10] The training camp and secret training are gone (the owner's spec, 4, 2026-10-26): their tables stay, unused.
    // The live broadcast's server side [Sprint 21 E8], outside game.match so it never enters a match's snapshot.
    'live' => [
        // [E8.6] Back after a gap: the events of at most this many missed minutes in one reply (the summary covers the rest).
        'missed_max_minutes' => 30,
        // [E8.7] The degradation ladder under load (App\League\LiveDegrade): 1 drops the catch-up summary, 2 the
        // commentator's voice, 3 tells the screens to poll every poll_ms. Also `php artisan matches:degrade`.
        // [Sprint 20 S6] And by itself: the smoothed lateness of the runner's steps (ms) past up_ms[0], [1] or [2]
        // raises it to 1, 2 or 3 at once; it comes down a step after hold_s under half the level's threshold.
        'degrade' => ['level' => (int) env('GAME_DEGRADE_LEVEL', 0), 'poll_ms' => 3000,
            'auto' => ['enabled' => (bool) env('GAME_DEGRADE_AUTO', true), 'up_ms' => [1500, 3000, 6000], 'hold_s' => 120]],
    ],
    // [Sprint 21 E8.7] logs:trim (hourly): a log over this size is kept as NAME.log.1 and starts again.
    'logs' => ['max_mb' => 20],
    // [Sprint 21 E8.1] sim:perf: one MatchMinute through simulateTick may take this long at p99 (one core). Tools only.
    'perf' => ['tick_budget_ms' => 20],
    // Calibration targets for sim:balance (docs/ENGINE.md 9.1). Read by the tools only, never by the engine,
    // so they are not in a match's config_snapshot. Each is [min, max] per match (percentages as 0..100).
    'balance' => [
        'league' => 'Premier League',
        'nightly' => (bool) env('GAME_NIGHTLY_BALANCE', false),   // the home server turns it on (docs/HOME_SERVER.md)
        'favourite_gap_points' => 18,          // the strongest club against one this many points weaker
        'targets' => [
            'goals/match' => [2.6, 2.9],
            '0-0_%' => [6, 9],
            'home_win_%' => [42, 48], 'draw_%' => [22, 28], 'away_win_%' => [27, 33],
            'shots/team' => [10.5, 13.5], 'on_target/team' => [4, 5],
            'yellow/match' => [3.5, 4.5], 'red/match' => [0.07, 0.15],
            'penalties/match' => [0.2, 0.3], 'injuries/match' => [0.2, 0.3], 'offsides/match' => [2, 4],
            'late_goals_%' => [22, 27],
            'favourite_win_%' => [65, 70],
        ],
        // Knob isolation (ENGINE 9.2): moving one knob from low to high on equal teams must move these the
        // given way (+1 up, -1 down) and leave the win rate within max_win_shift points.
        'knobs' => [
            'pressing' => ['from' => 0, 'to' => 100, 'expect' => ['presses_won_home' => 1, 'yellow_home' => 1, 'fitness_65_home_%' => -1]],
            'tempo' => ['from' => 0, 'to' => 100, 'expect' => ['attacks_home' => 1, 'fitness_65_home_%' => -1]],
            'tackling' => ['from' => 0, 'to' => 3, 'expect' => ['yellow_home' => 1, 'red_home_%' => 1]],
            'style' => ['from' => 0, 'to' => 100, 'expect' => ['goals_home' => 1, 'counters_away' => 1]],
            'trap' => ['from' => 0, 'to' => 1, 'against' => ['plan' => 'long'], 'expect' => ['offsides_away' => 1]],
            // Morale [X25] is not a tactic: from 40 to 90 it must win more, by a few points, not by a class.
            'morale' => ['field' => 'morale', 'from' => 40, 'to' => 90, 'min_shift' => 2, 'max_shift' => 10, 'expect' => ['goals_home' => 1, 'goals_away' => -1]],
            // Chemistry [X22] likewise, from 40 to 100.
            // A bought referee [X28]: more points for the side that paid, but not a class.
            'bribed' => ['field' => 'bribed', 'from' => 0, 'to' => 1, 'min_shift' => 1, 'max_shift' => 8, 'expect' => ['yellow_home' => -1, 'yellow_away' => 1]],
            'chem' => ['field' => 'chem', 'from' => 40, 'to' => 100, 'min_shift' => 2, 'max_shift' => 10, 'expect' => ['goals_home' => 1, 'goals_away' => -1]],
        ],
        'max_win_shift' => 3,
    ],
    // Chemistry [X22]: each player is linked to his `neighbours` nearest team-mates; a link is worth its colour,
    // and green also comes from `together_matches` played together for the club. The engine's effect is in engine.chemistry_*.
    'chemistry' => [
        'neighbours' => 2,
        'link_value' => ['green' => 100, 'yellow' => 65, 'red' => 25],
        'together_matches' => 15,
    ],
    'engine' => [
        'version' => 11,
        // القيم مبدئية وتُضبط بأدوات المحاكاة (docs/ENGINE.md 9)
        'overall_weight' => 60, 'attributes_weight' => 40,
        'attack_rate_bp' => 4500,                 // هجمات في الدقيقة للفريقين معاً
        'phase_floor_bp' => 800, 'phase_ceiling_bp' => 9200,
        'funnel_target_bp' => ['build' => 8000, 'progress' => 7500, 'create' => 7500],
        // خطة الهجوم × شكل دفاع الخصم (عالٍ، متوسط، منخفض) [Sprint 21 E5.4]: تغيّر احتمال التقدم وصنع الفرصة
        // (من 10000) لا قوة اللاعبين، والتسديد البعيد بلا صنع فرصة فيأخذها مرتين في التقدم. والخطة العادية (التمرير
        // على الشكل المتوسط) +600، فقاعدتا التقدم والصنع أقل بـ 600 لتبقى المباراة العادية كما هي.
        'matchup_bp' => [
            'counter' => [900, 0, -900], 'long_balls' => [600, -300, -300],
            'passing' => [-300, 600, -300], 'wings' => [-600, 0, 600],
            'long_shots' => [-600, -300, 900],
        ],
        'tackling_bonus_cp' => [0, 20, 30, 40],   // قانوني، عادي، حماس، خشونة
        // Fatigue [X21]: per minute, in hundredths of a per cent, for a player of stamina 70. About 18% in a normal
        // match (pressing and tempo at 50), about 24% with the press and the tempo high. Under tired_fit the
        // injuries come tired_injury_bp as often.
        'fitness_drain_base' => 12, 'fitness_drain_pressing_max' => 20, 'fitness_drain_tempo_max' => 8,
        'tired_fit' => 5500, 'tired_injury_bp' => 30000,
        'red_card_drain_bp' => 11500,
        // Chemistry [X22]: from chemistry_high the phases (passing, counters, cover) gain chemistry_high_bp, from
        // the first value at the line up to the second at 100; under chemistry_low they lose up to chemistry_low_bp at 0.
        // Morale [X25]: each point over or under 50 moves the progress and the chance creation by this much, the
        // attack's against the defence's. A side without a reading (the simulator) is neutral.
        'morale_bp' => 6,
        // A bought referee [X28]: the briber's own cards at this share of the usual, its opponent's at this, and the
        // penalties it is given at this.
        'bribe_own_card_bp' => 5000, 'bribe_rival_card_bp' => 16000, 'bribe_penalty_bp' => 30000,
        'chemistry_high' => 85, 'chemistry_high_bp' => [300, 700], 'chemistry_low' => 50, 'chemistry_low_bp' => 600,
        'trailing_push_from_minute' => 60,
        'tactics_max_win_bp' => 5800,             // شرط sim:matrix
        'counter_edge_min_pts' => 3,              // شرط sim:matrix: الأضعف بخطة كتاب التكتيك يأخذ 3 نقاط (من 100) أكثر من خططه الأخرى
        'live_reading_every_minutes' => 15,
        // Phase duels: success = base + slope × (attack − defence in rating points), clamped to floor..ceiling
        'phase_base_bp' => ['build' => 8000, 'progress' => 6900, 'create' => 7600, 'header' => 3500],
        'phase_slope_bp' => 17,              // per rating point of difference
        'share_slope_bp' => 30,              // initiative share per point of midfield difference
        'home_share_bp' => 450,              // the home side has the ball more (of 10000, on its own ground)
        'style_share_bp' => 5,               // initiative share per point of attacking style over the opponent's
        'goal_base_bp' => ['big' => 2000, 'normal' => 600, 'half' => 285, 'long' => 1000, 'header' => 450],
        'goal_slope_bp' => 12,               // per point of shooter − keeper
        'penalty_goal_bp' => 7600, 'free_kick_goal_bp' => 700,
        'on_target_bp' => 3700, 'corner_after_save_bp' => 3000,
        'press_bonus_cp' => 4,               // defence bonus in build-up per pressing point above 50
        'tempo_precision_cp' => 3,           // own precision loss per tempo point above 50
        'counter_base_bp' => 3200, 'counter_plan_bp' => 1600, 'counter_bonus_cp' => 150,
        'trap_base_bp' => 3500, 'trap_fail_bonus_cp' => 600,
        'foul_bp' => [800, 1300, 1900, 2700], // per lost duel, by tackling level
        'card_bp' => [1300, 1950, 2850, 3900], // per foul, by tackling level
        'referee_bp' => [7000, 10000, 13500], // soft, medium, strict
        'dogso_red_bp' => 120,
        'second_yellow_spare_bp' => 8000,    // a booked player's next yellow is let go this often
        'midfield_foul_bp' => 2300,          // per quiet minute: ordinary fouls away from danger
        'midfield_card_pct' => 110,           // of the card chance for a foul near goal (card_bp)
        'penalty_share_bp' => 700,           // fouls at the box that are inside it
        'progress_free_kick_bp' => 5000,     // fouls in midfield that still leave a free kick in range
        'offside_bp' => ['long' => 1900, 'counter' => 1500, 'passing' => 560, 'wings' => 440, 'shots' => 250],
        'injury_bp' => [170, 250, 380, 600],
        'man_down_cp' => 350,
        'captain_cp' => 80,
        'trailing_push_bp_per_minute' => 50,
        'late_open_bp_per_minute' => 30,     // the game opens up after minute 75
        'late_lapse_cp_per_minute' => 14,    // tired defences lose concentration after minute 70
        'stoppage' => [1 => [1, 3], 2 => [2, 6], 3 => [0, 2], 4 => [0, 2]],
        'bot_personalities' => ['giants', 'defenders', 'pressers', 'hard', 'wingers', 'adaptive'],
    ],
    'clock' => ['dev_round_minutes' => 1, 'file' => env('GAME_CLOCK_FILE', storage_path('app/game-clock.json'))],
    'simulator' => ['enabled' => (bool) env('SIMULATOR_ENABLED', env('APP_ENV', 'production') !== 'production')],
    // The game's names (owner's decision, 2026-10-26, X44): لعبة المدرب الأسطورة (GLM, Game Legend Manager), and its premium currency الكوينز.
    'brand' => ['name' => 'لعبة المدرب الأسطورة', 'short' => 'GLM', 'name_latin' => 'Game Legend Manager', 'premium_currency' => 'الكوينز'],
    // [X61] The oldest app still served comes from the same source as the game's version (APP_VERSION), not a number of
    // its own: the server said 0.1.0 and asked for apps from 1.0.0 at once. MIN_APP_VERSION raises it when an app ships.
    'app' => ['min_version' => env('MIN_APP_VERSION', env('APP_VERSION', '0.1.0')), 'token_ttl_days' => 30],
    // The coach's level on the home screen [X18]: points per win, draw and trophy; each level asks level_step more.
    'career' => ['xp_win' => 3, 'xp_draw' => 1, 'xp_trophy' => 30, 'xp_prediction' => 1, 'level_step' => 20],
    // [Sprint 25] The coach's rating (App\Season\CoachRating): points that rise and fall with every league or cup match.
    // A result's base (win, draw, loss), and per step of step_cp (strength centi-points, up to max_steps) the opponent was
    // stronger, per_step more (or, weaker, less): beating a stronger side earns more, losing to a weaker one costs more.
    // away for a win or draw away, big_win for winning by big_margin goals or more, and the trophies' points by position.
    // The tiers by their first points, each but the last in three divisions (III, II, I); a tier once reached is
    // kept, so the points never fall below its start (nor below zero).
    'rating' => ['win' => 20, 'draw' => 4, 'loss' => -14, 'per_step' => ['win' => 3, 'draw' => 3, 'loss' => 2], 'step_cp' => 200, 'max_steps' => 5,
        'away' => 2, 'big_win' => 3, 'big_margin' => 3, 'trophies' => ['league' => [1 => 100, 2 => 40, 3 => 20], 'cup' => [1 => 60, 2 => 20]],
        'tiers' => ['prospect' => 0, 'tactician' => 150, 'professional' => 400, 'elite' => 800, 'mastermind' => 1400, 'icon' => 2200, 'legend' => 3200],
        'divisions' => 3, 'recent' => 10],
    // [Sprint 30 G4] The achievements and their goals (App\Season\Achievements), in the order they show. professional and
    // legend are the rating's tiers (their goal is the tier's points, game.rating.tiers).
    'achievements' => ['first_win' => 1, 'matches' => 100, 'wins' => 25, 'first_title' => 1, 'league_title' => 1, 'cup_title' => 1,
        'professional' => 0, 'legend' => 0, 'friendlies' => 10, 'idea' => 1, 'invites' => 3],
    // Support [X13]: WhatsApp (the number in international form, digits only) and Telegram (the username, without @),
    // for account and sign-up problems and ideas. A channel left empty has no button.
    'support' => ['whatsapp' => env('SUPPORT_WHATSAPP'), 'telegram' => env('SUPPORT_TELEGRAM'),
        'message' => 'مرحباً، أحتاج مساعدة في لعبة المدرب الأسطورة: '],
    // The account [X4, 2026-10-24]: a holiday for every league at once, of up to vacation_max_days, and the next one
    // after vacation_rest_days from its end; the picture's largest upload (kilobytes) and its side (pixels).
    // How the coach watches [X10]: the two simulators. Unity opens only once its web build is deployed. The Arabic
    // commentators were deleted (2026-10-27); their setting stays accepted in the API (its contract), and is unused.
    // [Sprint 26] The characters (README section 0, 2026-10-30): the coach's look on the touchline (C1 to C3 of the
    // draft), a goal against from late_minute on angers instead of saddening, and a win by big_margin surprises.
    'characters' => ['looks' => ['C1', 'C2', 'C3'], 'default_look' => 'C1', 'late_minute' => 85, 'big_margin' => 3],
    'viewing' => ['commentators' => ['base', 'voice-1', 'voice-2', 'voice-3', 'voice-4', 'voice-5', 'voice-6', 'voice-7'], 'default_commentator' => 'voice-6',
        'match_views' => ['cartoon', 'unity'], 'unity_ready' => (bool) env('UNITY_BUILD', false)],
    // [UP6] The welcome coins, paid once the account is verified by a WhatsApp code, which lasts verify_code_days.
    // [UP13] The owner's spec (7): an account unused inactive_days in a row (no holiday) is deleted, warned at
    // warn_after_days. A holiday of up to auto_vacation_days is granted at once, auto_vacations_per_season times in
    // a season of reference_season_days with vacation_cooldown_days between them; a longer one (up to
    // long_vacation_max_days) waits for the developers.
    'inactivity' => ['inactive_days' => 14, 'warn_after_days' => 12],
    // [Sprint 21 E2] The verification code by email: valid verify_code_minutes, once, with verify_code_attempts wrong
    // tries. And the invite gift: referral_coins to the inviter for each coach who signs up from their link and
    // verifies, up to referral_max.
    // [Sprint 30 P6] starter_coins: a new coach's first coins, claimed once from the home screen (apart from the
    // verification reward).
    'account' => ['welcome_coins' => 1000, 'starter_coins' => 25, 'password_min' => 8, 'verify_code_days' => 7, 'verify_code_minutes' => 15, 'verify_code_attempts' => 5,
        'referral_coins' => 100, 'referral_max' => 10, 'auto_vacation_days' => 5, 'auto_vacations_per_season' => 2,
        'vacation_cooldown_days' => 3, 'long_vacation_max_days' => 60, 'vacation_max_days' => 14, 'vacation_rest_days' => 14, 'avatar_max_kb' => 4096, 'avatar_size' => 256,
        // Usernames [X11]: words that pass for the game's staff, anywhere in the name; the short ones only alone (or with
        // digits), so "modric" stays free. The developers' names are given by the admin only, with the official badge.
        'blocked_words' => ['owner', 'admin', 'support', 'moderator', 'official', 'legends', 'system', 'staff', 'developer'],
        'blocked_names' => ['mod', 'dev', 'gm', 'root', 'help', 'team'],
        // [Sprint 21 E2.6] The owner's names for the developers, fixed for good: Owner-Sizar and Owner-Sliman.
        'official_usernames' => ['Owner-Sizar', 'Owner-Sliman'],
        // Each developer's Gmail, on the server only: the confirmed address takes its name and the admin panel. The
        // old keys (OWNER_HAMZA_EMAIL, OWNER_SOLIMAN_EMAIL) still work, so the server needs no change.
        'official_emails' => ['Owner-Sizar' => env('OWNER_SIZAR_EMAIL', env('OWNER_HAMZA_EMAIL')), 'Owner-Sliman' => env('OWNER_SLIMAN_EMAIL', env('OWNER_SOLIMAN_EMAIL'))]],
    // The home server's health check every minute, with an alert on the phones by ntfy [PLAN 2.19, Sprint 21 B2].
    // Each phone subscribes to the topic in the ntfy app; no topic, no alert (the check still runs).
    'monitoring' => [
        'ntfy_topic' => env('NTFY_TOPIC'),
        'ntfy_server' => env('NTFY_SERVER', 'https://ntfy.sh'),
        'web_url' => env('HEALTH_WEB_URL', 'http://127.0.0.1:8000'),
        // A service is down when its last sign of life is older than this (seconds).
        'stale' => ['queue' => 120, 'scheduler' => 150],
        // While a service stays down, the alert comes again this often (minutes).
        'remind_minutes' => 30,
        // Disk space under this many MB on the data disk is a warning.
        'min_free_mb' => 1024,
    ],
    // The stadium [PLAN 2.9, Sprint 29]: three sections of three stages of five parts, one part at a time, each
    // started by the coach and done in part_hours (scaled by the season's length). The pitch's effect is in
    // match.home_pitch_bp (the engine reads it from the match's snapshot).
    // [Sprint 21 E6] Every part is built in part_hours, the same in every league.
    'stadium' => ['stages' => 3, 'parts_per_stage' => 5, 'part_hours' => 20,
        'sections' => ['seats', 'pitch', 'training'],
        'part_cost_bp' => [1 => 5, 2 => 8, 3 => 12],          // one part of a stage, as a share of the league's money scale
        'capacity_by_stage' => [20000, 25000, 31000, 38000],   // seats: the same ticket price, more seats
        // training: each session's step goes up by a random share in this range (basis points)
        'training_speed_bp' => [[0, 0], [0, 1000], [500, 2000], [1000, 3000]]],
    // Backups off this machine [PLAN 2.19, Sprint 37]: an rclone remote to Google Drive (rclone config, once).
    'backup' => ['rclone_remote' => env('BACKUP_RCLONE_REMOTE')],
    // The admin panel [PLAN 2.17, Sprint 37]: a code from the authenticator is asked again after these hours.
    // [Sprint 30 P1] The two-step code for the admin panel: asked of every admin by default (the owner's report,
    // 2026-11-01, over X46). Only ADMIN_TWO_FACTOR=false on the server turns it off.
    // [Sprint 21 E9] Rewarded videos: each one the provider verifies cuts minutes_per_video off a training slot's next
    // session or a stadium part, up to max_per_item for the same task. Off, with no provider, until the owner picks one
    // (README section 11): no paid or account-bound SDK is in the game.
    // [Sprint 20 S4] The provider is our own (house, App\Ads\HouseAds), on by the owner's decision 2026-10-29: the
    // developers' ads from the admin panel, else these built-in ones, each house_seconds long by default.
    // [Sprint 20 B4] Friendlies: not within block_minutes of the club's next match; each player who played gets
    // training_progress on his bar (of training.progress_scale, 10000), `fitness` more fitness (up to 100), and the
    // friendly counts for chemistry. [Sprint 24 B2] coins each (the owner's request 2026-10-29), taken when the coach
    // confirms, in every league (fair ones too), with no limit: no daily one, and not in the season's coin cap.
    // [Sprint 30 P6] first_free: an account's first friendly costs nothing.
    'friendlies' => ['first_free' => true, 'coins' => 5, 'fitness' => 5, 'block_minutes' => 60, 'training_progress' => 300],
    // [Sprint 20 B5] The weekly quests (Monday to Monday, Cairo): a target each and coins; the big one (unbeaten: at
    // least target matches without a defeat) pays money_bp of the league's money scale to the club.
    'quests' => ['friendly' => ['target' => 1, 'coins' => 10], 'wins' => ['target' => 2, 'coins' => 20], 'stadium' => ['target' => 1, 'coins' => 15],
        'training' => ['target' => 1, 'coins' => 10], 'unbeaten' => ['target' => 2, 'money_bp' => 50]],
    // [X54] An announcement's picture: at most image_max_kb uploaded, kept as a JPEG at most image_width wide and
    // image_max_height high (a wide banner, as the owner's picture).
    'announcements' => ['image_max_kb' => 4096, 'image_width' => 1200, 'image_max_height' => 600],
    // [Sprint 20 B3] The after-round window: the matches missed in the last days days, at most max.
    'after_round' => ['days' => 3, 'max' => 5],
    // [Sprint 20, question 5] The board's mood: calm before after_rounds league rounds; then happy at or above the
    // objective's place, worried up to worried_places below it, angry further down.
    'board' => ['after_rounds' => 3, 'worried_places' => 2],
    // [X57] Google AdSense, the owner's real ad revenue (the owner's request 2026-10-29), off until ADSENSE_CLIENT is set
    // on the server (legends-set ADSENSE_CLIENT, the account's ca-pub-…): then /ads.txt names the account, the page
    // carries its code, and display units show in a few calm places (never in a match). With ADSENSE_REWARDED, a
    // rewarded video (H5 Games Ads) is tried before our own ad and cuts the same minutes; its watch is timed on the
    // server for at least adsense_seconds (Google has no server check for the web), and the 5 a task stay. test asks
    // Google for test ads (ADSENSE_TEST) until H5 Games Ads approves the site.
    // [X72] The game's own AdSense account by default (the owner's, 2026-11-01): its publisher id is public, so it sits
    // here; ADSENSE_CLIENT on the server still replaces it, and an empty one turns Google's ads off.
    'adsense' => ['client' => env('ADSENSE_CLIENT', 'ca-pub-9280036306568581'), 'slot' => env('ADSENSE_SLOT'), 'rewarded' => (bool) env('ADSENSE_REWARDED', false),
        'test' => (bool) env('ADSENSE_TEST', false), 'adsense_seconds' => 10],
    'ads' => ['enabled' => (bool) env('ADS_ENABLED', true), 'driver' => env('ADS_DRIVER', 'house'), 'minutes_per_video' => 30, 'max_per_item' => 5,
        'house_seconds' => 30, 'house_defaults' => [
            ['title' => 'ادعُ صديقاً واربح 100 كوينز', 'body' => 'انسخ رابط الدعوة من «حسابي». كل صديق يسجّل منه ويوثّق حسابه يعطيك 100 كوينز، حتى 10 أصدقاء.',
                'title_en' => 'Invite a friend, win 100 coins', 'body_en' => 'Copy your invite link from "My account". Every friend who signs up from it and verifies gives you 100 coins, up to 10 friends.'],
            ['title' => 'لكل خطة خطة تهزمها', 'body' => 'افتح «كتاب التكتيك» في صفحة التكتيك: اعرف الخطة التي تتفوق على دفاع خصمك، فيكون للأضعف رد.',
                'title_en' => 'Every plan has its answer', 'body_en' => 'Open the tactics book on the tactics page: find the plan that beats your opponent\'s defence, so the weaker side has an answer.'],
            ['title' => 'لا تدريب بلا مدرب', 'body' => 'تعاقد مع مدرب كل خط من الجهاز الفني، ثم ضع لاعباً من كل خط في التدريب: جلسة كل 6 ساعات.',
                'title_en' => 'No training without a coach', 'body_en' => 'Hire each line\'s coach from the technical staff, then put a player of each line in training: a session every 6 hours.'],
            ['title' => 'الملعب يصنع الفارق', 'body' => 'وسّع المدرجات وحسّن أرض التدريب: كل جزء 20 ساعة، وكل مرحلة تزيد دخلك أو تسرّع تطور لاعبيك.',
                'title_en' => 'The stadium makes the difference', 'body_en' => 'Grow the stands and the training ground: each part takes 20 hours, and every stage adds income or speeds up your players.'],
            ['title' => 'المباراة تُدار حية', 'body' => 'ادخل مباراتك المباشرة: غيّر الخطة وأجرِ التبديلات في نوافذ المدرب، والمعلق يرافقك.',
                'title_en' => 'The match is managed live', 'body_en' => 'Join your live match: change the plan and make substitutions in the coach\'s windows, with the commentator beside you.'],
        ]],

    // [Sprint 30 G6] The admins' scopes: each opens these sections of the panel (the first part of the path under
    // /admin/); an admin with no scope opens everything, and gives the scopes.
    'admin' => ['scopes' => [
        'support' => ['overview', 'activity', 'users', 'conversations', 'vacations', 'alliances', 'leagues', 'reports'],
        'content' => ['overview', 'announcements', 'house-ads', 'junk', 'ideas', 'polls', 'events', 'commentary', 'data', 'chat', 'reports'],
        'finance' => ['overview', 'activity', 'coins', 'leagues'],
    ], 'two_factor' => (bool) env('ADMIN_TWO_FACTOR', true), 'two_factor_hours' => 12, 'users_per_page' => 100,
        // [X54] The most coins an admin gives an account at once.
        'coins_max' => 100000],
    // [Sprint 28] The coaches' suggestions to the developers and the polls on what to build next: how many
    // suggestions an account sends a day (the last 24 hours), the reward for one the team likes (the default the
    // panel offers, and the most), and a poll's options and longest run.
    'ideas' => ['per_day' => 3, 'reward_default' => 50, 'reward_max' => 1000,
        'poll_options_min' => 2, 'poll_options_max' => 6, 'poll_max_days' => 30],
    // Notifications [PLAN 2.13, Sprint 36]: one channel (Web Push now, FCM in Sprint 45). Each kind can be turned off,
    // and the inbox messages that push under each kind. The VAPID keys come from .env (php artisan push:keys).
    'notifications' => [
        'kinds' => [
            'referee' => ['referee'],
            'match_soon' => ['match_soon', 'match_move'],
            'offers' => ['offer_received', 'offer_countered', 'offer_accepted', 'offer_rejected', 'listing_sold', 'loan'],
            'done' => ['training_done', 'stadium_part', 'scout_report', 'staff_left', 'referral_reward', 'slot_opened'],
            // [Sprint 21 E7.2, E7.7] The developers' announcements and their messages to the coach.
            'news' => ['announcement', 'official_message', 'coins_gift', 'suggestion_answer'],
            'absence' => ['absence_warning', 'left_absent', 'kicked', 'vacation_request', 'vacation_approved', 'vacation_rejected', 'inactive_warning', 'account_vacation', 'account_vacation_request', 'assistant_led'],
        ],
        // [Sprint 21 E4.7] Half an hour before kick-off, as the owner asked (was 10 minutes).
        'match_soon_minutes' => 30,
        'vapid' => ['public' => env('WEBPUSH_VAPID_PUBLIC'), 'private' => env('WEBPUSH_VAPID_PRIVATE'), 'subject' => env('WEBPUSH_SUBJECT', 'mailto:admin@legends.local')],
    ],
    // The premium coins [docs/features/premium.md, Sprint 34]: earned in the game only, spent like OSM, never into club money.
    'premium' => [
        'season_cap' => 400,           // the most a coach spends in one league in one season
        'earn' => ['daily' => 10, 'win' => 5, 'draw' => 2, 'objective_league' => 50, 'objective_cup' => 30,
            // The big season prizes go to the champions alone: the league's and the cup's [X14].
            'league_1' => 300, 'cup_1' => 200],
        'price' => ['spy' => 20, 'specialist' => 25, 'finish_training' => 5, 'finish_scout' => 15, 'finish_stadium_per_stage' => 10, 'quick_sale' => 5,
            'bribe' => 15, 'security_check' => 10, 'double_agent' => 15],
        'shop' => [['coins' => 100, 'label' => 'حزمة صغيرة'], ['coins' => 300, 'label' => 'حزمة متوسطة'], ['coins' => 1000, 'label' => 'حزمة كبيرة']],
    ],
    // Club objectives [PLAN 2.20, Sprint 33]: from the club's rank by strength in its league (1 = strongest).
    // League: the strongest goes for the title; the top quarter for a place this far below its rank; the rest
    // further; and nobody is asked for less than to stay out of the bottom fifth. Cup: a stage by quarter of rank.
    'objectives' => ['top_quarter_slack' => 1, 'rest_slack' => 2, 'bottom_bp' => 2000,
        'cup_by_quarter' => ['final', 'sf', 'qf', 'qf']],
    // The bots between matches [ENGINE 7, Sprint 32]: each personality's own tactics, then the match's adjustments
    // from what any coach can see of the opponent (strength, the four public tactics of his last match, his form).
    'bots' => [
        'personalities' => [
            'giants' => ['plan' => 'passing', 'tackling' => 1, 'pressing' => 55, 'style' => 62, 'tempo' => 50, 'att' => 'support', 'mid' => 'push', 'def' => 'stay', 'trap' => 0, 'marking' => 'zone'],
            'defenders' => ['plan' => 'counter', 'tackling' => 1, 'pressing' => 30, 'style' => 25, 'tempo' => 45, 'att' => 'only', 'mid' => 'def', 'def' => 'stay', 'trap' => 0, 'marking' => 'man'],
            'pressers' => ['plan' => 'passing', 'tackling' => 2, 'pressing' => 85, 'style' => 62, 'tempo' => 78, 'att' => 'back', 'mid' => 'push', 'def' => 'stay', 'trap' => 1, 'marking' => 'zone'],
            'hard' => ['plan' => 'long', 'tackling' => 3, 'pressing' => 55, 'style' => 48, 'tempo' => 55, 'att' => 'support', 'mid' => 'stay', 'def' => 'stay', 'trap' => 0, 'marking' => 'man'],
            'wingers' => ['plan' => 'wings', 'tackling' => 1, 'pressing' => 50, 'style' => 58, 'tempo' => 60, 'att' => 'support', 'mid' => 'stay', 'def' => 'fullbacks', 'trap' => 0, 'marking' => 'zone'],
            'adaptive' => ['plan' => 'passing', 'tackling' => 1, 'pressing' => 50, 'style' => 50, 'tempo' => 50, 'att' => 'support', 'mid' => 'stay', 'def' => 'stay', 'trap' => 0, 'marking' => 'zone'],
        ],
        'style_per_100cp' => 4,        // a stronger side attacks more: style moves this much per 100 strength points of gap
        'style_swing' => 12,           // at most this far from the personality's own style
        'rest_below_fitness' => ['pressers' => 75, 'default' => 65],   // rotation: who rests while the squad allows
    ],
    // Specialists [docs/features/specialists.md, Sprint 31]: a contract of contract_days (scaled by the season's
    // length), paid when signed as a share of the league's money scale (club money until the premium coins).
    // The integrity system [X28], where the owner switched it on: a bribe of bribe_cost_bp of the league's money scale
    // (and the coins of premium.price.bribe), caught by the VAR var_bp of the time (lost, and var_morale off); a
    // lawyer of lawyer_stars or a security check shows the spies, and a spy is turned for double_agent's price; the
    // FA confiscates fine_bp of the money, bans from the market for market_ban_hours, takes `points`, and the scandal
    // takes scandal_morale off and scandal_attendance_bp of the next home crowd; the headline shows headline_hours.
    // [X61] The bribe down to about a round or two of wages (bribe_cost_bp 40 to 24, and 40 coins to 15), its
    // consequences (the VAR, the fine, the points, the scandal) as they were.
    'integrity' => ['bribe_cost_bp' => 24, 'var_bp' => 2000, 'var_morale' => 10, 'lawyer_stars' => 4,
        'security_check_cost_bp' => 8, 'double_agent_cost_bp' => 10, 'fine_bp' => 3000, 'market_ban_hours' => 24, 'points' => 3,
        'scandal_morale' => 15, 'scandal_attendance_bp' => 2500, 'headline_hours' => 24],
    // The alliance tournament [X27]: the first round at least notice_minutes ahead (time for the developers'
    // approval), a round each gap_minutes (dev_gap_minutes in a development league), and never within
    // clash_minutes of another match of its clubs.
    'alliance' => ['notice_minutes' => 60, 'gap_minutes' => 1440, 'dev_gap_minutes' => 3, 'clash_minutes' => 30, 'sizes' => [2, 7], 'default_size' => 5],
    // A round in two time slots [X31]: the league's gap to the second slot (min..max minutes; dev_minutes in a
    // development league), and the reminder to each coach remind_minutes before the round's one lock.
    'staggered' => ['min_minutes' => 60, 'max_minutes' => 600, 'dev_minutes' => 3, 'remind_minutes' => 120],
    // The live draw [X26]: one slot revealed this often on every screen.
    'draw' => ['reveal_ms' => 2500],
    // [Sprint 29] Tournaments: 2 to 32 teams, clubs and national teams together. A national team plays when the data has
    // nation_min_players of its nationality with a goalkeeper among them, and takes its best nation_squad (with
    // nation_keepers goalkeepers); a player of a club in the same tournament stays with his club. The draw shows one
    // ball every reveal_ms. Each template: who it takes (nations of a confederation, all nations, or the strongest
    // clubs, at most per_league from one league), how many, and its shape.
    'tournaments' => [
        // [X68] Up to 64 teams (a knockout alone up to 32); a draw that shares the teams among the players who entered
        // starts auto_draw_minutes after the last place is taken, unless the organizer set its time.
        'min_teams' => 2, 'max_teams' => 64, 'knockout_max_teams' => 32, 'auto_draw_minutes' => 10, 'entry_modes' => ['pick', 'draw', 'assign'], 'nation_min_players' => 14, 'nation_squad' => 23, 'nation_keepers' => 3,
        'group_counts' => [1, 2, 4, 8], 'advance' => [1, 2], 'reveal_ms' => 3500,
        'templates' => [
            'world_cup' => ['pool' => 'nations', 'teams' => 32, 'format' => 'groups', 'groups' => 8],
            'club_world_cup' => ['pool' => 'clubs', 'per_league' => 2, 'teams' => 32, 'format' => 'groups', 'groups' => 8],
            'afcon' => ['pool' => 'nations', 'confederation' => 'CAF', 'teams' => 16, 'format' => 'groups', 'groups' => 4],
            'euro' => ['pool' => 'nations', 'confederation' => 'UEFA', 'teams' => 16, 'format' => 'groups', 'groups' => 4],
            'asian_cup' => ['pool' => 'nations', 'confederation' => 'AFC', 'teams' => 16, 'format' => 'groups', 'groups' => 4],
            'custom' => ['pool' => 'any', 'teams' => 8, 'format' => 'groups', 'groups' => 2],
        ],
    ],
    // [Sprint 29] Chat groups: members at most, a message's length, how many messages a page brings, and a group's
    // name. A member sends at most per_minute messages a minute.
    'chat' => ['max_members' => 256, 'max_length' => 1000, 'page' => 50, 'per_minute' => 20, 'max_groups' => 50,
        // [X65] A picture is kept at most image_px on its long side (a JPEG); a voice note up to audio_kb and audio_seconds.
        'image_max_kb' => 8192, 'image_px' => 1280, 'audio_kb' => 1500, 'audio_seconds' => 120,
        'audio_mimes' => ['audio/webm', 'audio/ogg', 'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/x-m4a', 'video/webm']],
    // [X65] The settings the admin changes from the panel (App\Support\GameSettings), with their defaults: the chat's
    // messages older than chat.retention_days are deleted every hour (0: kept), and pictures and voice notes allowed.
    'settings' => ['chat.retention_days' => 0, 'chat.media' => true],
    // [X66] The live draw's chat: open from open_before minutes before the draw to open_after minutes after its last
    // ball; a line up to max_length, per_minute lines and reactions a viewer, and only these reactions.
    'draw_chat' => ['open_before' => 60, 'open_after' => 30, 'max_length' => 200, 'per_minute' => 12, 'reactions_per_minute' => 40,
        'page' => 300, 'reactions' => ['🔥', '👏', '😱', '⚽', '😂', '❤️', '😮', '🏆']],
    // [UP12] The press conference opens open_minutes before kick-off (until the lock), and the coach's statement adds
    // morale points to his team in that match. A right prediction of a match's winner pays the predictor's club
    // prediction_cash_bp of the league's money scale and counts xp_prediction on his career.
    // [X61 E9] stakes: what each statement does to the morale after the match, by its result (a bold promise pays on
    // a win and costs on a defeat; the calm one is safe; the rallying one in between).
    'press' => ['open_minutes' => 30, 'morale' => 1,
        'stakes' => ['attack' => ['win' => 3, 'draw' => -1, 'loss' => -3], 'calm' => ['win' => 1, 'draw' => 1, 'loss' => 0], 'rally' => ['win' => 2, 'draw' => 0, 'loss' => -1]], 'prediction_cash_bp' => 3, 'article_max' => 2000,
        // [Sprint 21 E4.6, final formulas Sprint 20 S3] The league's news (App\League\NewsFormulas). upset_gap: strength
        // points that make one side clearly stronger on paper.
        // A match: goal for each goal, draw for a draw with goals or one_goal for a one-goal game, upset when the winner
        // was the clearly weaker side (upset_draw for a draw between unequal sides), late_goal for each equaliser or
        // go-ahead goal from late_minute (up to late_max), comeback when the winner was behind, and red for each red card.
        // A player: his rating (6.00 = 600), goal and assist each, clean_sheet for a keeper or defender, and his side's win or draw.
        // A coach: win (or draw against a clearly stronger side), margin for each goal up to margin_max, one point per
        // gap_per_point his side was weaker, away for a result away, and clean_sheet.
        'news' => ['best_matches' => 3, 'scandals' => 5, 'upset_gap' => 300,
            'match' => ['goal' => 3, 'draw' => 5, 'one_goal' => 3, 'upset' => 8, 'upset_draw' => 4, 'late_goal' => 3, 'late_minute' => 85, 'late_max' => 2, 'comeback' => 6, 'red' => 2],
            'player' => ['goal' => 60, 'assist' => 35, 'clean_sheet' => 40, 'win' => 20, 'draw' => 5],
            'coach' => ['win' => 10, 'draw' => 3, 'margin' => 3, 'margin_max' => 3, 'gap_per_point' => 100, 'away' => 3, 'clean_sheet' => 2]]],
    // Morale [X25], 0..100: after a win, a draw, a defeat, and more down from the second match in a row without a
    // win; in a match each side adds its crowd (twice for the home side on its ground), and `ticket` for each
    // league coach who bought a ticket to cheer it (up to tickets_max). The engine's effect is in engine.morale_bp.
    'morale' => ['start' => 70, 'min' => 20, 'max' => 100, 'win' => 6, 'draw' => -2, 'loss' => -6, 'winless_extra' => 2,
        'crowd' => 3, 'ticket' => 2, 'tickets_max' => 6, 'ticket_cost_bp' => 5],
    // [UP13] The assistant takes a team whose coach has not been in its league since its last match (or is on
    // holiday): the tired under min_fitness rest, and one of these balanced formations with balanced tactics.
    'assistant' => ['min_fitness' => 75, 'formations' => ['4-3-3A', '4-4-2A', '4-3-3B', '4-4-2B']],
    // [Sprint 22] The Assistant Coach (Manager Bot): smart answers per coach per Cairo day (then the guide answers), the
    // messages of the conversation sent back with each question, the longest question, and the reads of the coach's
    // own club one answer may make.
    'manager_bot' => ['daily_ai' => 30, 'history' => 8, 'question_max' => 500, 'reads_max' => 4],
    'specialists' => ['contract_days' => 7,
        // [X20] The staff by stars, 1 to 5: a coach for each line (the keeper coach for the keepers), the doctor, the
        // physio and the lawyer. The price is cost_bp (of the league's money scale) times stars_cost_bp; each effect
        // grows with the stars. A contract can be renewed in its last renew_hours (the new one starts when it ends);
        // one that ends unrenewed is a resignation, and the coach is told.
        'cost_bp' => ['mental_coach' => 15, 'doctor' => 20, 'lawyer' => 15, 'physio' => 20, 'keeper_coach' => 20, 'def_coach' => 15, 'mid_coach' => 15, 'att_coach' => 15],
        'stars_cost_bp' => [1 => 5000, 2 => 7500, 3 => 10000, 4 => 14000, 5 => 20000],
        'renew_hours' => 24,
        'doctor_countdown' => [1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3],         // each match counts injuries down by this many
        'lawyer_cancel_bp' => [1 => 2000, 2 => 3500, 3 => 5000, 4 => 6500, 5 => 8000],   // the share of new red-card bans cancelled
        'keeper_coach_boost' => [1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3],       // on the keeper's rating and attributes in a match
        'physio_rest_bonus' => [1 => 5, 2 => 10, 3 => 15, 4 => 20, 5 => 25],     // fitness on top of rest_recovery for a player who rests
        'mental_coach_boost' => [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5],    // morale back after a draw or a defeat [X25]
        'coach_training_bp' => [1 => 1000, 2 => 2000, 3 => 3000, 4 => 4500, 5 => 6000],  // faster training for the coach's line
        // [X61] The basic coach every club has for free, one per line, until it signs one from the staff: its line
        // trains from the first day, this much faster (a one-star coach's own), so a new coach is never stuck.
        'basic_coach_bp' => 1000],
    // Spying on the next opponent [docs/features/spy.md, Sprint 30]: a share of the league's money scale (club
    // money until the premium coins come, Sprint 34).
    'spy' => ['cost_bp' => 15],
    // The scout [docs/features/scout.md, X15]: a share of the league's money scale, a 15-hour trip scaled by the
    // season's length, and five players that match every criterion (the position, the age, the rating, the price).
    // [X61] cost_bp 30 to 7 (the owner, 2026-10-30): a report cost about two rounds of wages, now under half of one.
    'scout' => ['cost_bp' => 7, 'hours' => 15, 'results' => 5],
    // [X61 E5] The season's awards: the best player needs min_matches at least (or half the most played), the young
    // one is young_age or under.
    'awards' => ['min_matches' => 3, 'young_age' => 21],
    // [X61 E3] The youth academy: `offers` prospects of max_age or under every `days` days, the potential hidden within
    // `range`, at price_bp of the value, per_season signings at most.
    // [X61 E2] Loans between coaches: up to max_rounds league rounds, for a fee up to max_fee_bp of the player's value.
    'loans' => ['max_rounds' => 6, 'max_fee_bp' => 2000],
    // [X61 E1] The contracts within a season: the squad's value up to wage_cap_bp of the larger of the league's scale
    // and the club's own squad in the data; ending one early costs release_bp of the wages left in the season.
    // [X62] Renewing for up to max_seasons more seasons costs renew_fee_bp of his wages over them as a signing fee.
    'contracts' => ['wage_cap_bp' => 16000, 'release_bp' => 5000, 'renew_fee_bp' => 2000, 'max_seasons' => 3],
    'academy' => ['days' => 3, 'offers' => 3, 'max_age' => 19, 'range' => 4, 'price_bp' => 6000, 'per_season' => 2],
];
