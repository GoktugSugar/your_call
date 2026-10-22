# Content format

The game's questions and narration live here as data. Adding a question means adding data, and its stage and doodles if they are new, never new flow code. Copy changes are made here; `docs/SCRIPT.md` is the draft the content was converted from.

- `chapters/*.json`: one file per chapter, its beats in play order.
- `profile_axes.json`: the silent profile's axes.
- `countries.json`: the countries the pin in 2.10 can land on: name, ISO code, people, and where on the map.

The tests in `tests/content/` load every chapter and fail on any problem, so run them after editing.

## A chapter

```json
{
  "id": "ch1",
  "title": "The Tracks",
  "beats": [ ...beats in play order... ]
}
```

## A beat

Either some narration from the imp:

```json
{ "kind": "narration", "id": "taunt", "lines": [ "...", "..." ] }
```

a cinematic, which plays the scene `cinematics/<scene>/<scene>_cinematic.tscn`:

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
- `reveal.heading` is the reveal's heading. `reveal.labels` (optional) puts other words over the bars than the option labels, one per option, such as "took the money" for "Press it". `reveal.mark` (optional) names the line a coordination gamble's crowd had to cross, such as "half".

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

- `label` is the words in the choice row: plain text, no colour tags.
- `outcome` is read by the stage. The trolley stage reads `track`.
- `crowd` is the seeded share who chose it. For binary and multiple choice questions the shares add up to 100. Every number so far is a placeholder chosen to divide people.
- `profile` nudges axes from `profile_axes.json`. Negative leans toward the axis's first pole, positive toward its second. Leave it out for questions that feed no axis. An option picked again and again, as on an offer ladder, nudges every time.
- `ending` names a secret ending the option fires; leave it out otherwise.

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

- `speaker` is `imp` (the default), `button`, `plea`, `headline` or `confessor`.
- `face` is `grin`, `smug`, `glare` or `surprised`. A line without one shows his grin.
- `direction` is a delivery note for the voice, such as `"[furious]"`, sent ahead of the line when it is voiced. It is never shown.
- Each line becomes one or more dialogue boxes: long lines are paged by whole sentences.
- Every line gets an id from where it sits, `<chapter>.<beat>.<part>.<number>`, such as `ch1.lever.pull.1`.

### Placeholders

A line can carry placeholders the stage fills in when it is shown, such as the amount the player turned down: `"[amber]{amount}[/amber] was the number you would not go below."` Names are lowercase in curly brackets, and each stage lists the ones it fills (below). Every way a stage can fill a line is a variant with an id of its own, the line's id plus the variant, such as `ch2.price.refuse.1.3125`, so each can be voiced as its own clip. The tests check every variant against the text rules and the dialogue box.

### Words on the stage

Stage data can hold words the player reads on the stage. They follow the text rules too, but they are not lines:
- `says` anywhere in stage data is a line floating over something on the stage: plain text is a plea, a line object can name its speaker (`{ "text": "Ow!", "speaker": "button" }`), and a list holds several. They get ids like `ch2.walks_away.stage.1`.
- `text`, `caption` and `label` keys hold readouts, captions and labels, such as `"{count} dead"`. They may carry placeholders, never colour tags.

## The text rules

These hold for everything a player reads (PREMISE.md section 9), and the tests check the mechanical ones:

- No dashes or hyphens of any kind. Write "six year old children".
- Colour tags only from the vocabulary: `[red]` death and the guilty, `[amber]` the stakes and emphasis, `[pink]` the partner and love, `[gold]` the best life, `[blue]` the blue button. One level deep, always closed, only in lines, never in labels or headings.
- The imp mocks whatever the choice and never grades it.
