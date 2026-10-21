# Architecture

How the remake is built. It describes what exists in the build, and grows as systems land. Design intent lives in `PREMISE.md`; the reasons behind each choice are in `DECISIONS.md`.

## Engine

Godot 4.7, Forward+ renderer, GDScript with static typing. The base canvas is 1920x1080 (`canvas_items` stretch, `keep` aspect, paper coloured clear colour), so every position and size in the project is in those units. The window opens maximized and the canvas scales to fit.

## Layout

| Folder | What lives there |
|---|---|
| `ink/` | The ink look: the brush that turns paths into hand-drawn lines, the boil clock, the shared style and palette, the paper ground. |
| `figures/` | The reusable rigs drawn in ink: the stick figure, its poses, and the imp. |
| `doodles/` | Ink drawings of things (props, controls) that more than one stage uses. Empty so far. |
| `stages/` | Question presentations, one folder each. A stage stages any question that uses it, from that question's data. |
| `ui/` | The dialogue box, the choice row, the crowd reveal, and the theme. |
| `game/` | The run: the main scene, the question flow, the content model and loader, the profile. |
| `content/` | The game's content as data. Its format is in `content/README.md`. |
| `assets/` | Imported files: fonts, and voice clips in `assets/voice/` (stored with Git LFS). |
| `dev/` | Development-only tools and samplers. Main adds the dev tools in debug builds only, and `dev/` stays out of release exports. |
| `tests/` | GUT tests. |
| `addons/` | Third-party addons: GUT 9.7.1. |
| `docs/` | Design docs, decision log, open questions. Hidden from Godot. |
| `tools/` | Offline tooling: the voice pipeline (`tools/voice/`, Python). Hidden from Godot. |

A feature keeps its scene, script and resources together in its folder. Files and folders are `snake_case`.

## The ink look (`ink/`)

Everything on screen is ink drawn in code. Nothing is a sprite.

- **`InkBrush`** turns a densely sampled path into a line. It nudges each point off the path along its normal by two layers of smooth 1D noise: a slow drift (the unsteady hand, the same every frame) and a small fast wiggle that changes with the boil variant. The width swells and thins along the line, loose ends taper and overshoot slightly, and a closed shape runs a little past its own start, like a pen lifted late. Short lines wobble less. The result is a triangle strip drawn with `RenderingServer.canvas_item_add_triangle_array`. It also draws fills (washes under a line) and round dots (eyes).
- **`ink_line.gdshader`** reads the strip's UVs: `UV.y` runs across the line, so the shader softens the edges by screen-space derivatives (antialiasing without MSAA), adds a faint grain along `UV.x`, and can dissolve a drawing away in noisy blotches. Fills and dots use a negative `UV.x` to skip the grain.
- **`InkStyle`** (`ink/ink_style.tres`) holds every tunable of the line: boil rate and variant count, wobble, width, taper, overshoot, sampling. **`InkPalette`** (`ink/palette.tres`) holds the colours by meaning. Tuning either retunes the whole game.
- **`Ink`** (autoload, `ink/ink.gd`) is the boil clock. Five times a second it moves the page to its next variant (three variants by default) and every ink drawing redraws, the way hand-drawn animation redraws its lines. It also keeps a running time that idle motion reads, so breathing steps with the boil. It keeps ticking while the game is paused. A drawing can instead pass a fractional variant, and the brush then blends smoothly between two boil shapes; the imp does this for his soft waver.
- **`InkLine`** is one line ready for the brush; **`InkPainter`** paints a list of them into any canvas item, drawn on in order by a `reveal` fraction. Each line's wash goes down just before the line, so a drawing lists what is behind first. The painter keeps every line at least `min_screen_width` screen pixels wide, whatever the window size or the node's scale. It also hooks Controls up to the ink material and the boil.
- **`InkDrawing`** is the Node2D every ink drawing extends. It can carry its own `InkStyle` (the imp's line is heavier and wavers more). It draws authored `InkStroke` resources or, in subclasses, lines built in code (`_build_lines`). It can draw itself on (`draw_on`) or dissolve away (`dissolve_away`), and it keeps its line width constant however the node is scaled, as a pen would. Drawings are `@tool`, so they preview in the editor.
- **Paper** (`ink/paper/paper.tscn`) is a CanvasLayer at the back with a still shader: a fine tooth, faint clouds and fibres. It never boils.

## Figures (`figures/`)

- **`StickFigure`** is every soul: a jointed rig with dot eyes. Arms are forward kinematics from the shoulders; legs are two-bone IK from the hips to planted feet, so a crouch bends the knees and the feet stay put. Knees bend outward when standing and up off the ground once the figure is lying down. It breathes, stepped with the boil. Its origin is the ground between its feet.
- **`FigurePose`** is a pose resource: hip offset, spine lean, head tilt, shoulder and elbow angles, foot offsets. As a step in a motion it also says how the figure arrives in it (duration, curve) and how long it holds. Poses blend, mirror, and live in `figures/poses/`.
- **The fold** is the shared death: `fold()` plays `buckle`, `collapse` and `down`, then dissolves the figure. Falling the other way mirrors the poses.
- **The imp** is `Imp` (behaviour) over `ImpDrawing` (art). The drawing is a crude, angular little devil in his amber tint: long thin horns, a lumpy head, sly slanted eyes over a wide grin, a boxy body, floating bent arms and a crooked tail with a square tip. He has four faces: grin, smug, glare, surprised. His line is his own style (`figures/imp/imp_ink_style.tres`). The behaviour scribbles him into being with a pop and keeps him softly alive: his line melts between shapes, he drifts on smooth noise, bobs, sways, breathes and sways his tail, and every few seconds he fidgets with an eased shrug, tail flick, bounce or cocked head. He nods and gestures while he talks, and hops to a fresh spot in one of the two side wings, never onto the stage.

## Stages (`stages/`)

A **`Stage`** is a question's presentation. The question player drives every stage through the same calls: `setup(question)`, `enter()`, `set_choosing(active)`, `highlight_option(index)`, `play_consequence(index)` and `leave()`. A stage reports its in-scene controls through `option_hovered` and `option_committed`. By default `enter` draws every ink drawing on and `leave` dissolves them. Stage scenes live at `stages/<type>/<type>_stage.tscn`, where `<type>` is the question's `stage.type`.

**The trolley stage** builds itself from `stage.tracks`, a list of tracks each with its figures. Track 0 runs straight on; the others branch off at the split. The lever stands for the first option whose outcome leaves track 0. Pulling throws the lever, then the trolley rolls along the approach and down the chosen track, speeding up all the way. Each soul folds as the trolley's front reaches it, and the trolley dissolves off the end of the line. `Track` draws two rails and sleepers along a smooth path and answers positions by distance along it. `TrolleyCart` is the tram, filled with paper so it hides what it passes. `Lever` lifts when pointed at and throws when clicked.

## UI (`ui/`)

- **`DialogueBox`**: the hand-drawn `InkFrame` (gone over twice, on box paper) sized to its text and growing upward from just above the bottom edge. `Pager` splits each line into pages of whole sentences, as few as fit in three lines and as even as possible, closing and reopening a colour tag across a break. Text inks on through `InkOnEffect`, a rich text effect that fades characters in by a schedule: a steady pace with breaths after punctuation. The page is laid out in full first, so nothing shifts. A click or key finishes the page, then moves on. The schedule is the hook for voice: it can come from audio timings instead.
- **`ChoiceRow`**: the options as muted hand-lettered `ChoiceWord`s above the box. Pointing lifts a word to amber and draws an `InkUnderline`; picking keeps the pick amber and fades the rest. Mouse or number keys. A stage control (the lever) lights and picks options through the same calls.
- **`CrowdReveal`**: the lowercase muted heading, then a `CrowdRow` per option, each a label over a `CrowdBar` that inks in from the left while its bare number counts up past its end. The pick is amber, the crowd darker ink. While it is up it is the only thing listening: the first input finishes the inking, the next dismisses it.
- **Theme** (`ui/theme/ink_theme.tres`, set as the project theme): Caveat at weight 600 (`caveat_semibold.tres`), 44 px, warm ink colour.

## The question loop (`game/`)

**`QuestionPlayer.play(question, profile)`** is the core loop as one chain of awaits:

1. The stage is built from the question's data and draws itself on.
2. The imp asks: `dialogue.say(ask, hold_last)` leaves the last page up.
3. The choice row offers the options above the box while the stage's controls are live. The lever and the row light and pick in sync.
4. The box clears and the stage plays the consequence.
5. The imp reacts over the world, page by page. The click on the last page is the gate.
6. The reaction clears, the profile takes the option's silent nudges, and the stage dissolves.
7. The crowd reveal shows how others chose until the player dismisses it.

`phase_changed` reports each step for tools. **`Main`** loads the content, scribbles the imp in, wires the imp to the dialogue box (a hop per box, a nod while text inks on, the line's face if it names one), and for now plays 1.02 The Lever on repeat.

**`Profile`** is the silent portrait: a signed leaning per axis, never shown during play. The axes come from `content/profile_axes.json`.

## Content (`content/`, `game/content/`)

Content is JSON, one file per chapter, read by **`ContentLoader`** into `ChapterData`, `QuestionData`, `NarrationData`, `OptionData` and `LineData`. The loader never stops on a problem: it keeps what it can and lists each problem with where it is, and the tests fail on any. Every line gets a stable id from where it sits, such as `ch1.lever.pull.1`. **`Markup`** handles the colour tags: stripping them, turning them into palette colours, and checking them; it also checks for dashes. The format is documented in `content/README.md`.

## Voice (`tools/voice/`, `game/voice/`)

Lines are voiced with ElevenLabs. Each line is one take, so its delivery flows across its sentences, and the game plays a page at a time out of it.

- **Casting.** `design_auditions.py` designs candidate voices from written descriptions into `voice_auditions/` (ignored by git and Godot). `save_voice.py` saves the chosen one as a permanent ElevenLabs voice and records it per speaker in `tools/voice/voices.json`, with the TTS model and settings.
- **Voicing.** `voice_lines.py` asks Godot for every line (`dev/export_voice_lines.gd`: id, speaker, spoken text, SHA-1), then voices each line whose speaker has a voice and whose clip is missing or out of date. It uses the with-timestamps endpoint, so every clip comes with the time each character is spoken. A clip is out of date when its text or its voice settings change. Clips go to `assets/voice/<speaker>/<line id>.mp3`, timings beside them as `.json`, and `assets/voice/manifest.json` records the text hash and voice signature of each.
- **Playing.** `VoiceLibrary` looks a line's clip up by id and only returns it while the line's spoken text still hashes to what the clip was made from; recolouring a line keeps its voice, rewording it silences it until it is voiced again. `VoiceClip` gives the stretch of the take for a page's characters and when each character starts. `DialogueBox` plays that stretch on the Voice bus and inks the page on in time with it, reading the audio clock. The first click finishes the page while the voice plays on; the next moves on, fading the voice out on one of two players so it never cuts off the next take.
- **The key** is read from `.env` or `ELEVENLABS_API_KEY` and never printed.

## Development tools (`dev/`)

All of these run from the command line; see CLAUDE.md for the exact commands.

- `check_scripts.gd` loads every script and fails if any does not compile (the headless import alone does not catch parse errors).
- `dev_tools.tscn` (debug builds only): F5 restarts, F3 shows the phase and the profile. On the command line it can force a window size, autoplay a question (pick an option, or point at and click the lever with synthetic pointer events), speed the game up, save a screenshot before each click and a burst during the consequence, and quit after a number of questions.
- `capture_runner.tscn` runs any scene and saves screenshots at set times.
- `export_voice_lines.gd` writes every line's id, speaker, spoken text and hash for the voice tools.
- `ink_sampler`, `figure_sampler` and `imp_sampler` show the line, the poses and fold, and the imp's faces and hops on their own.

## Tests (`tests/`)

GUT 9.7.1, run headless from the command line. `tests/unit/` covers the markup, paging, the profile and the content loader. `tests/content/` loads every chapter and enforces the text rules: no loader problems, no dashes in anything player-facing, well formed colour tags, no tags in labels or headings, display-only crowd splits that add up to 100, and a stage scene for every question.
