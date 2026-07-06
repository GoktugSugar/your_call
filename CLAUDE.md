# CLAUDE.md — Project Context & Working Rules

Read this first. The detailed design source of truth lives in `docs/`. Read the relevant doc before implementing or changing anything in that area, and treat `docs/` as authoritative over your own assumptions. If something isn't specified, ask rather than inventing it.

## What this is
A single-player, roughly 5 to 6 hour PC/Steam narrative game of dark comedy and moral philosophy. You play a judge who dies drunk driving; in a cosmic void, a chaotic-trickster narrator puts him through 25 to 35 escalating ethical dilemmas, never letting him forget that the man who judged others is now the one being judged, quietly building a moral profile that pays off in the ending. Black-and-white hand-drawn stick-figure animation. No right answers, no fail state.

Working title: Your Call. Full pitch: `docs/vision.md`.

## Design pillars (hard constraints, do not violate)
1. No "right" answer. Dilemmas are genuine dilemmas. The game never scores the player as good or bad and never implies a correct choice.
2. No good/bad moral axis. The moral profile tracks what kind of reasoner the player is (the one vs. the many, mercy vs. justice, ends vs. rules, order vs. freedom), never a virtue score. See `docs/narrative.md`.
3. No fail state. The player is already dead; they can't lose or die. Choices only steer which ending is reached.
4. Minimal UI. Clear and simple: no large HUD, no big menus, no pop-ups, minimal on-screen detail. The void and the figures carry the screen; UI recedes. See `docs/art-and-ui.md`.
5. Themes, not named politics. Draw from real current tensions (AI and jobs, surveillance, rationing) but abstract one step. Never name real parties, politicians, or dated events.
6. Reposable rigs, not bespoke frames. All characters are stick figures on reusable 2D skeletal rigs (Unity's 2D Animation); one rig reposed into many scenes. This is what keeps scope achievable.
7. Scope discipline on verbs. Launch has exactly four verbs (binary, allocation, coordination gamble, self-sacrifice). New verbs are post-launch, not launch scope.
8. Stats are display-only, offline-first, optional. Never let stats gate progress or require a connection. (Only the coordination gamble resolves against a seeded crowd.)
9. Text-first. Ship text; voice acting is a later upgrade. Don't build around VO.

## Tech stack
- Engine: Unity, C# (fill in the exact LTS version you install, for example Unity 6 LTS).
- Version control: git + GitHub.
- Unity MCP: a Unity MCP for Claude Code drives the engine; prefer it for engine operations (confirm one works in your setup).
- Stats backend (later): a tiny global tally (Supabase or a small serverless endpoint). Not Nakama. Deferred until near real players.

## Engine conventions (Unity, follow for all code)
- Expose tunables in the Inspector: any value a designer might tweak (durations, speeds, delays, offsets, thresholds, weights, placeholder text) is a `[SerializeField]` with a sensible default. No magic numbers buried in scripts.
- Compose with prefabs: build reusable visual elements as their own prefabs with one component each, and instance them. No monolithic drawing script. (Figure, Trolley, Track, Lever, StatsView are separate prefabs; DilemmaStage is the scene root.)
- Decouple with events: components communicate via C# events (or UnityEvents for Inspector wiring), not by reaching across the hierarchy with hard references.
- Data-driven core: dilemmas are ScriptableObjects; shared state is a persistent singleton (or runtime ScriptableObject). New content means new assets and prefabs, not new loop code.
- Files live under `Assets/` in `Scripts/`, `Prefabs/`, `Scenes/`, `Data/`, `Art/`, `Settings/`. Commit `.meta` files. Keep scripts small and single-purpose; prefer composition.
- The figure is built for Unity's 2D Animation (bones and sprite skinning) so it can be reposed, not redrawn.

### Code organisation (never lump everything into one script)
- One script, one job. Each script has a single clear responsibility. If a script is handling drawing, input, and state at once, split it into separate scripts.
- No god scripts. Do not build a single large manager that owns everything. Behaviour lives in the component that owns it; coordination runs through events and the `DilemmaStage` state machine, not a mega-class.
- Separate the concerns: data (ScriptableObjects), persistent state (the `Profile` singleton), presentation and animation (small per-element components on prefabs), input (the interactable component or a dedicated handler), and flow (the `DilemmaStage` state machine) are distinct pieces, never merged into one.
- One class per file, named after the class. Keep files small; if a script grows past roughly a screen or two, treat that as a signal to extract or split it.
- Group scripts by role under `Assets/Scripts/` (for example `Scripts/Dilemma/`, `Scripts/Figure/`, `Scripts/Stats/`, `Scripts/Data/`), not one flat folder of everything.
- Composition over inheritance: prefer small components combined over deep class hierarchies. Prefer private `[SerializeField]` fields over public ones, and keep `Update()` lean with small, focused methods.

## Commands
- Open/run: open the project in Unity Hub, press Play in the Editor.
- Test: Unity Test Framework via the Test Runner (once wired).
- Build: Editor Build Settings, or `-batchmode` from the CLI for CI (once configured).

## Git workflow
- `main` stays runnable. Feature work on `feat/<short-description>` branches; PR to merge.
- Small, focused commits; imperative messages (for example "add dilemma ScriptableObject").
- Never commit Unity's `Library/` (see `.gitignore`). Keep `.meta` files tracked.

## Keeping docs in sync (important)
`docs/` is the project's source of truth, so it must not drift from reality:
- When a design decision changes, update the relevant `docs/*.md` file and append a dated entry to `docs/decisions.md`, in the same change or commit. Never change behaviour without updating the docs, and never leave a changed decision unlogged.
- When something is undecided, add it to `docs/open-questions.md` rather than guessing.
- Keep this file lean and high-signal; put detail in `docs/`, not here.

## Don'ts (easy to get wrong)
- Don't add a good or evil meter, morality score, or "correct answer" feedback.
- Don't add large HUDs, cluttered menus, or pop-up dialogs.
- Don't name real politicians, parties, or current events in dilemmas.
- Don't build the stats backend early, or make stats required.
- Don't create per-dilemma bespoke character art; repose the shared rigs.
- Don't add new interaction verbs for launch.
- Don't commit `Library/`; don't gitignore `.meta` files.
