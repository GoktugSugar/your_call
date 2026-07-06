# Decision Log

Append a dated entry whenever a design decision is made or changed. Newest at top. Keep entries short: what was decided, and (if it changed something) what it replaced and why.

Format: `YYYY-MM-DD — <area>: <decision>. (Was: <old> — <reason>.)`

---

## 2026-07-06 — Coordination gamble becomes the literal blue/red button (feat/blue-red-button)
- Replaced the invented "hold the line / roll the dice" framing (a die and a circle) with the actual viral blue/red button dilemma, reframed only for the dead protagonist. The narrator states the rule plainly: press blue and you live; press red and you live only if more than half the room presses blue. The player, a judge who cannot die, casts for one soul in his charge, not for himself and not for the whole room.
- Mechanic fix (the important one): there is no option that saves the whole room for free. Blue protects only the player's charge; red gambles that one charge on the room. That is what gives the gamble its pull. Previously "safe" spared the entire crowd, which carried no tension. The seeded-crowd resolution is unchanged (blue-fraction 0.43 against a 0.50 threshold, both [SerializeField]); at the seed red loses and only the charge folds, while the room, the aggregate that decided it, stays standing.
- Kept on palette (white, black, one amber): the two options are two clean ink buttons told apart by label alone, and the narrator names them the blue and the red button, so the reference is unmistakable while nothing on screen is blue or red. Amber still appears only on hover, selection, and consequence.
- Resolved the earlier open question about which value the amber highlights on the stats screen: the amber marks the player's pick. The blue/red framing settles it, because pressing red and joining the red majority (57 over the 50 half line) is exactly why blue fell short (43 under it) and the charge died. The pick and the cause are the same bar, so amber on the pick reads true. The seeded blue-fraction still inks in against the threshold line as the load-bearing number.
- Architecture reused, not extended: same `CoordinationGambleResolver` and `ConsequencePresenter`, no new verb branches in `DilemmaStage`. Renamed the concrete presenter `CrowdConsequence` to `RoomConsequence` (a room plus a distinguished charge; folds only the charge) and the choice widget `OptionMarks` to `ButtonChoice` (two ink buttons). The only resolution change is data: the red choice's gambled party is now the single `charge`.
- Content and scene renamed for clarity: `Assets/Data/Gamble.asset` to `Assets/Data/BlueRedButton.asset`, `Assets/Scenes/Gamble.unity` to `Assets/Scenes/BlueRedButton.unity` (both scenes in build settings). Profile unchanged and silent: blue leans order and control, red leans freedom and trust in the many. Trolley confirmed unchanged (both outcomes still fold).

## 2026-07-06 — Coordination gamble verb prototype (feat/coordination-gamble)
- Built the second launch verb, the coordination gamble, as a new dilemma reusing the loop (present, choose, consequence, stats, end). The outcome depends on a seeded crowd aggregate, not the player's choice alone: playing safe spares the crowd; gambling spares them only if the crowd's safe fraction reaches a threshold. Seeded safe fraction 0.43 against a 0.50 threshold (both [SerializeField] on the `Dilemma`), so at the seed the gamble fails and the crowd folds, the dramatic case to see. Raising the fraction above the threshold spares the gamble; both outcomes verified in play.
- Reframed the red/blue button into the monochrome ink language, forced by the one-amber palette (`art-and-ui.md`): the two options are told apart by form, pattern, and label, never by colour. A closed circle with a check is "hold the line" (safe); a die with pips is "roll the dice" (the gamble). Amber appears only on hover, selection, and consequence; the narrator carries the meaning. This settles the open red-vs-accent collision for this verb without spending the accent on it.
- Per-verb resolver architecture so `DilemmaStage` stays generic as verbs accumulate. Each verb has a `VerbResolver` (`BinaryResolver`, `CoordinationGambleResolver`; `Allocation` and `SelfSacrifice` are stubbed seams) that turns the choice plus the seeded crowd into a `DilemmaOutcome` (which parties fold, the narrator reaction, and a `ResolutionReport` for the stats). A per-verb `ConsequencePresenter` (`TrolleyConsequence`, `CrowdConsequence`) owns the scene apparatus and the animated consequence. `DilemmaStage` now only resolves, plays, reveals, and records, with no verb branches. The trolley was refactored onto the Binary resolver plus `TrolleyConsequence` with no behaviour change (both outcomes re-verified: divert folds the one, do nothing folds the five).
- The stat is load bearing here, not reflective. `StatsView` is now driven by a `ResolutionReport` and draws an optional threshold marker (the line the crowd had to cross), so the seeded fraction inks in as the number that decided the outcome. The trolley keeps its reflective "how others chose" bar.
- Profile impacts (first pass, silent, tunable): hold the line leans order and control (OrderVsFreedom toward order); roll the dice leans freedom and trust in the many (OrderVsFreedom toward freedom, OneVsMany toward the many). Recorded silently and never drawn; verified.
- Fold-in fix: raised `NarratorView`'s default typing speed so the opening line lands a touch quicker (it was about five seconds). The instruction read "lower the typing speed"; I took the intent to be a faster read, so raised chars-per-second. One tunable value if that was the wrong reading.
- Runnable: a second scene, `Assets/Scenes/Gamble.unity`, with `Gamble.asset` assigned; both scenes are in build settings.

## 2026-07-06 — Native Unity trolley prototype built (feat/trolley-prototype)
- Built the first playable prototype fresh in Unity 6 (6000.3.10f1, URP): the full trolley loop present → choose → consequence → stats → end. No fail state; minimal UI; white paper ground, black ink, one amber accent used only for the lever (attention) and the player's own pick on the stats screen (consequence). No dashes in any player-facing text. The moral profile is recorded silently to the `Profile` singleton and never drawn (verified in play: pulling the lever records OneVsMany +1, EndsVsRules −1).
- Rendering is `LineRenderer` ink (one shared `Sprites/Default` material, rounded caps and corners, vertex-colour alpha for uniform fades) plus world-space TextMeshPro, the Unity analogue of the earlier Godot `Line2D` doodle. A subtle line boil (`LineBoil`) cycles jittered copies; a faint paper tint sits on the camera background. The `Figure` is one continuous stroke with rounded joints and no joint dots that folds and fades as a single unit; it is structured to be promoted to a Unity 2D Animation rig later (not yet rigged).
- Input is the new Input System only: pointer and keyboard go through `UnityEngine.InputSystem`, and diegetic picking (the lever, the fallback text choices) uses `Physics2D` against `Collider2D`, so there is no EventSystem or uGUI. The lever is diegetic (hover intensifies the amber, click throws it and raises `Pulled`); two plain world-space text choices are the fallback.
- Scene and prefabs: `Assets/Scenes/Dilemma.unity` with `DilemmaStage` as the composition root (explicit phase state machine; wires input via C# events; drives the consequence; reveals the stats; records the profile). One component per prefab: `Figure`, `Track` (the single source of truth for layout, exposing figure positions and the trolley path), `Trolley` (anticipation and settle, raises `Impact`), `Lever` (raises `Pulled`). Plus `NarratorView`, `ChoiceButtons`, `StatsView`, the persistent `Profile`, and small `Common` helpers (`InkLine`, `LineBoil`, `EaseUtil`, `PointerInput`, `PuffCue`, `InkText`, `Palette`). Scripts grouped by role under `Assets/Scripts/`. Content is a `Dilemma` ScriptableObject at `Assets/Data/Trolley.asset` (seeded 87 pull / 13 do nothing, silent profile impacts).
- The characterful narrator typeface, full paper texture, and ink-draw-on transitions remain the documented fast follow (`art-and-ui.md`).

## 2026-07-06 — Code organisation rules made explicit
- Tightened the engineering conventions in `CLAUDE.md` (and `tech.md`) to prevent monolithic scripts: one script one job, no god or manager class, separated concerns (data, persistent state, presentation, input, flow), one class per file, scripts grouped by role under `Assets/Scripts/`, composition over inheritance. No design change; a coding-discipline clarification.

## 2026-07-06 — Art direction refined: minimal but stylised
- Minimalism governs the number of on-screen elements (spare, uncluttered); stylisation governs the character of each element. The game should read as minimal but never sterile or plain.
- Style lives in four levers that add no clutter: a living hand-drawn ink line (with a subtle boil), a faint paper texture on the white ground, characterful narrator typography that inks in, and expressive ink-like motion. Detailed in `art-and-ui.md`.
- Unchanged: minimal UI (no HUD, menus, or pop-ups), monochrome plus one amber accent. Stylisation never means more UI or more colour.

## 2026-07-06 — Switched engine to Unity (no code ported)
- **Engine switch:** moved development from Godot 4.6 to Unity (C#). Reason: personal preference for Unity. The design is engine-neutral and does not change.
- **No code ported.** The Godot trolley prototype (and the earlier JS spike) are set aside; the Unity trolley prototype will be built fresh. This was a deliberate choice, not a limitation.
- **Convention mapping (Godot to Unity):** scenes become prefabs and scenes; GDScript becomes C#; `.tres` Resources become ScriptableObjects; autoload becomes a persistent singleton (or runtime ScriptableObject); signals become C# events (or UnityEvents); `@export` becomes `[SerializeField]`; the Skeleton2D rig becomes a Unity 2D Animation rig; the Godot MCP becomes a Unity MCP (confirm one works in the setup).
- **Repo:** same GitHub repo reused. Godot scaffold removed, Unity `.gitignore` added (keeps `.meta` files, ignores `Library/`), history preserved. See `tech.md` for the Unity file map.
- **Docs updated in this switch:** `tech.md` rewritten for Unity; `CLAUDE.md` updated (engine, conventions, commands); `art-and-ui.md` and `open-questions.md` had single engine references updated. Design docs (`vision.md`, `gameplay.md`, `narrative.md`) unchanged.

## 2026-07-06 — JS-first workflow rejected; native Godot trolley rebuilt
- **Workflow:** evaluated writing dilemmas in **JavaScript first, then porting** to Godot (spike on `exp/js-port-test`). **Rejected.** Only the data, config, and phase state machine port (about a quarter of the code, the cheap part); all rendering, animation, and moment-to-moment feel must be built natively and are discarded in a JS pass. Decision: build dilemmas **directly in Godot.** Browser builds are reserved **only for later** playtesting of narrator copy and the stats screen (the content layer that does port), never for the core loop.
- **First dilemma rebuilt natively** (`feat/trolley-v2`) as the grey-box prototype: full loop present → choose → consequence → stats → end. No fail state, minimal UI, one amber accent used only for attention (the lever) and consequence (the struck figure; the player's own pick on the stats screen). Profile recorded **silently** to the `Profile` autoload and never drawn. Seeded 87/13 display-only stats.
- **Scene structure:** composed from instanced scenes — `Figure`, `Trolley`, `Track`, `Lever`, and `DilemmaStage` (the loop + explicit state machine) — plus a `StatsView`. Each dilemma is a `Dilemma` **Resource** (`.tres`) of `DilemmaChoice` sub-resources; shared state in the `Profile` autoload; every tunable an `@export`. See `tech.md` for the file map.
- **Figure** is a rounded-`Line2D` silhouette with no joint dots, built as a bone-like hierarchy so it can be promoted to a Skeleton2D rig later; it folds and fades as a single unit.

## 2026-07-06 — Working title, protagonist, first dilemma, engine version
- **Working title:** *Your Call* (spoken straight to the player — the decision is the whole game). Provisional; earlier drafts considered *Track Record* and others.
- **Protagonist:** the blank-slate player character is a **judge who died drunk driving** — a fixed backstory (he judged others; now he's judged; likely sentenced DUIs himself) over a still-blank *moral present* filled by the player's choices. Refines the earlier pure "blank slate."
- **He killed only himself** in the crash — no bystander. (The "did he kill someone else" thread was dropped to keep focus on the dilemmas, not a backstory investigation.)
- **First dilemma:** the clean classic **trolley problem** (five on the main track, one on a branch, a lever). Grey-box prototype content; mirrors the protagonist's own death.
- **Engine:** Godot **4.6**. (Superseded 2026-07-06 by the switch to Unity above.)
- **Still open:** death reveal timing (cold open vs. gradual) — see `open-questions.md`.

## 2026-07-06 — Founding decisions (from initial design Q&A)
- **Platform / scope:** PC / Steam first; ~5–6 hours; linear campaign; ~25–35 dilemmas, each a full scene (~10 min).
- **Narrator:** recurring chaotic trickster who secretly tracks the player.
- **Protagonist:** blank slate; only fixed fact is how he died.
- **Ending:** reflects a moral profile (what *kind* of reasoner, not good/bad).
- **Verbs (launch):** binary, allocation, coordination gamble, self-sacrifice.
- **Coordination gamble reframed:** crowd decides *other souls'* fates (player can't die); resolved vs. a seeded crowd. (Was: classic self-preservation blue/red — doesn't fit a dead protagonist.)
- **Stats:** display-only, offline-first, optional; seeded (from real survey data) → real players.
- **Sourcing:** mix of real philosophy + original; topical *themes* abstracted one step (no named politics).
- **Escalation:** waves (difficulty + personal implication + narrator intimacy), with breathers.
- **Art:** B&W stick figures on reposable rigs; one meaningful accent colour.
- **UI:** minimal — no large HUD, no big menus, no pop-ups, minimal detail. Profile is not shown as a running gauge.
- **Audio:** text-first; VO later.
- **No fail state.**
- **Rejected:** selfish↔selfless profile axis (smuggles a "right answer").
- **Tooling:** Godot 4.6; git + GitHub; Godot MCP. Stats backend later via Supabase / serverless (not Nakama). (Engine superseded by the Unity switch above.)
