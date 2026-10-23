# Content format

The game's questions and narration live here as data. Adding a question means adding data, and its stage and doodles if they are new, never new flow code. Copy changes are made here; `docs/SCRIPT.md` is the draft the content was converted from.

- `run.json`: the chapters of a run, in play order, by file name.
- `chapters/*.json`: one file per chapter, its beats in play order.
- `profile_axes.json`: the silent profile's axes.
- `countries.json`: the countries the pin in 2.10 can land on: name, ISO code, people, and where on the map.
- `menu.json`: the main menu's title, and the imp's lines there (see "The main menu" below).

The tests in `tests/content/` load every chapter and fail on any problem, so run them after editing.

## A chapter

```json
{
  "id": "ch1",
  "title": "The Tracks",
  "beats": [ ...beats in play order... ]
}
```

The facts a run remembers so far: the walking button's history (`button_woke`, `button_auctioned`, `button_shot`, `button_spared`), set by its stages, and the campaign's (`class_knight` and the other classes, `reason_gold` and the other reasons, `took_shortcut` or `took_long_road`, `companion_trusted`, `companion_used` or `companion_refused` with `companion_with_you` for either of the first two, `beast_killed` or `beast_spared`, `took_blade`, `took_gold` or `left_treasure`), set by its options.

A chapter can say what a run started after it, from the dev menu, should take it to have left behind: `"if_skipped": { "remember": ["button_woke"], "kills": { "stranger": 1 } }`, the facts later beats look back on and the kills by kind. Later beats read the walking button's history (`button_woke`, `button_auctioned`, `button_shot`, `button_spared`) and the kill tally.

A chapter that hands the player money, like The Money, has a `wallet`: `"wallet": { "start": 10000 }`. The wallet opens as the chapter's first words are said, its balance shows at the top of the screen until the chapter ends, and the shop, the auction, the buyback and the receipt spend from it and read it.

## A beat

Either some narration from the imp:

```json
{ "kind": "narration", "id": "taunt", "lines": [ "...", "..." ] }
```

a cinematic, which plays the scene `cinematics/<scene>/<scene>_cinematic.tscn`, such as the opening `crash`, or the `waking` that opens every later chapter:

```json
{ "kind": "cinematic", "id": "crash", "scene": "crash" }
```

or a question:

```json
{
  "kind": "question",
  "id": "lever",
  "number": "1.02",
  "title": "The Lever",
  "verb": "binary",
  "weight": "medium",
  "stage": { "type": "trolley", ...the stage's own settings... },
  "ask": [ "The imp's line that poses it." ],
  "options": [ ...two or more options... ],
  "reveal": { "heading": "how others chose" }
}
```

- `id` is stable: saves, the profile and the crowd tally key off it. Beat ids are unique within a chapter.
- `verb` is one of `binary`, `multiple_choice`, `coordination_gamble`, `allocation`, `self_sacrifice`.
- `weight` is `light`, `medium` or `heavy`.
- `stage.type` names the stage scene, `stages/<type>/<type>_stage.tscn`. The rest of `stage` is read by that stage.
- `lines` (optional) holds named sets of the imp's lines that the stage says at moments of its own, such as the needling over the timer's countdown: `"lines": { "countdown": [ "...", "..." ] }`. A set's lines get ids like `ch2.timer.countdown.1`, so a set may not be called `ask`, `stage` or the id of an option.
- `ask` can also be an object of named asks, `"ask": { "items": [...], "nothing": [...] }`, when the stage picks how to pose the question, as the buyback does. Their lines get ids like `ch3.buyback.ask.items.1`.
- `lines.least_popular` (optional) is said by the imp just before the reveal when the player's pick was the least popular, such as "Not the popular call. Watch."
- `reveal.heading` is the reveal's heading. `reveal.labels` (optional) puts other words over the bars than the option labels, one per option, such as "took the money" for "Press it". `reveal.mark` (optional) names the line a coordination gamble's crowd had to cross, such as "half".

A **tableau** is a stage the imp talks over with nothing to choose, like the receipt: no options, no verb and no reveal. The stage draws on, the imp says the `ask` if there is one, the stage plays out and reports an outcome, and the imp says the question's `lines` of that name, the click on the last page moving on:

```json
{
  "kind": "tableau",
  "id": "receipt",
  "number": "3.23",
  "title": "The Receipt",
  "stage": { "type": "receipt", ... },
  "lines": { "hoard": [ "..." ], "spend": [ "..." ], "middle": [ "..." ] }
}
```

## The trolley stage

```json
"stage": {
  "type": "trolley",
  "rolling": true,
  "tracks": [
    { "figures": [ "stranger", "stranger" ], "facing": "away" },
    { "figures": [ { "kind": "stranger", "says": "Please. Please, not me." } ] },
    { "figures": [ "guilty", "stranger" ], "roped": true }
  ]
}
```

- Each track lists its souls by kind, nearest the split first. The kinds are the files in `figures/kinds/`: `stranger`, `guilty`, `partner`, `child`, `elderly`, `pregnant`, `sleeper`, `baby`.
- A soul given as `{ "kind": ..., "says": ... }` pleads: it clasps its hands and the words float over its head. The words follow the line rules (tags allowed) and get an id like `ch1.begging.stage.1`.
- On a track, `"roped": true` ties its souls together, `"facing": "away"` turns them from the player, and `"dark": true` hides the track in a dark that lifts once the trolley has rolled.
- `"rolling": true` sets the trolley creeping toward the split while the player decides.
- Two tracks are a fork: track 0 runs straight on, track 1 branches, and a lever throws the trolley across. Three are a fan, first to third from the top, and the player points at one.
- An option's `outcome` is `{ "track": n }`.

## The doodles stage

```json
"stage": { "type": "doodles", "doodles": [ "winged_figure", "flexing_figure" ] }
```

- A would you rather: two doodles side by side, the first on the left over the first option, the second on the right over the second.
- Each id names a doodle's script, `doodles/<id>.gd`. A new doodle is a new script there.
- Options need no `outcome`.

## The matchup stage

```json
"stage": { "type": "matchup", "sides": [ { "doodle": "brawler", "count": 100, "role": "blue" }, { "doodle": "gorilla", "role": "secondary" } ] }
```

Who Would Win: two sides with "vs" between them, each over its option's label; the reveal colours each bar by its side's `role`. A side names a `doodle`; with a `count` over one it is a crowd. `{ "button": true }` is the walking button itself, and `{ "doodle": "brawler", "kills": true, "role": "red" }` is everyone the player has killed in the run, with `{kills}` in the option's label filled with how many. `"asks": [ { "if": "button_shot", "ask": "shot" }, { "ask": "spared" } ]` picks the question's keyed ask by the first fact the run remembers.

## Buttons

Several stages are pressed with a push button. Where a stage takes `"button"`, it names a look in `stages/controls/looks/`: `plain`, `blue` (with a ring), `red` (with a dot), `green` or `gold` (with a dollar sign). Wherever an option's `outcome` has `"press": true`, that option is the one the button picks.

### The button stage

```json
"stage": { "type": "button", "button": "plain" }
```

One button, alone. The pressing option presses it; the other leaves it be.

With `"comes_alive": true` it is the walking button, dormant until pressed: it yelps the first of the stage's `says` lines as the press lands and wakes with a start, says the second with a fist shaken at the player, gets up, and stomps off saying the third. Its lines are spoken by the button (`"speaker": "button"`), each finished before the next.

### The better offer stage

```json
"stage": { "type": "better_offer", "button": "plain", "figure": "best_life", "cue": 2 }
```

A button beside a soul of the kind `figure`, drawn larger, which inks itself in on line `cue` of the ask (counting from 1). Pressing takes its life: it hops for joy and strolls off. The other option keeps your own: it turns away and fades.

### The gamble stage

```json
"stage": { "type": "gamble", "line": 50, "random": 50 }
```

A coordination gamble: a soul apart, and a button per option, left to right, its look named by the option's `outcome.button`. The option with `"gamble": true` stakes the soul on a room that has already voted: its `crowd` is the room's share for that button, `random` is the share of the room pressing at random instead (drawn again every play), and the soul lives only if the room's share passed `line`. The other button keeps it alive. Outcomes: `lives`, `dies`. The reveal shows the room's vote in the buttons' colours, with `reveal.mark` naming the line.

### The offer stage

```json
"stage": {
  "type": "offer", "button": "plain", "victim": "stranger",
  "people": 8100000000, "high_from": 128,
  "readouts": [ { "text": "{total} banked", "role": "amber" }, { "text": "{count} dead", "role": "red" } ],
  "tiers": [ { "amount": 100000, "crowd": 61 }, { "amount": 50000, "crowd": 55 }, { "amount": 1, "crowd": 2, "repeats": false } ]
}
```

An escalating offer. The option with `"accept": true` takes the amount on offer, and the offer comes back at the next tier; the other option stops. A tier's `crowd` is the share who took it there, and the reveal shows the tier the player stopped on (the options' own `crowd` is the first tier's split). A tier with `"repeats": true` comes back at the same amount. With `victim`, a soul of that kind folds off to the side with every press. `readouts` appear under the button once there is a number to run, each in its palette `role`.
- Outcomes: taking an offer reports its amount in digits, such as `"50000"`, or `"again"` for a repeat of the same tier. Stopping reports `"high"` or `"low"` when `high_from` is set: whether the amount last taken reached it.
- Placeholders: `{amount}` the amount on offer, `{given}` the amount last taken, `{total}` everything taken, `{count}` how many have folded, `{grand}` everything taken times `people`.

### The timer stage

```json
"stage": { "type": "timer", "seconds": 10, "label": "press", "cues": [0.6, 2.6, 4.0, 5.0, 8.0] }
```

A button with `label` on its cap and a clock over it. There is no choice row: the clock starts when the ask's last line has inked on, the imp says the question's `countdown` lines at `cues` (seconds into the clock, or spread evenly without them) without waiting for clicks, and the player presses the button or lets the clock run out, which picks the other option.

### The nuke stage

```json
"stage": {
  "type": "nuke", "button": "red", "countries": "res://content/countries.json",
  "bands": [ { "under": 100000, "key": "tiny" }, { "under": 5000000, "key": "small" }, { "under": 100000000, "key": "mid" }, { "key": "huge" } ],
  "caption": "{people} people, give or take"
}
```

Pressing the button inks a world map in; a pin goes round over it while the imp says the question's `spin` lines, then lands on a random country from `countries`, whose name and `caption` ink on beside it, and a mushroom cloud doodles onto the spot.
- Outcomes, in this order: `"home"` when it is the player's own country, read from the system's region; the country's code, such as `"VA"`, when the pressing option has a reaction for it; otherwise the `key` of the first band its people fall `under` (a band with no `under` takes the rest).
- Placeholders: `{country}` and `{people}`.

## The gun stage

```json
"stage": { "type": "gun", "imp": true, "survivors": "leave",
  "targets": [ { "id": "man", "kind": "stranger", "x": 640 }, { "id": "bear", "kind": "bear", "x": 1200 } ] }
```

First person: an ink sight follows the pointer, amber brackets lock on to the target under it, and a click fires. Each target names a soul `kind` (or a `doodle`), stands at `x` on the ground (or `y`), and can plead (`says`), be drawn in a palette `role`, and carry a `crowd` share and a `label` for a reveal by target.
- An option's outcome is `{ "shoot": "<target id>" }`, `{ "shoot": "any" }` (the target clicked, or one at random when picked in the row), `{ "shoot": "imp" }`, `{ "shoot": "self" }`, or `{ "hold": true }` to lower the gun. An option with `"hidden": true` stays out of the choice row and the reveal, and only the stage picks it: the imp is shot this way.
- `"imp": true` lets the sight lock on to the imp; `"survivors": "leave"` sends the figures left standing walking off; `"empty": true` makes every shot a dry click; `"dies_anyway": true` has the target die by itself once the gun is lowered; `"fires_back": 50` has an armed target fire back at a lowered gun that share of the time; `"alone": { "seconds": 8 }` asks nothing, shows no choice row, and lowers the gun when time runs out; `"charge": { "seconds": 6 }` sends the doodle target charging while the player chooses, arriving (which holds) when time runs out, and turning out to be the walking button, which says the question's `hurt_again`, `hurt` or `hello` line.
- Outcomes: the id of the target shot, `imp`, `self`, `click` (an empty gun), `held`, `fired` and `lowered` (an armed target's answer), and for the charging thing `shot`, `shot_again` (the button woke in 2.11) or `waved`.
- With targets that carry `crowd`, the reveal is a bar per target in its colour, then the holding option's.

## The booth stage

```json
"stage": { "type": "booth", "confessors": [ { "voice": "recliner", "says": { "text": "I paid for the whole seat.", "speaker": "headline" } } ] }
```

The confession booth, for Chapter 7. A confessor files into the booth, the words it stands by (`says`, a headline) floating over the roof, and states its side in the dialogue box: its lines in the ask are `{ "text": ..., "speaker": "confessor", "voice": "recliner" }`, and the confessor with that `voice` gestures while they play. The player rules one of three ways; the gavel is heard, the page jolts, and each confessor takes its verdict, then files out once the imp has had his say.
- A confessor with `"side": "left"` or `"right"` stands beside the booth instead of in it, with its words over its head, as the two in 7.10 do. `"kind"` names its soul kind (a stranger by default).
- `{ "button": true }` is the walking button, which slides in as a plain button and comes alive in the booth. A line of the ask with `"speaker": "button"` floats over it in its own voice while the box is away, and it says the question's `leave` lines as it files out.
- An option's outcome is `{ "verdict": "guilty" }`, `cleared` or `everyone`, or one per confessor by voice: `{ "verdict": { "her": "cleared", "him": "guilty" } }`.

## The campaign's stages

### The menu stage

```json
"stage": { "type": "menu", "doodles": [ "knight_shield", "rogue_dagger", "wizard_hat", "bard_lute", "cleric_chalice" ] }
```

A row of doodles, one per option left to right, each over its label: the doodles stage for three or more, with no "or". Options need no `outcome`.

### The vignette stage

```json
"stage": { "type": "vignette", "doodle": "dragon" }
```

One doodle sets the scene while the imp narrates, at `scale` times its own size if the stage says (1.3 otherwise); the options are in the choice row. An option's `outcome` can say how the doodle answers the pick: `{ "doodle": "fall" }` (it topples and dissolves), `"shake"`, `"leave"` (it backs away, fading), or it hops.

### The dice stage

```json
"stage": { "type": "dice", "sides": 6, "target": 3, "cue": 6, "caption": "roll a {target} or higher and you clear it" }
```

A hand drawn die with its `caption` under it, `{target}` in amber. The click that moves on from the imp's last page before the roll rolls it, and it lands on a face with an amber flash. Outcomes: `made` when the face reaches `target`, `missed` otherwise.
- As a tableau, the die inks in on line `cue` of the ask (counting from 1, every line counted), and the click on the ask's last page rolls it; the question's `made` or `missed` lines follow.
- As a question, an option whose outcome has `"roll": true` rolls: the stage says the question's `fetch` lines, inks the die in, says its `prompt` lines, and the click on their last page rolls it; the option's reaction is keyed `made` or `missed`. Any other option leaves the die out of it.

## The money chapter's stages

These spend from and read the chapter's `wallet`. Amounts show in the money format, such as `$1,750`.

### The shop stage

```json
"stage": { "type": "shop", "item": "burrito", "label": "Free food for life", "price": 1800 }
```

One thing for sale: `item` names its doodle, `label` is its name on the receipt, and `price` is what it costs, or `"everything"` for the whole balance. `"buyback": 100` gives the buyback's offer for it as a share of the price, in percent, when it differs from the buyback's own. The option whose outcome has `"buy": true` buys; the other keeps the money.
- Outcomes: `bought`; `broke` when the money is not there, which shows in the reveal as keeping the money; `passed`.
- Bought one at a time, with `"step": 100, "most": 40`, each one costs the step more than the last and the offer comes round again after every one, with `"tag": { "text": "{price} a year" }` on the price tag and `"tally": { "text": "{count} years taken", "one": { "text": "{count} year taken" } }` under it, shown from the first. Outcomes: `first` and `more` for each one bought, `broke` or `ran_out` when the money runs out before or after the first, and on stopping `some` or `none`.
- Placeholders: `{price}` what one costs now, `{count}` how many were bought. Only the price the thing is offered at is voiced.

### The auction stage

```json
"stage": { "type": "auction", "item": "cigarette_pack", "price": 20, "step": 10, "persist": 3,
  "bid": { "label": "Bid {bid}" }, "drop": { "label": "Drop out" } }
```

A shop with a rival. Buying brings the walking button in to bid `step` over the player, and the choice row then shows the `bid` and `drop` labels; no money moves. `persist` counts the player's bids, the first included, that fire the buying option's ending. The question's line sets hold what is said: the button's `arrive`, `taunts` (one a round, in order), `won` (after a drop out) and `gloat` (at the ending), and the imp's `stop`, his cut in before the ending, which moves on by itself.
- Outcomes: `auction` when the button comes in, `bid` for each bid it answers, `cursed` for the bid that reaches `persist`, `dropped`, `passed`, `broke`.
- Placeholders: `{price}` the asking price, `{rival}` the button's bid now, `{bid}` what the player would bid over it.

### The buyback stage

```json
"stage": { "type": "buyback", "share": 50, "round_to": 10, "least": 10 }
```

Everything owned, a row each, offered back one at a time in the order bought for `share` percent of what was paid, rounded to the nearest `round_to`, never under `least`. The option whose outcome has `"sell": true` sells. Its `ask` is keyed: `nothing` when nothing is owned (then there is no choice at all), the first thing's question id when there is an ask by that name (`poverty`, when End Poverty is all there is), and `items` otherwise.
- Outcomes: the thing's question id, such as `poverty`, when the picked option has a reaction for it; on the last row `last`, or `none` for keeping it with nothing sold; otherwise `sold` and `kept` the first time each is picked, and `again` after, which has no line.

### The receipt stage

```json
"stage": { "type": "receipt", "title": { "text": "the receipt" }, "many": { "text": "{name} x{units}" },
  "more": { "text": "and {more} more" }, "empty": { "text": "you bought nothing at all" },
  "started": { "text": "started with {start}" }, "spent": { "text": "spent {spent}" }, "left": { "text": "left with {left}" },
  "passed": { "caption": "passed on" }, "most_rows": 6, "most_passed": 4,
  "hoard_from": 80, "spend_upto": 20, "nudge": { "self_others": -0.2 } }
```

A tableau. It prints what is owned, the dearest `most_rows` when there are more, the money, and the dearest `most_passed` things passed on, then reports `hoard` (at least `hoard_from` percent of the pot left), `spend` (at most `spend_upto`) or `middle`, and nudges the profile by `nudge` times the share left.

## An option

```json
{
  "id": "pull",
  "label": "Pull the lever",
  "outcome": { "track": 1 },
  "crowd": 87,
  "profile": { "one_many": 1, "ends_rules": -1 },
  "reaction": [ "The imp's reaction." ],
  "ending": ""
}
```

- `label` is the words in the choice row: plain text, no colour tags. It may carry a placeholder its stage fills, such as `Bid {bid}`.
- `outcome` is read by the stage. The trolley stage reads `track`.
- `crowd` is the seeded share who chose it. For binary and multiple choice questions the shares add up to 100. Every number so far is a placeholder chosen to divide people.
- `profile` nudges axes from `profile_axes.json`. Negative leans toward the axis's first pole, positive toward its second. Leave it out for questions that feed no axis. An option picked again and again, as on an offer ladder, nudges every time. An entry whose value is an object instead of a number replaces the nudges for one outcome: `{ "self_others": -0.05, "broke": {} }` nudges on buying and not at all on trying without the money.
- `ending` names a secret ending the option fires; leave it out otherwise.
- `if` names a fact, or a list of facts, the run must remember for the option to be offered at all, and `unless` facts that keep it back: `"if": "class_knight"`, `"unless": [ "companion_trusted", "companion_used" ]`. Without them the option is always offered. The reveal shows bars only for the options offered, their shares scaled to add up to 100.
- `remember` names a fact, or a list, the run remembers once the option is picked, for later beats to look back on: `"remember": [ "companion_trusted", "companion_with_you" ]`. The tests walk every set of facts a run can reach and check each question still offers at least two options whose shares add up to about 100.

When how the consequence comes out decides what the imp says, `reaction` is an object keyed by the outcome the stage reports, and `ending` can be keyed the same way to fire only on some outcomes:

```json
"reaction": {
  "lives": [ "Blue, and the room held." ],
  "dies": [ "Blue, and the room came up short." ]
},
"ending": { "dies": "some_ending" }
```

Keyed lines get ids like `ch2.red_blue.blue.lives.1`. An outcome with no lines of its own gets no reaction. Each stage below lists the outcomes it reports.

## A line

A line is text, said by the imp:

```json
"You pulled. [amber]One[/amber] life swapped for [amber]five[/amber]."
```

or an object, when someone else says it or the imp's face should change:

```json
{ "text": "Please. Please, not me.", "speaker": "plea" }
{ "text": "...", "face": "smug" }
```

- `speaker` is `imp` (the default), `button`, `plea`, `headline` or `confessor`. A confessor speaks in the dialogue box; the imp keeps still and quiet while it does.
- `voice` names whose voice says the line when its speaker is one of several, as each confessor has a voice of its own: `"voice": "recliner"` is voiced as `confessor.recliner` in `tools/voice/voices.json`.
- `face` is `grin`, `smug`, `glare` or `surprised`. A line without one shows his grin.
- `direction` is a delivery note for the voice, such as `"[furious]"`, sent ahead of the line when it is voiced. It is never shown.
- `if` and `unless` say the line only on a run that remembers every `if` fact and none of the `unless` ones, as an option's do: `{ "text": "A locked gate...", "if": "class_rogue" }`. A line with neither is always said; the tests check every line with a condition is said on some run.
- `"voiced": false` keeps a line silent: it inks on with no voice, and the voice tools leave it out. The dollar break uses it for the moment the imp stops doing the voice.
- Each line becomes one or more dialogue boxes: long lines are paged by whole sentences.
- Every line gets an id from where it sits, `<chapter>.<beat>.<part>.<number>`, such as `ch1.lever.pull.1`.

### Placeholders

A line can carry placeholders the stage fills in when it is shown, such as the amount the player turned down: `"[amber]{amount}[/amber] was the number you would not go below."` Names are lowercase in curly brackets, and each stage lists the ones it fills (below). Every way a stage can fill a line is a variant with an id of its own, the line's id plus the variant, such as `ch2.price.refuse.1.3125`, so each can be voiced as its own clip. The tests check every variant against the text rules and the dialogue box.

### Words on the stage

Stage data can hold words the player reads on the stage. They follow the text rules too, but they are not lines:
- `says` anywhere in stage data is a line floating over something on the stage: plain text is a plea, a line object can name its speaker (`{ "text": "Ow!", "speaker": "button" }`), and a list holds several. They get ids like `ch2.walks_away.stage.1`.
- `text`, `caption` and `label` keys hold readouts, captions and labels, such as `"{count} dead"`. They may carry placeholders, never colour tags.

## The main menu

```json
{
  "id": "menu",
  "title": "Your Call",
  "lines": {
    "barks": [ { "text": "Still here, are we?", "face": "smug" } ],
    "new_game": [ { "text": "Starting over? The run you have goes in the bin.", "face": "smug" } ]
  }
}
```

- `title` is the title over the menu: plain text, no tags.
- `lines` holds named sets of the imp's lines, each a list of lines as anywhere else, with ids like `menu.barks.1`. `barks` are said now and then, one at a time and never the same twice running; `new_game` is the question New Game puts when there is a run to lose.
- A line can hang on what the menu knows, with `if` and `unless` as in a chapter: `run_saved` is there to continue. "Continue is greyed out" is said `unless` it.
- They are voiced like any line, by `tools/voice/voice_lines.py`.

## The text rules

These hold for everything a player reads (PREMISE.md section 9), and the tests check the mechanical ones:

- No dashes or hyphens of any kind. Write "six year old children".
- Colour tags only from the vocabulary: `[red]` death and the guilty, `[amber]` the stakes and emphasis, `[pink]` the partner and love, `[gold]` the best life, `[blue]` the blue button. One level deep, always closed, only in lines, never in labels or headings.
- The imp mocks whatever the choice and never grades it.
