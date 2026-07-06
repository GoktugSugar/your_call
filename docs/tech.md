# Tech, Stats & Build

## Engine & tooling
- Unity, C# (fill in the exact LTS version you install, for example Unity 6 LTS).
- git + GitHub for version control.
- A Unity MCP for Claude Code (confirm one works in your setup before relying on it; the smooth Godot workflow leaned on its MCP, so this matters).

## Stats system
- Display-only (never changes outcomes; the one exception is the coordination gamble, which resolves against a seeded crowd), offline-first, and optional.
- Data: ship with seeded numbers baked in, drawn from real survey data (for example MIT's Moral Machine) for the classic dilemmas where it exists, then blend toward real player responses as they accumulate. The baked-in seed doubles as the offline fallback.
- Backend (deferred): a tiny global tally per choice. Use Supabase or a small serverless endpoint, not Nakama. Do not build this early; seeded data carries the whole prototype with zero backend.

## Data model
Each dilemma is a self-contained `Dilemma` ScriptableObject (a `.asset`, class `Dilemma`) holding: `id`, `verb`, `weight` (`Light` / `Medium` / `Heavy`, which scales the consequence duration), `narratorPrompt`, and a list of `DilemmaChoice`. `DilemmaChoice` is a `[Serializable]` class (or a sub-asset) holding: `id`, `label`, `narratorReact`, `route` (which track the trolley runs, or which group is struck), `diverts` (does the choice throw the lever), `seedVotes` (display-only tally), and `profileImpact`. Unity does not serialise dictionaries by default, so `profileImpact` is a small serializable list of axis and value pairs (the axes in `narrative.md`), recorded silently. The first dilemma is an asset under `Assets/Data/` (for example `Assets/Data/Trolley.asset`).

Shared state (the moral profile) lives in a `Profile` service: a persistent singleton MonoBehaviour (`DontDestroyOnLoad`), or a runtime ScriptableObject if you prefer, holding a silent tally over the axes in `narrative.md`, never drawn during play. Every feel or timing value is a `[SerializeField]` on the relevant component so it can be tuned in the Inspector.

## Verb architecture (resolvers and presenters)
Each dilemma has a `verb`, and each verb maps to two seams so the loop stays generic as verbs accumulate:
- A `VerbResolver` (pure logic, `Scripts/Resolution/`): the player's choice plus the dilemma data (and, for coordination, the seeded crowd) produce a `DilemmaOutcome` (which party ids fold, the narrator reaction to show, and a `ResolutionReport` for the stats). `BinaryResolver` (the trolley) and `CoordinationGambleResolver` are built; `AllocationResolver` and `SelfSacrificeResolver` are stubbed seams. `VerbResolvers.For(verb)` is the only place the verb-to-resolver mapping lives.
- A `ConsequencePresenter` (a MonoBehaviour, `Scripts/Consequence/`): owns the verb's scene apparatus (figures, diegetic input, the animated consequence) and raises `Chosen` for a diegetic pick. `TrolleyConsequence` (track, trolley, lever; the struck group folds on impact) and `CrowdConsequence` (a crowd and the two ink marks; the crowd folds as one when the gamble fails).

`DilemmaStage` holds a resolver (looked up by verb) and a `ConsequencePresenter` reference (assigned per scene) and never branches on verb: it presents, arms the presenter's diegetic input plus an optional text fallback, resolves, plays the consequence, reveals the stats from the report, and records the profile silently. Adding a dilemma is a new asset; a new verb is a new resolver, a new presenter, and one line in `VerbResolvers`, never edits to the loop.

New `DilemmaChoice` fields for resolution: `struckParty` (a party this choice always strikes) and `gambledParty` (a party struck only if a coordination gamble fails), plus `narratorReactStruck` (an outcome-aware reaction). New `Dilemma` fields: `statsHeading`, and for coordination `crowdSafeFraction`, `crowdThreshold`, `thresholdLabel`. `StatsView` is driven by the `ResolutionReport` and draws an optional threshold marker, so a coordination gamble's number reads as load bearing (the line the crowd had to cross) while the trolley's stays reflective. The coordination gamble is rendered in the monochrome ink language, told apart by form, pattern, and label, not colour (`art-and-ui.md`), with amber only on hover, selection, and consequence.

## Scene, prefab & file structure
Composed from small prefabs, one component (MonoBehaviour) each. No monolithic drawing script:
- `Assets/Scenes/Dilemma.unity` with `DilemmaStage` (`Assets/Scripts/Dilemma/DilemmaStage.cs`) as the composition root. Explicit phase state machine (Present, Choose, Consequence, Stats, End); wires input via C# events; drives the consequence; reveals the stats; records the profile. Main scene.
- `Track` prefab (`Track.cs`): the forking track and the single source of truth for layout; exposes query methods for figure positions and the trolley path so nothing else hard-codes geometry.
- `Figure` prefab (`Figure.cs`): a clean single-stroke stick figure with rounded joints and no joint dots that strikes, folds, and fades as one unit. Drawn with a `LineRenderer` for the prototype (the analogue of the earlier Godot `Line2D`) and structured so it can be promoted to a Unity 2D Animation rig (bones and sprite skinning) later, not redrawn.
- `Trolley` prefab (`Trolley.cs`): follows a supplied path with anticipation and a settle on impact; raises an `Impact` event.
- `Lever` prefab (`Lever.cs`): a diegetic amber interactable (Collider2D plus new-Input-System picking); hover intensifies, click raises `Pulled`.
- `NarratorView` (`NarratorView.cs`): the narrator's line as world-space TextMeshPro that inks in (fades while it types on); no panel or box.
- `ChoiceButtons` (`ChoiceButtons.cs`): two plain world-space text choices as the fallback to the lever, picked by click or key.
- `StatsView` (`StatsView.cs`): display-only bars over a dimmed world, the player's pick in amber (minimal UI).
- `Profile` (`Profile.cs`): the persistent profile singleton (`DontDestroyOnLoad`).
- `Dilemma.cs`, `DilemmaChoice.cs` (plus the enums `MoralAxis`, `DilemmaWeight`, `DilemmaVerb` and the serializable `AxisImpact`): the data (ScriptableObject plus serializable classes).
- `OptionMarks` (`Choices/OptionMarks.cs`): the coordination gamble's two ink marks, told apart by form, pattern, and label; amber on hover and selection only. Raises `Chosen`.
- `Resolution/` (`VerbResolver` plus `BinaryResolver`, `CoordinationGambleResolver`, the `Allocation`/`SelfSacrifice` stubs, `VerbResolvers`; and the data `DilemmaContext`, `DilemmaOutcome`, `ResolutionReport`, `StatBar`): the per-verb outcome logic and the stats report.
- `Consequence/` (`ConsequencePresenter` plus `TrolleyConsequence`, `CrowdConsequence`): the per-verb scene apparatus and animated consequence.
- `Common/` helpers, one job each: `InkLine` (builds the shared ink strokes), `LineBoil` (the boil), `EaseUtil` (easing), `PointerInput` (new Input System), `PuffCue` (the impact cue), `InkText` (world TMP labels), `Palette` (the single black / paper / amber source).
- `Assets/Data/Trolley.asset` (Binary) and `Assets/Data/Gamble.asset` (CoordinationGamble): the two dilemmas' data. Each verb has its own scene: `Assets/Scenes/Dilemma.unity` (trolley) and `Assets/Scenes/Gamble.unity`, both in build settings.

Folders under `Assets/`: `Scripts/` (grouped by role: `Scripts/Dilemma/`, `Scripts/Figure/`, `Scripts/Track/`, `Scripts/Trolley/`, `Scripts/Lever/`, `Scripts/Narrator/`, `Scripts/Choices/`, `Scripts/Stats/`, `Scripts/Profile/`, `Scripts/Data/`, `Scripts/Resolution/`, `Scripts/Consequence/`, `Scripts/Common/`), `Prefabs/`, `Scenes/`, `Data/` (ScriptableObjects), `Art/` (the shared ink material), `Settings/`. Commit `.meta` files. One class per file; keep scripts small and single-purpose.

Prototype implementation notes: all ink is one shared `Sprites/Default` material tinted per stroke (rounded caps and corners, vertex-colour alpha so a stroke fades uniformly). The project is configured for the new Input System only, so there is no EventSystem or uGUI; diegetic picking is `Physics2D` against `Collider2D`. Text uses world-space TextMeshPro (essentials imported). Driving play mode headless (for example from an MCP) needs `Application.runInBackground = true`, or the unfocused editor freezes the player loop.

Motion note: for code-driven eased motion (the trolley's anticipation and settle, the fades), use Unity coroutines with easing, the Animation or Animator system, or a tweening library such as DOTween if you add one. Keep the timing values exported so they stay tunable.

## Git workflow
- `main` stays runnable. Feature work on `feat/<short-description>` branches; PR to merge.
- Small, focused commits; imperative messages.
- The Unity `.gitignore` excludes `Library/`, `Temp/`, `Obj/`, `Build(s)/`, `Logs/`, `UserSettings/`, and IDE files, while keeping `.meta` files tracked. Never commit `Library/`, and never gitignore `.meta` files.

## Build plan
1. Native Unity trolley prototype (built, `feat/trolley-prototype`): the one full dilemma loop present → choose → consequence → stats → end, with a diegetic lever plus a text fallback, an animated consequence, seeded local stats, no fail state, and minimal UI. Validates the moment-to-moment feel. (Earlier Godot and JS-first prototypes were set aside; see `decisions.md`. No code was ported.)
2. Verb and production-time test: 3 to 4 dilemmas across different verbs with the real rig. The coordination gamble (`feat/coordination-gamble`) is the first verb of this test, on the resolver plus presenter architecture above. Time one finished dilemma; multiply by 25 to 35 for the true scope reality check.
3. Defer the backend until near real players.
