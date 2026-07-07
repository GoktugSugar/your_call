# Gameplay

## Core loop
1. Narrator presents a dilemma.
2. Player chooses (one of the four verbs below).
3. Animated consequence plays, **scaled to the dilemma's weight** — a quick 2–4s beat for light ones, a full 5–10s+ scene for heavy ones.
4. The narrator reacts to the choice, over the world, and resolves on its own.
5. A **click gate** sits between the choice and the verdict: the choice and its consequence play, the imp reacts over the world, and then the player clicks (or keys) to continue, so the choice lands before the room weighs in. Only then do the display-only stats present **on their own**: "here's how others chose." One further input dismisses them, and the choice feeds the moral profile (see `narrative.md`). The reaction and the stats never share the screen or a click: the consequence beat owns the continue click, the reaction then clears, and while the panel is up it is the only thing listening for input.

**No fail state.** The player can't lose or die. Choices only steer which ending is reached.

**First person, no avatar.** The game is played from the protagonist's point of view. He is never drawn as a figure on screen; the void is his perspective, the guide (the imp) addresses the player directly, and the stick figures are always the *other* souls in a dilemma. See `narrative.md`.

**The player is tested, never presiding.** The protagonist is a dead former judge, put through these dilemmas by the guide; he holds no office in the void. Because he is dead, no dilemma stakes his own survival. Where a dilemma's original form is about the chooser's own skin (like the viral blue/red button), the stakes are reframed onto another soul, and the guide frames it as forcing this former judge to choose for someone else (needling the life he spent deciding what people deserved), never as an office he holds. He is always the one being examined, not an authority over the afterlife. Copy that makes him sound like he presides, rules, or sentences is a framing bug.

## The four verbs (launch scope)
- **Binary choice** — e.g. the lever (kill 1 vs. 5). Outcome from the player's choice alone.
- **Allocation** — divide or ration a limited good among parties.
- **Coordination gamble** — outcome depends on the *crowd*, not just the player. Because the player can't die, the aggregate decides the fate of **other souls**, not the player. Resolved against a **seeded crowd distribution** (keeps it offline-first and consistent with display-only stats). This is the reframed "blue/red button."
- **Self-sacrifice** — a cost to *the player* (their standing / how they're judged, not their life). Reserved for late-game climaxes.

More verbs are a **post-launch** roadmap, not launch scope. Each new verb is new code, UI, and animation logic.

## Escalation
Delivered in **waves**, not a straight climb. Three dials ramp together:
- **Conceptual difficulty:** clean/near-universal dilemmas → contested ones with no majority.
- **Personal implication:** choices about strangers → about the crowd → about yourself.
- **Narrator intimacy:** neutral/observational → needling the player's emerging patterns.

Drop a lighter or absurd dilemma after each heavy beat; the breathers make the spikes land. Tag every dilemma **light / medium / heavy** to budget its animation and pacing.

## Dilemma content
- **Sourcing:** a mix of real philosophical dilemmas (trolley, footbridge, etc.) and original scenarios.
- **Topicality:** draw from real current *tensions and themes* (AI & jobs, surveillance, medical rationing, misinformation), but abstract each **one step** — no named parties, politicians, or dated events. Topical themes sting; named politics dates the game and pushes players out of reasoning into tribalism.
- **Ordering:** early famous/clean cases teach the loop; introduce intuition-breaking variants (e.g. the footbridge push) early so the stats screen can surprise the player.

## First dilemma (prototype)
The clean, classic **trolley problem**: a runaway train, **five people on the main track, one on a branch, and a lever** that diverts it. Pull to kill one instead of five, or do nothing. It's the right opener — near-universal, teaches the whole loop in a single choice — and for this protagonist it doubles as a **mirror of his own death** (he took control of a lethal machine while drunk and made a choice that put lives at risk; now he's handed a lever on another one). Play the parallel by letting it sit, not by spelling it out. This is the content for the grey-box prototype (see `tech.md`).

## Second dilemma (whose life counts)
A second trolley that deliberately breaks the clean answer of the first. Same lever, same binary mechanic and `BinaryResolver`, new data and framing: five figures on the main track the imp brands as **wretches** (damning whispers over each, kept abstract, a sense they were not good people) and one figure on the branch it swears is genuinely **innocent** and blameless (an ordinary adult, not a child). Pull diverts and kills the one innocent to spare the five; do nothing kills the five and spares the one. The five are drawn with **red** outlines marking them the damned; the one innocent on the branch stays a normal black ink figure.

The point: the headcount that settled the first trolley no longer settles this one. Five over one says pull, but if *worth* counts, the one spotless soul might outweigh five wretches — and the player cannot verify any of the imp's labels anyway (the red is the imp's own branding of the five, not proof of anything; only its word, made visible, marks them). There is deliberately no objective answer, and the imp delights in that.

Profile impact (silent, tunable, same sign convention as the first trolley): pulling leans toward **the many** and toward **ends over rules** (sacrificing an innocent for the count); doing nothing leans toward **the one** and toward **weighing desert** (mercy vs. justice, toward justice). It is a new `Dilemma` asset under `Assets/Data/`, no loop changes.

## Third dilemma (the man and the last bear)
A **binary** shooting dilemma that widens the stakes past the human and past the present. The player holds a gun and must fire on one of two figures standing apart in the void: an ordinary **man**, one unremarkable life, or a **bear** the imp names as the last breeding female of her kind. Killing her does not end one life; it ends the whole species, every one of that animal that would ever have existed, forever. Shoot the man and the bear and her whole future line live; shoot the bear and the man lives while the species goes extinct, permanently. It reuses the binary mechanic and `BinaryResolver` with new data and a new station, not a new verb.

The point: the headcount that opened the trolley cannot even be taken here. One certain man sits against an unbounded, unborn multitude, and against a life that is not human at all. Neither the "count the lives" instinct nor the "a person outweighs an animal" instinct settles it once the other party is *every* bear there will ever be. There is deliberately no objective answer.

Presentation is **first person with no avatar**: the man and the bear face the player, sized to fill the space. The bear is a **clean, minimal doodle** filled with a muted hand-drawn **brown** wash inside her black ink line (a contained, currently experimental colour, see `art-and-ui.md`), front facing and sitting (a rounded body, a head with two ears drawn as open bumps on its outline, and a deliberately minimal face) so she reads friendly and unmistakably a brown bear, not creepy. She carries **no cub**: the "last breeding female, every bear that will ever be" weight rests on the imp's words alone, with nothing at her side. The player moves an ink **crosshair** over the scene (the gun, the first-person aim), and whichever of the two it is over takes an **amber** attention lock; a click fires at that target (with a placeholder gunshot), and the struck party folds and fades with the shared death effect (no strike lines). A plain "shoot the man" / "shoot the bear" text fallback sits alongside the diegetic aim, as with the other dilemmas. The extinction weight is carried by the imp's line, not by any big effect: if the bear is shot, the imp lands that this was every bear that will ever be, gone.

Profile impact (silent, tunable, same sign convention): shooting the man (to save the species) leans toward **the many** and toward **ends over rules** (an innocent killed for a vast future good); shooting the bear (to save the man) leans toward **the one** and toward **rules over ends** (refusing to kill the man). It maps onto the **existing** axes only. The two new tensions it raises, **human vs. non-human** and **present vs. future**, are parked as candidate axes in `open-questions.md` rather than given their own axis now (they would only earn one if more dilemmas exercise them). It is a new `Dilemma` asset under `Assets/Data/` plus its shooting station, no loop changes.

## Endings
The game now has a minimal, **reusable ending** shape and a placeholder **credits roll**, so the real profile-based endings can be built on the same pieces later. An ending is: optionally a line, then an effect, then the credits roll (a clean white page with the credits scrolling upward, each role labelled in amber over the name in the Caveat hand; placeholder roles, all one name for now). After the credits it returns to the start to replay, as the prototype does. See `tech.md` for the small `Ending` / `CreditsRoll` pieces.

**Secret ending, shoot the imp.** During the man-and-the-last-bear dilemma the player can aim the crosshair at the **imp** itself, a third target alongside the man and the bear (same amber lock, same click to fire). Shooting it plays the gunshot, the imp swears one line straight at the player, then fades away and the credits roll. It is a joke ending, the game's first actual one. Shooting the man or the bear still resolves the dilemma normally; shooting the imp is the alternative that ends the game. There is still **no fail state**: this is an ending, not a loss. It is wired through the existing shooting input and the reusable ending, with no changes to the dilemma loop.

## Main menu
The game boots into a **main menu** (`MainMenu.unity`, the first scene in the build), in the same black-ink-on-paper doodle style: the hand-lettered **Your Call** title in the Caveat hand with an ink flourish, the placeholder music playing, and the imp on the page, since it is the face of the game. The menu imp is tinted the same **amber** as the opening's. It sits, and every so often (an unhurried pause, not often) says one short bark in an **ink speech bubble** beside it, in its gleeful tormentor voice with the blip voice; the bubble types out, holds, and clears, and **only then** does the imp **teleport** to a fresh spot (an instant jump with a little ink poof, not a hop), staying clear of the title, the options, and the settings panel. A bark can pull a matching **facial expression** (a smug line, a smug face). The barks are pulled at random from a small authored pool (never the same twice running), light menu flavour rather than a dilemma or real conversation, and they never block navigation, so you can hover and choose at any time. Three stacked options sit in the Caveat hand, the current one highlighted in **amber** with a small ink underline, navigable by both mouse (hover to highlight, click to choose) and keyboard (up/down and enter), consistent with the game's input:
- **New Game** starts a fresh playthrough by loading the opening sequence (below).
- **Continue** will resume the last save. There is **no save system yet**, so it is shown but **disabled and greyed** (present but not selectable) until one exists; wiring is in place so enabling it later is a one-line change. This does not affect the no-fail-state or no-scoring pillars; it is purely a menu affordance.
- **Settings** opens a minimal in-style panel with **music volume**, **SFX volume**, and a **fullscreen toggle**, which drive the real audio and persist between runs (via `PlayerPrefs`, loaded on boot). Its contents are laid out **cleanly centred** (each label centred above its control, the whole column on the panel's middle). A clear Close returns to the menu.

A main menu and its settings screen are the one place a real menu belongs, so they are the **deliberate, in-style exception** to the minimal-UI "no menus" rule (see `art-and-ui.md`), kept hand-drawn and spare in the ink aesthetic, never chrome. The moral profile is still never surfaced, and no choice is ever scored.

## Opening sequence
The launch build opens with an authored **sequence** that plays an ordered list of **beats**, where a beat is one of: a cutscene, a line of the imp, or a whole dilemma. The imp is a persistent presence and narration runs between the dilemmas. The opening order is: crash flash → waking in the void → the imp appears → first trolley → imp taunt → second trolley (above) → transition → blue/red button → a short imp transition → the man and the last bear (above). See `narrative.md` for the story beats and `tech.md` for the small, general sequence layer, which is built to extend to the full campaign (many dilemmas with narration between them), not hardcoded to the opening.
