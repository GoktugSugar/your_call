# Decision log

A dated record of every decision, newest at the bottom. Append an entry whenever a decision is made or changes, and update the doc it touches. Each entry says what was decided, who decided it (the user for creative calls, the dev for technical ones) and why.

## 2026-10-21: the remake starts

- **Engine and language: Godot 4.7, Forward+, GDScript.** User. The editor is the 4.7.2 standard build. GDScript matches the user's other Godot projects and needs no .NET toolchain or build step.
- **The ink look is drawn in code.** User, on the dev's recommendation. Every line on screen, from figures and the imp to doodles and UI frames, is generated at runtime as a hand-drawn ink stroke that boils. Figures are jointed rigs reposed by their joint angles. There is no sprite art pipeline, so nothing waits on drawing. How the strokes are made is in `ARCHITECTURE.md`.
- **Voice acting comes right after the first slice.** User. The slice is built ready for voice: lines are addressable, colour tags are stripped before anything reaches TTS, and the dialogue box can take its typing pace from audio.
- **No Godot MCP server.** User. This supersedes the handoff README's suggestion to set one up again. The dev runs, tests and captures the game through the Godot command line instead.
- **Repository.** Dev. The project folder the user created in the Godot 4.7 project manager became the clone of github.com/GoktugSugar/your_call, on top of its placeholder commit. The Unity backup bundle and the handoff folder sit beside the project but stay out of git (listed in `.git/info/exclude`).
- **The handoff pack became living docs.** Dev. `PREMISE.md` and `SCRIPT.md` moved into `docs/` and now stay in sync with the build. The open questions in PREMISE section 16, and the points sections 9 and 14 leave to the user, moved to `OPEN_QUESTIONS.md`.
- **Git workflow.** Dev, keeping the user's old rules. `main` stays runnable. The project setup went straight onto `main` as the base. Every feature after it goes on a `feat/<short-description>` branch with a pull request, merged once the user signs off at the check-in.
- **Display.** Dev. Base resolution 1920x1080 with stretch mode `canvas_items` and aspect `keep`. The clear colour is the paper colour, so on other aspect ratios the letterbox bars read as more paper. The window opens at 1600x900 during development.
- **Type: Caveat SemiBold.** Dev, keeping PREMISE's default. It is the variable font from Google Fonts set to weight 600, downloaded fresh under the SIL Open Font License, with the licence beside it.
- **Input.** Dev. Everything goes through Input Map actions: `advance` (left click, Space, Enter), `choose_1` to `choose_6` (number keys), `pause` (Esc), plus `dev_restart` (F5) and `dev_overlay` (F3), which only act in development builds.
- **Project layout by feature.** Dev. Folders are `ink/`, `figures/`, `doodles/`, `stages/`, `ui/`, `game/` and `content/`, with `docs/` and `tools/` hidden from Godot. Details are in `ARCHITECTURE.md`.
- **CLAUDE.md carries a GodotPrompter section.** User. Agents, subagents included, must check for a matching `godot-prompter` skill before building a Godot system.

## 2026-10-22: the first slice, 1.02 The Lever

All dev decisions, made while building the slice. The look and pacing numbers are starting points to tune with the user.

- **Content is JSON, one file per chapter.** Lines are plain strings, or objects when they need a speaker or a face. JSON is plain text that diffs cleanly and that the voice tooling can read without a parser of its own. `ContentLoader` reports every malformed or unknown field with its location, and the content tests fail on any problem. The format is in `content/README.md`.
- **Line ids come from where a line sits** (`ch1.lever.pull.1`), so nobody types or maintains them. The voice pipeline will also track each clip by its text, so a copy change marks exactly that clip for regeneration.
- **How the ink is drawn.** Every line is a triangle strip built in GDScript and drawn through `RenderingServer`, with a shader that softens edges from screen-space derivatives. Wobble and boil come from cheap 1D value noise. The whole page boils together on one clock: 5 fps, 3 variants. Static drawings only redraw on the boil; moving ones redraw every frame.
- **Idle motion steps like hand-drawn animation.** Figures breathe in step with the boil, and the imp idles at 12 fps. Big motion, such as the trolley, a fall or a hop, runs at full frame rate.
- **The stick figure rig.** Arms use forward kinematics and legs use two-bone IK to planted feet, all from pose resources that blend and mirror. Death is the shared fold: buckle, collapse, down, then an ink dissolve. There are no strike marks or impact effects.
- **The imp is drawn in code too**, with four faces (grin, smug, glare, surprised). He uses the palette's `imp` tint, the last build's amber, until the open question is settled; one palette change switches him to black ink. He keeps to one wing for a whole question.
- **Stages are data-driven scenes behind one contract.** A question's `stage.type` picks `stages/<type>/<type>_stage.tscn`, and the stage builds itself from the question's data. The trolley stage handles any number of tracks and figures, and the lever stands for the option that leaves the straight track.
- **The loop is one chain of awaits** in `QuestionPlayer`. Each component listens for input only while the loop is waiting on it, so the reaction and the reveal never share a click.
- **UX defaults in place, to confirm at tuning.** A click while text is inking finishes the page. The tableau dissolves before the crowd reveal, so the reveal stands alone. Consequences cannot be skipped. Pages hold up to 3 lines, and text inks on at 42 characters a second with short breaths after punctuation.
- **New input action `pick`** (left click) for pointing at things on the stage and in the choice row, separate from `advance`.
- **Testing with GUT 9.7.1**, the version the user already runs on Godot 4.7, vendored in `addons/gut`.
- **Development tools are debug only.** Autoplay, screenshots, the overlay and F5 restart live in `dev/` and are added by `Main` only in debug builds. `dev/` will be excluded from release exports when the export presets are set up.

## 2026-10-22: first tuning round on the slice

- **Settled from the slice's open questions.** User. The imp stays amber. A click while text is inking finishes the page. The tableau dissolves before the crowd reveal. Consequences always play in full. The souls stand on the rails.
- **The imp is redrawn after the old build's imp.** User, from a picture of the old imp. The clean smiley read wrong, so he is now crude and angular: long thin horns, a lumpy head, sly slanted eyes over a wide grin, a boxy body, floating bent arms, and a crooked tail with a square tip. His line is heavier than the rest of the page.
- **The imp's jitter is soft, never sharp.** User. Random twitching read like an animatronic, so all his idle motion is now eased and continuous. His line melts smoothly from one shape to the next (dev: the brush can blend between boil variants). He drifts on smooth noise, and his fidgets (a shrug, a tail flick, a bounce, a cocked head) ease in and out. The rest of the page keeps its stepped 5 fps boil.
- **Lines are heavier and never too thin on screen.** User reported thin lines in the 1600x900 window. Dev: the base line is 5.2 px (was 4.4), every line keeps at least 3 screen pixels at any window size, and a taper takes at most a fifth of a line, so short marks like the imp's eyes stay bold. The imp's eyes and mouth are drawn heavier still.
- **The game opens maximized.** Dev. The 1600x900 window drew everything at 83 percent. The `--window=WxH` dev switch forces an exact size for checking.
- **Stage tuning.** User. The stick figures are a fifth smaller, the lever sits lower, and the trolley's wheels tuck up under its body.
- **Washes paint in line order.** Dev. Each line's wash goes down just before the line itself, so a drawing lists what is behind first. The trolley's body now hides the tops of its wheels.
- **The imp, second pass.** User. His grin is finer than his eyes, and both arms join his body at the shoulders. His body no longer swells with each breath and barely bobs, and the bounce fidget is gone, because together they read as straining. A lean toward the stage takes the bounce's place among his fidgets.
