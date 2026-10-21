# Your Call

A narrative dark comedy for PC and Steam, remade from scratch in Godot 4.7 with GDScript. You are dead. A small ink imp runs you through a long line of questions with no right answer, and quietly builds a portrait of who you are. Only the premise and the questions carried over from the first version, which was built in Unity.

**Read first:** `docs/PREMISE.md` (pillars, core loop, the imp, writing rules, art direction), `docs/ARCHITECTURE.md` (how it is built), `docs/DECISIONS.md` (what was decided and why) and `docs/OPEN_QUESTIONS.md` (what is not settled). The content draft is `docs/SCRIPT.md`.

## Working rules

- **Who decides.** Technical decisions (architecture, data format, tooling, how the ink look is made) are the developer's: make them, tell the user in a line or two, and log them. Creative decisions (the pillars, the endings, the tone, what gets cut or rewritten) are the user's: bring them to the user. If something isn't specified, ask rather than invent, and park it in `docs/OPEN_QUESTIONS.md` meanwhile.
- **Docs are the source of truth** and stay in sync with the build. Append a dated entry to `docs/DECISIONS.md` whenever a decision is made or changes, and update the doc it touches.
- **Nothing is ported from the Unity project**: no code, scenes, art, audio, fonts or conventions.
- **Git.** `main` stays runnable. Feature work goes on `feat/<short-description>` branches and is merged by pull request once the user signs off at a check-in. Small, focused commits with imperative messages.
- **Content is data, not code.** Adding a question means adding data under `content/` (and its doodles), never new flow code.
- **Small single-purpose pieces**, composed in scenes and decoupled with signals. No god scripts.
- **No magic numbers.** Every value a designer might tweak (durations, delays, sizes, thresholds, weights, seeds, colours) is an `@export` with a sensible default, or lives in a shared tuning resource.
- **Player-facing text** (dialogue, options, labels, headings, barks, credits) follows PREMISE section 9:
  - no dashes of any kind, and no hyphenated compounds ("six year old children")
  - colour tags only from the vocabulary (`[red]`, `[amber]`, `[pink]`, `[gold]`, `[blue]`), only in narration, never in choice labels, and stripped before TTS
  - the imp mocks whatever the choice and never grades it; the five secret endings are the only breaks
- **Secrets stay out of the repo.** The ElevenLabs API key comes from the `ELEVENLABS_API_KEY` environment variable or a git-ignored `.env`, and is never committed or logged.

## Godot conventions

- Static typing everywhere: typed variables, parameters and return types; `:=` where the type is obvious.
- `snake_case` files, folders, functions and variables; `PascalCase` for `class_name`; `UPPER_SNAKE` constants; private members start with `_`; signals are past tense (`option_committed`).
- Folders by feature (`docs/ARCHITECTURE.md` has the map). A scene, its script and its resources sit together.
- Call down, signal up. Autoloads stay few and small, and only for truly global services.
- Input goes through Input Map actions, never raw keycodes. A component listens for input only while it is active.
- Tunables are `@export`ed, grouped with `@export_group`, with defaults that work. Shared tuning lives in resources.
- A beat's flow is written as a readable chain of `await`s on small components.
- `##` doc comments on every class and on every public member a designer or caller touches.
- Match the surrounding code: its comment density, naming and idiom.

## Running and checking

The editor is the 4.7.2 standard build in `C:/Program Files/Godot/`. There is no Godot MCP server: run and check everything from the command line.

`G` below stands for `"C:/Program Files/Godot/Godot_Console.exe"`.

- Import (also refreshes the class cache after adding a `class_name`): `G --headless --path . --import`
- Check every script compiles (import alone misses parse errors): `G --headless --path . -s res://dev/check_scripts.gd`
- Run the tests: `G --headless --path . -s addons/gut/gut_cmdln.gd`
- Run the game: `"C:/Program Files/Godot/Godot.exe" --path .` (F5 restarts, F3 shows the phase and the silent profile)
- Look before you claim a visual change works. Autoplay a question and save a screenshot before each click, plus a burst during the consequence:
  `G --path . -- --window=1920x1080 --autoplay=1 --speed=2 --shots=<scratch>/run --burst=0.25 --quit-after=1`
  (`--autoplay=lever` clicks the stage's lever instead of a choice word.) Any other scene: `G --path . res://dev/capture_runner.tscn -- --window=1920x1080 --scene=res://... --out=<scratch>/shot --times=0.5,2`
- The game opens maximized. `--window=WxH` forces an exact window size, so check small windows (`--window=1600x900`) as well as large.
- Keep screenshots and other scratch output out of the repo.

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing any game system, you MUST check for a matching `godot-prompter:*` skill and invoke it. This applies to all agents, subagents, and sessions working in this repository.

Key skills here: `scene-organization`, `gdscript-patterns`, `2d-essentials`, `shader-basics`, `tween-animation`, `animation-system`, `godot-ui`, `resource-pattern`, `state-machine`, `audio-system`, `save-load`, `localization`, `godot-testing`.

For the full skill list, invoke `godot-prompter:using-godot-prompter`.
