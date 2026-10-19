# أحداث المباراة

> العقد بين المحرك والعارض. كل دقيقة لعب (Tick) تعيد كائناً واحداً بالشكل أدناه، سواء جاءت من المحاكي (`POST /api/v1/sim/matches/{id}/ticks`) أو من البث الحي لاحقاً. تسجيل كامل نموذجي: `docs/api/samples/liverpool-arsenal-48213.json` (ليفربول ضد آرسنال، البذرة 48213).
>
> كل الأرقام صحيحة. الإحداثيات بالديسيمتر على ملعب 1050 × 680: صاحب الأرض يهاجم دائماً نحو x = 1050 (لا تبديل للجهات بين الشوطين في v1)، وy = 0 خط التماس البعيد.

## الدقيقة

| الحقل | النوع | المعنى |
|---|---|---|
| `tick` | int | رقم التسلسل من 1 (البذرة = بذرة المباراة + هذا الرقم) |
| `period` | int | 1 و2 الشوطان، 3 و4 الوقت الإضافي، 5 الترجيح |
| `minute` | [int, int] | الدقيقة المعروضة ووقت بدل الضائع: `[90, 3]` تعني 90+3 |
| `score` | {home, away} | النتيجة بعد هذه الدقيقة |
| `events` | list | الأحداث بالترتيب (أدناه) |
| `danger` | int | خطورة اللحظة من −5 إلى 5 (موجب لصاحب الأرض): شريط الزخم وصوت الجمهور |
| `rejected` | list | أوامر رُفضت مع السبب (`no_subs_left`، `bad_players`، `bad_tactics`، `bad_formation`) |
| `finished` | bool | انتهت المباراة |
| `frames` | list | 6 إطارات مفتاحية للرسم (أدناه) |
| `moment` | {kind, ms} | لقطة الدقيقة ومدة عرضها بالميلي ثانية [MOMENTS.md]: `quiet` `attack` `goal` `save` `miss` `offside` `corner` `yellow` `red` `free_kick` `penalty` `sub` `injury` `stoppage` `shootout` `coach` (تغيير تكتيك أو طريقة) `whistle` (استراحة ونهاية). يحسبها الخادم من الأحداث (`MomentClock`) فتتزامن الشاشتان |
| `teams` | object | لقطة الفريقين بعد الدقيقة: الطريقة، التكتيك، التبديلات، الإحصائيات، واللاعبون بلياقتهم وبطاقاتهم وتقييمهم |
| `debug` | object | **في المحاكي فقط:** قيم داخلية للوحة المطور (معدل الهجمات ونصيب صاحب الأرض) |

## الأحداث

كل حدث فيه `type` و`team` (`home` أو `away` أو `null`).

| `type` | حقول إضافية |
|---|---|
| `attack` | `plan`، `counter`، `phases` (كل مرحلة `{n, ok, p}`: `build` `progress` `offside` `create` `shot` `corner`، و`p` احتمال النجاح بنقاط الأساس)، `result` (`goal` `saved` `missed` `blocked` `lost` `cleared` `corner` `offside` `foul` `penalty`)، `lane` (`left` `center` `right` من جهة المهاجم)، `quality` (`big` `normal` `half` `long` `header`)، ومعرّفات اللاعبين: `carrier` `receiver` `creator` `shooter` `defender` `keeper` |
| `goal` | `scorer`، `assist`، `kind` (`open` `penalty` `free_kick`)، `score` |
| `card` | `player`، `color` (`yellow` `red`)، `second_yellow` |
| `foul` | `player`، `victim`، `penalty` |
| `penalty` / `free_kick` | `taker`، `keeper`، `scored` |
| `corner` | `taker`، `won` (كسب المهاجم الرأسية) |
| `injury` | `player` |
| `sub` | `out`، `in`، `reason` (`injury` للتبديل التلقائي) |
| `action` | `action`: الأمر الذي طُبق في هذه الدقيقة (تبديل، تكتيك، طريقة) |
| `stoppage` | `added`: دقائق بدل الضائع المعلنة |
| `period` | `name`: `halftime` `extra_time` `extra_time_half` `penalties` `fulltime` |
| `shootout` | `kicks` (`{team, taker, scored}`)، `score` |

## الإطارات المفتاحية

يولّدها `MatchChoreographer` في السيرفر. العارض يستوفي بينها فقط ولا يحسب أي حركة.

```json
{ "t": 0, "b": [612, 418, 30], "p": { "1234": [598, 424], "...": [0, 0] }, "h": 1234 }
```

| الحقل | المعنى |
|---|---|
| `t` | رقم الإطار 0 إلى 5 داخل الدقيقة |
| `b` | الكرة `[x, y, z]`: z ارتفاعها (الكرات الطويلة والعرضيات) |
| `p` | موقع كل لاعب في الملعب بمعرّفه |
| `h` | معرّف حامل الكرة أو `null` |

الأشكال مرسومة من الطريقة فقط، ولا تحمل أي قيمة تكتيكية مخفية (اختبار في الدوري لاحقاً).
