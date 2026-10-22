# Architecture

How the remake is built. It describes what exists in the build, and grows as systems land. Design intent lives in `PREMISE.md`; the reasons behind each choice are in `DECISIONS.md`.

## Engine

Godot 4.7, Forward+ renderer, GDScript with static typing. The base canvas is 1920x1080 (`canvas_items` stretch, `keep` aspect, paper coloured clear colour), so every position and size in the project is in those units. The window opens maximized and the canvas scales to fit.

## Layout

| Folder | What lives there |
|---|---|
| `ink/` | The ink look: the brush that turns paths into hand-drawn lines, the boil clock, the shared style and palette, the paper ground. |
| `figures/` | The reusable rigs drawn in ink: the souls (the stick figure, its poses and kinds, the baby) and the imp. |
| `doodles/` | The doodles a would you rather shows, one script each, named by id (`doodles/<id>.gd`). |
| `cinematics/` | Cinematic beats, one folder each (`cinematics/<name>/<name>_cinematic.tscn`): the opening crash and the waking that opens every later chapter, with the eyelids they share at the root. |
| `stages/` | Question presentations, one folder each. A stage stages any question that uses it, from that question's data. Controls more than one stage uses, such as the push button, are in `stages/controls/`. |
| `ui/` | The dialogue box, the choice row, the crowd reveal, the credits, and the theme. |
| `game/` | The run: the main scene, the question flow, the content model and loader, the profile. |
| `content/` | The game's content as data. Its format is in `content/README.md`. |
| `assets/` | Imported files: fonts, music in `assets/audio/music/`, and voice clips in `assets/voice/` (stored with Git LFS). |
| `dev/` | Development-only tools and samplers. Main adds the dev tools in debug builds only, and `dev/` stays out of release exports. |
| `tests/` | GUT tests. |
| `addons/` | Third-party addons: GUT 9.7.1. |
| `docs/` | Design docs, decision log, open questions. Hidden from Godot. |
| `tools/` | Offline tooling: the voice pipeline (`tools/voice/`, Python). Hidden from Godot. |

A feature keeps its scene, script and resources together in its folder. Files and folders are `snake_case`.

## The ink look (`ink/`)

Everything on screen is ink drawn in code. Nothing is a sprite.

- **`InkBrush`** turns a densely sampled path into a line. It nudges each point off the path along its normal by two layers of smooth 1D noise: a slow drift (the unsteady hand, the same every frame) and a small fast wiggle that changes with the boil variant. The width swells and thins along the line, loose ends taper and overshoot slightly, and a closed shape runs a little past its own start, like a pen lifted late. Short lines wobble less. The result is a triangle strip drawn with `RenderingServer.canvas_item_add_triangle_array`. It also draws fills (washes under a line) and round dots (eyes), and lays out the crayon scribble that colours in a shape (`hatch_ellipse`: back and forth strokes joined into one zigzag, kept inside the edge).
- **`ink_line.gdshader`** reads the strip's UVs: `UV.y` runs across the line, so the shader softens the edges by screen-space derivatives (antialiasing without MSAA), adds a faint grain along `UV.x`, and can dissolve a drawing away in noisy blotches. Fills and dots use a negative `UV.x` to skip the grain.
- **`InkStyle`** (`ink/ink_style.tres`) holds every tunable of the line: boil rate and variant count, wobble, width, taper, overshoot, sampling. **`InkPalette`** (`ink/palette.tres`) holds the colours by meaning. Tuning either retunes the whole game.
- **`Ink`** (autoload, `ink/ink.gd`) is the boil clock. Five times a second it moves the page to its next variant (three variants by default) and every ink drawing redraws, the way hand-drawn animation redraws its lines. It also keeps a running time that idle motion reads, so breathing steps with the boil. It keeps ticking while the game is paused. A drawing can instead pass a fractional variant, and the brush then blends smoothly between two boil shapes; the imp does this for his soft waver.
- **`InkLine`** is one line ready for the brush; **`InkPainter`** paints a list of them into any canvas item, drawn on in order by a `reveal` fraction. Each line's wash goes down just before the line, so a drawing lists what is behind first. The painter keeps every line at least `min_screen_width` screen pixels wide, whatever the window size or the node's scale. It also hooks Controls up to the ink material and the boil.
- **`InkDrawing`** is the Node2D every ink drawing extends. It can carry its own `InkStyle` (the imp's line is heavier and wavers more). It draws authored `InkStroke` resources or, in subclasses, lines built in code (`_build_lines`). It can draw itself on (`draw_on`) or dissolve away (`dissolve_away`), and it keeps its line width constant however the node is scaled, as a pen would. Drawings are `@tool`, so they preview in the editor.
- **Paper** (`ink/paper/paper.tscn`) is a CanvasLayer at the back with a still shader: a fine tooth, faint clouds and fibres. It never boils.

## Figures (`figures/`)

- **`Soul`** is anything on a stage that can die. `fold()` takes it down and dissolves it, then emits `folded`; the base only dissolves, and souls with a body to fall override it.
- **`StickFigure`** is the soul almost everyone is: a jointed rig with dot eyes. Arms are forward kinematics from the shoulders; legs are two-bone IK from the hips to planted feet, so a crouch bends the knees and the feet stay put. Knees bend outward when standing and up off the ground once the figure is lying down. It breathes, stepped with the boil. Its origin is the ground between its feet. Small switchable details set souls apart without new art: open, closed or hidden eyes, a pregnant belly, a cane, tufts of hair, a crown, a beating heart over the head and z marks drifting up from it. The heart and the z marks move on the page clock and redraw with the boil, like breathing. `head_top()` says where something floating over the figure goes.
- **Walking.** `walk_to(x, speed)` walks a stick figure along the ground and emits `arrived`. `FigureWalk` plans the walk ahead: where each foot lands, so a planted foot never slides, and the body's pose at any moment (a dip just after each landing, arms swinging opposite the legs, a lean into the walk). The figure faces the way it goes (`facing`: front, left or right, which slides the eyes and bends the knees that way) and ends standing in its pose. Its own pace is a stride every `step_time`; a set speed quickens the steps. Big motion like this runs at full frame rate.
- **`BabyBundle`** is the one soul that is not a stick figure: a swaddled bundle with a round head, lying on the rails.
- **`SoulKind`** (`figures/kinds/<kind>.tres`) is one kind of soul as data: the scene it is made from, the palette role it is drawn in, its size, its pose and its details, and whether it falls when hit (a soul already lying down only dissolves). Content names kinds by file name: `stranger`, `guilty` (red), `partner` (pink, with the heart), `child` (smaller), `elderly` (stooped, cane, hair), `pregnant` (belly, a hand under it), `sleeper` (lying on the rail, eyes closed, z marks), `best_life` (gold, crowned) and `baby`. `make()` builds a soul of the kind.
- **`FigurePose`** is a pose resource: hip offset, spine lean, head tilt, shoulder and elbow angles, foot offsets. As a step in a motion it also says how the figure arrives in it (duration, curve) and how long it holds. Poses blend, mirror, and live in `figures/poses/`.
- **The fold** is the shared death: `fold()` plays `buckle`, `collapse` and `down`, then dissolves the figure. Falling the other way mirrors the poses.
- **The imp** is `Imp` (behaviour) over `ImpDrawing` (art). The drawing is a crude, angular little devil in his amber tint: long thin horns, a lumpy head, sly slanted eyes over a wide grin, a boxy body, floating bent arms and a crooked tail with a square tip. He has four faces: grin, smug, glare, surprised. His line is his own style (`figures/imp/imp_ink_style.tres`). The behaviour scribbles him into being with a pop and keeps him softly alive: his line melts between shapes, he drifts on smooth noise, bobs, sways, breathes and sways his tail, and every few seconds he fidgets with an eased shrug, tail flick, bounce or cocked head. He nods and gestures while he talks, and hops to a fresh spot in one of the two side wings, never onto the stage.

## Stages (`stages/`)

A **`Stage`** is a question's presentation. The question player drives every stage through the same calls: `setup(question)`, `enter()`, `set_choosing(active)`, `highlight_option(index)`, `play_consequence(index)` and `leave()`. A stage reports its in-scene controls through `option_hovered` and `option_committed`, and `option_point(index)` says where on the canvas an option can be picked in the scene, if it can. By default `enter` draws every ink drawing on and `leave` dissolves them. Stage scenes live at `stages/<type>/<type>_stage.tscn`, where `<type>` is the question's `stage.type`.

A stage can do more, each with a default that does nothing:
- **Report how the consequence came out.** `play_consequence` returns an outcome, such as `lives` or a ladder's amount, which picks the imp's reaction and any secret ending.
- **Bring the offer round again.** `another_round()` keeps an offer ladder going after each acceptance.
- **Take the choice by itself.** A stage that `chooses_alone()` has no choice row; the question player awaits its `choose()`.
- **Fill placeholders.** `fills()` and `fill_keys()` give the values its question's lines are filled with right now, and `fill(lines)` fills them. A static `fill_variants(question)` on the stage's script lists every filling its lines can take, and `const FILLS` names the placeholders; `StageFills` reads both for the tests and the voice tools.
- **Make its own reveal.** `reveal_split(pick)` returns a `RevealSplit`, by default the question's own.
- **Talk.** The question player hands every stage the dialogue box (`dialogue`), for a stage whose imp speaks at moments of its own.

**The push button** (`stages/controls/push_button.tscn`, `PushButton`) is the in-scene control most of Chapter 2 is pressed with: a round cap coloured in with a crayon scribble inside its pen line, sitting in a base. Its `ButtonLook` (`stages/controls/looks/<look>.tres`) sets the cap's colour and its mark; content names looks by file name: `plain`, `blue` (a ring), `red` (a dot), `green` and `gold` (a dollar sign), so the blue and red buttons never depend on colour alone. While it is live, pointing lifts the cap and clicking emits `clicked`; `highlighted` lifts it from the choice row; `press()` sinks the cap behind the front of the base and springs it back. It can carry a word on its cap (`text`), which goes on and off with the drawing.

**The trolley stage** builds itself from `stage.tracks`, a list of tracks each with its souls, named by kind. It shows the `TrackLayout` with as many routes as there are tracks:

- **Two tracks make a fork.** Track 0 runs straight on and track 1 branches off at the split. The lever stands for the first option whose outcome leaves track 0. Pulling throws the lever, then the trolley rolls along the approach and down the chosen track.
- **Three make a fan**, read top to bottom as first, second and third, with no lever. Pointing at a route lights it amber and clicking picks it; the choice row lights the same route.

The trolley speeds up all the way. Each soul folds as the trolley's front reaches it, and the trolley dissolves off the end of the line. The data can also ask for:

- **A plea** (`{"kind": ..., "says": ...}` in place of a kind): the soul holds its hands clasped, and a `Plea` inks the words on over its head once the stage is drawn. They bob with the boil and fade when the soul dies or the stage goes.
- **`roped`**: a `Rope` ties the track's souls together at the waist. It goes when the first of them is hit.
- **`"facing": "away"`**: the track's souls have no eyes, turned from the player.
- **`dark`**: a `Darkness`, a heavy ink wash with a scribbled edge, hides the track from the middle on. A trolley sent into it stops there unseen, and the dark lifts once the trolley has rolled.
- **`rolling`** (on the stage): the trolley creeps toward the split while the player decides, slowing as it nears so it never arrives on its own.

`Track` draws two rails and sleepers along a smooth path and answers positions by distance along it. `TrolleyCart` is the tram, filled with paper so it hides what it passes. `Lever` lifts when pointed at and throws when clicked.

**The doodles stage** is the quick would you rather: two small ink doodles side by side, each over its option's label, with a muted "or" between them. `stage.doodles` names them, left then right, and `DoodlesStage.make_doodle(id)` builds each from its script in `doodles/`. Pointing at a doodle lifts it and lights its label, and clicking it picks it; the choice row lifts the same doodle. On the pick an amber loop draws itself around the chosen doodle while the other one, its label and the "or" dissolve, and the pick hops once. A doodle is an `InkDrawing` built in code, standing on its origin.

**The gamble stage** is the coordination gamble: the soul at stake standing apart, and a push button per option, its look named by the option's `outcome.button`. The room has voted already: its share for the gamble's button is the gamble option's crowd, and `stage.random` is the share of the room pressing at random, drawn again every play. Pressing the gamble's button makes the soul glance about while the room is counted; it lives if the room's share passed `stage.line`, and folds if not. The other button keeps it alive. A soul that lives walks out of the room, fading as it goes. Outcomes `lives` and `dies`; the reveal shows the room's vote in the buttons' colours with the line marked.

**The offer stage** is the escalating offer, a ladder: one button, the amount on offer over it, and readouts under it. `stage.tiers` lists each tier's amount and the share who took it. Taking an offer presses the button (and in 2.03 a stranger inks itself in off to the side and folds) and brings the offer back at the next tier; a tier that `repeats` comes back at the same amount. Stopping ends it, and the reveal shows the split at the tier the player stopped on. Outcomes: the amount taken, `again` for a repeated tier, and `high` or `low` on stopping when `stage.high_from` is set.

**The timer stage** takes the choice by itself: one button with a word on it and a clock counting down over it. The imp's `countdown` lines drop in at `stage.cues` without waiting for clicks, and the player presses the button (or key 1) or lets the clock run out.

**The button stage** is one button alone. The option whose outcome has `press` presses it.

**The better offer stage** is a button and the best life: the golden soul inks itself in on the ask line `stage.cue`. Taking it presses the button, and the soul hops for joy and strolls off, fading; keeping your own, it turns its back and fades.

**The nuke stage** is a red button that cures cancer at the price of one random country from `content/countries.json`. Pressed, a hand-drawn world map inks itself in, a red pin goes round and round over it while the imp says his `spin` lines, then drops onto the country; its name and people ink on beside it and a mushroom cloud doodles onto the spot. Outcomes, in order: `home` when the pin lands on the player's own country (from the system's region), the country's code when there is a reaction for it, or the key of its band by people (`stage.bands`). It fills `{country}` and `{people}`.

## Cinematics (`cinematics/`)

A cinematic is a CanvasLayer over everything with a `play()` the run player awaits. An advance press skips it, but not in its first moments, so the click that focuses the window does not throw it away.

- **The crash** (`cinematics/crash/`) opens the game. `CrashView` is the memory in pale ink on black: a night road, its centre line streaming by, and two headlights bearing down, their glow on a canvas item of its own without the ink material so it falls off smoothly. `CrashCinematic` flickers it at a low frame rate with frames lost to black, swerves the view, lands the hit with a white flash and a shake (emitting `hit`, for its sound), cuts to black, then wakes.
- **The eyelids** (`cinematics/eyelids.tscn`, `Eyelids`) are the waking both cinematics share: `eyelids.gdshader`, on a ColorRect, clears the dark in uneven blotches that blink, drift and sharpen as the eyes focus (`open()`), or closes it in the same way run backwards, drooping, fluttering and shutting (`close()`).
- **The waking** (`cinematics/waking/`) opens every chapter after the first: the eyes close on the empty page, the dark holds, and they open again. It sits over the dialogue box and under the credits.

## UI (`ui/`)

- **`DialogueBox`**: the hand-drawn `InkFrame` (gone over twice, on box paper) sized to its text and growing upward from just above the bottom edge. `Pager` splits each line into pages of whole sentences, as few as fit in three lines and as even as possible, closing and reopening a colour tag across a break. Text inks on through `InkOnEffect`, a rich text effect that fades characters in by a schedule: a steady pace with breaths after punctuation. The page is laid out in full first, so nothing shifts. A click or key finishes the page, then moves on. The schedule is the hook for voice: it can come from audio timings instead. `say(lines, hold_last, auto)` can move each page on by itself once it has been said and has stayed up for `auto_hold`. `interject(line)` throws a line's first page up at once, in place of whatever is there, without waiting or taking clicks, the way the imp needles over the timer.
- **`ChoiceRow`**: the options as muted hand-lettered `ChoiceWord`s above the box. Pointing lifts a word to amber and draws an `InkUnderline`; picking keeps the pick amber and fades the rest. Mouse or number keys. A stage control (the lever, a button) lights and picks options through the same calls.
- **`CrowdReveal`**: the lowercase muted heading, then a `CrowdRow` per option, each a label over a `CrowdBar` that inks in from the left while its bare number counts up past its end. The pick is amber, the crowd darker ink. While it is up it is the only thing listening: the first input finishes the inking, the next dismisses it. It shows a `RevealSplit`: the heading, labels, shares and pick, and optionally meaning colours for the bars (the pick's label still goes amber) and a `CrowdMark`, an ink line across the bars at the share a coordination gamble's crowd had to pass, with its name over it.
- **`Credits`**: a clean paper page over everything; the title and each credit (the role in amber over the name in ink) scroll up from `content/credits.json`, and the page fades. A press hurries them along.
- **Theme** (`ui/theme/ink_theme.tres`, set as the project theme): Caveat at weight 600 (`caveat_semibold.tres`), 44 px, warm ink colour.

## The question loop (`game/`)

**`QuestionPlayer.play(question, profile)`** is the core loop as one chain of awaits:

1. The stage is built from the question's data and draws itself on.
2. The imp asks: `dialogue.say(ask, hold_last)` leaves the last page up. Placeholders are filled by the stage.
3. The choice row offers the options above the box while the stage's controls are live. The lever, a button or a doodle and the row light and pick in sync. A stage that takes the choice by itself (the timer) does so with no row.
4. The box clears and the stage plays the consequence, which reports how it came out.
5. The imp reacts over the world to that outcome, page by page. The click on the last page is the gate.
6. The profile takes the option's silent nudges. On an offer ladder the offer comes round again (back to 3), with the imp's line for the round held up while the player chooses again (`round_lines`: hold, auto or click).
7. The reaction clears, the stage dissolves, and the crowd reveal shows the stage's split until the player dismisses it.

`phase_changed` reports each step and `choosing_started` each choice, for tools. When an outcome fires a secret ending, the loop stops after the reaction, returns the ending, and leaves the stage up for the run player to take down.

**`RunPlayer.play_run(chapters, profile, from_chapter, from_beat)`** plays the chapters in order, and **`play_chapter`** a chapter's beats in order, from the top or from a named beat. A cinematic beat plays its scene (`cinematics/<name>/<name>_cinematic.tscn`, awaited through `play()`) over everything. A narration beat has the imp say its lines, and a question beat goes to the question player; the imp scribbles himself in before the first beat that needs him, and takes his leave at the end of each chapter. A secret ending ends the run: a beat's pause, then the stage dissolves, the imp fades and the credits roll (`ui/credits/credits.tscn`, awaited through `roll()`). A scene that does not exist yet is skipped with a warning, so the run never stalls on it.

**`Main`** loads the run (`content/run.json`: the chapters in order), wires the imp to the dialogue box (a hop per box, a nod while text inks on, the line's face or else his grin), and for now plays the run from the top over and over, with a fresh profile each run.

**`Profile`** is the silent portrait: a signed leaning per axis, never shown during play. The axes come from `content/profile_axes.json`.

## Content (`content/`, `game/content/`)

Content is JSON, one file per chapter, read by **`ContentLoader`** into `ChapterData`, `CinematicData`, `QuestionData`, `NarrationData`, `OptionData` and `LineData`. The loader never stops on a problem: it keeps what it can and lists each problem with where it is, and the tests fail on any. Every line gets a stable id from where it sits, such as `ch1.lever.pull.1`; a line can carry a voice direction for the voice tools. Words a soul says on the stage are collected into the question's stage lines (`ch1.begging.stage.1`), so they are checked and exported like any other line; readouts and captions are collected as stage texts. `all_lines()` on any beat lists every line it can show. **`Markup`** handles the colour tags: stripping them, turning them into palette colours, and checking them; it also finds placeholders and checks for dashes and stray braces. **`Numbers`** writes money and big counts the way the player reads them ("$12,500").

A reaction or an ending can be keyed by the outcome the stage reports (`OptionData.reaction_for`, `ending_for`), and a question can hold named sets of lines its stage says (`lines_in`). A line's placeholders are filled by `LineData.filled(fills, keys)`, whose copy's id ends with the keys of the values it used, so a filling has the same id wherever it is made. The format is documented in `content/README.md`.

## Voice (`tools/voice/`, `game/voice/`)

Lines are voiced with ElevenLabs. Each line is one take, so its delivery flows across its sentences, and the game plays a page at a time out of it.

- **Casting.** `design_auditions.py` designs candidate voices from written descriptions into `voice_auditions/` (ignored by git and Godot). `save_voice.py` saves the chosen one as a permanent ElevenLabs voice and records it per speaker in `tools/voice/voices.json`, with the TTS model and settings.
- **Voicing.** `voice_lines.py` asks Godot for every line (`dev/export_voice_lines.gd`: id, speaker, spoken text, SHA-1; a line with placeholders once for every filling its stage lists, each under its own id), then voices each line whose speaker has a voice and whose clip is missing or out of date. It uses the with-timestamps endpoint, so every clip comes with the time each character is spoken. A clip is out of date when its text or its voice settings change. Clips go to `assets/voice/<speaker>/<line id>.mp3`, timings beside them as `.json`, and `assets/voice/manifest.json` records the text hash and voice signature of each.
- **Playing.** `VoiceLibrary` looks a line's clip up by id and only returns it while the line's spoken text still hashes to what the clip was made from; recolouring a line keeps its voice, rewording it silences it until it is voiced again. `VoiceClip` gives the stretch of the take for a page's characters and when each character starts. `DialogueBox` plays that stretch on the Voice bus and inks the page on in time with it, reading the audio clock. The first click finishes the page while the voice plays on; the next moves on, fading the voice out on one of two players so it never cuts off the next take.
- **The key** is read from `.env` or `ELEVENLABS_API_KEY` and never printed.

## Audio (`game/audio/`, `default_bus_layout.tres`)

Buses: Master, with Music, SFX and Voice under it. The Voice bus starts with a pitch shift, which the dialogue box sets so a voice played faster keeps its pitch (`voice_speed`). The `Music` autoload loops one quiet track under everything, carried across scene changes, fading it in and dipping it while someone talks. A missing track is silence.

## Development tools (`dev/`)

All of these run from the command line; see CLAUDE.md for the exact commands.

- `check_scripts.gd` loads every script and fails if any does not compile (the headless import alone does not catch parse errors).
- `dev_tools.tscn` (debug builds only): F5 restarts, F3 shows the chapter, the phase and the profile. On the command line it can force a window size, start the run at a named chapter and beat, autoplay a question (pick an option in the choice row, or point at it on the stage and click it there with synthetic pointer events: the lever, a track, a doodle, a button; a list of picks for an offer that comes round again; on a stage that takes the choice by itself, click there or leave it be), speed the game up, save a screenshot before each click, a burst during the consequence and one every few seconds throughout, and quit after a number of questions.
- `capture_runner.tscn` runs any scene and saves screenshots at set times.
- `export_voice_lines.gd` writes every line's id, speaker, spoken text and hash for the voice tools.
- `ink_sampler`, `figure_sampler` and `imp_sampler` show the line, the poses and fold, and the imp's faces and hops on their own. `soul_sampler` shows every soul kind side by side, with a plea, a roped pair, a soul turned away, a patch of the dark and a soul walking back and forth. `doodle_sampler` shows every doodle and previews the doodles stage; `button_sampler` shows every push button look, lifted, half pressed and with a word; `cinematic_sampler` plays the crash, the waking (alone with `--waking`) and the credits.

## Tests (`tests/`)

GUT 9.7.1, run headless from the command line. `tests/unit/` covers the markup, lines and their fillings, paging, the profile, the content loader, the doodles and their stage, and the stick figure's walk and crown. `tests/content/` loads every chapter and enforces the text rules: no loader problems, no dashes in anything player-facing, well formed colour tags, no tags in labels, headings or stage words, no stray braces, every placeholder one its stage fills, display-only crowd splits that add up to 100, a stage scene for every question, a scene for every cinematic and a soul kind for every soul on a track. `test_credits.gd` and `test_countries.gd` check the credits and the country list the same way. `test_dialogue_pages.gd` shows every page of every line, every filling of a line with placeholders included, at the size the dialogue box gives it, and checks it keeps the lines it was measured on.
