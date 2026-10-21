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
