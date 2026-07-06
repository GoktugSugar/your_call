# Gameplay

## Core loop
1. Narrator presents a dilemma.
2. Player chooses (one of the four verbs below).
3. Animated consequence plays, **scaled to the dilemma's weight** — a quick 2–4s beat for light ones, a full 5–10s+ scene for heavy ones.
4. Display-only stats: "here's how others chose."
5. Narrator reacts; the choice feeds the moral profile (see `narrative.md`).

**No fail state.** The player can't lose or die. Choices only steer which ending is reached.

**The judge never stakes his own life.** Because the protagonist is already dead, no dilemma puts his own survival on the line. He always rules on the fate of other souls. Any dilemma whose original form is about the chooser's own skin (like the viral blue/red button) is reframed so he decides for a soul in the dock, never for himself. Copy that says the judge himself lives or dies is a framing bug.

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
