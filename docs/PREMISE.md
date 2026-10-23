# Your Call: Premise and Design Intent

This is the carried-over design for **Your Call**, written for the Claude remaking it from scratch in Godot 4.7, and for the user. It comes from an earlier Unity build, and is rewritten here so it doesn't depend on any engine.

> **A living document.** It arrived in the handoff pack on 2026-10-21 and now stays in sync with the remake. When a decision changes something here, the change is logged in `DECISIONS.md`. Open questions live in `OPEN_QUESTIONS.md`.

**How to read it.** Nothing here is binding spec. There are three kinds of content:
- **Section 2, Firm pillars:** the creative pillars the user held across the whole earlier project. Change them only with the user's explicit say-so.
- **Section 3, What changed:** what is different for the remake.
- **Open questions** (`OPEN_QUESTIONS.md`, formerly section 16): things never settled. Decide them with the user rather than guessing.

Everything else describes how the earlier build did things and why. Treat it as a strong default that you can keep, change or drop with the user.

The full question script lives in `SCRIPT.md`: every question in play order, its options, the imp's lines, the crowd seeds and the profile nudges. This file does not repeat it.

---

## 1. Logline and concept

**Logline.** You die. In a formless afterlife, a chaotic trickster runs you through his game of questions with no right answer, and quietly builds a portrait of who you really are.

- **The format.** A single-player narrative dark comedy for PC and Steam: one linear run of about 5 to 6 hours.
- **The player character is a judge** who spent his career deciding what other people deserved.
  - He died drunk driving, killing only himself, so there is no victim and nothing to investigate.
  - That past is fixed. His present is blank, and the player's choices fill it in.
- **The irony is the auditor audited.**
  - Now he is the one being sized up, and the imp keeps returning to his rulings and his hypocrisy.
  - The ending can compare the man he was on the bench with the person these choices reveal.
- **He never presides.** In the void he holds no office.
  - When he chooses for other souls, the imp is forcing a former judge to choose for someone else.
  - Copy that makes him sound like he rules or sentences is a framing bug.
  - Chapter 7 deliberately twists this: the imp makes him do the old job again, as a torment rather than an office.
- **First person, no avatar.** The void is his point of view.
  - He is never drawn, and the imp talks straight to the player.
  - Every stick figure on screen is another soul, an androgynous stand-in.
- **The void.** A cosmic, abstract nowhere with almost no background art, so all the attention lands on the figures.
- **The imp's game.** A small hand-drawn devil runs him through a long, ordered stream of questions with no right answer, from silly would-you-rathers to gut-punch dilemmas.
  - The imp is not judging his morality. He is figuring out who he is: the whole person.
  - Every question ends on "how others chose".
  - Quietly, the imp builds a portrait that picks which of several endings the player reaches.
- **The death is shown early and lightly.** A quick ink flash of the crash opens the game, then he wakes in the void. Showing it up front keeps it a passing gag, not a mystery.
- **Tone.** Funny with real bite, paced in waves.
  - The heavy dilemmas supply the sting.
  - Fourth-wall winks are allowed, but the fiction never fully breaks.
  - It never punches down: aim the comedy at hypocrisy, never at the tragedy of a death.
- **Positioning.** Trolley-problem games with "how others voted" already exist (Trolley Problem Inc., Dr. Trolley's Problem), but they are mostly text question generators with no arc. This game's edge:
  - an animated ink consequence for every question
  - a narrator who tracks the player
  - real endings that depend on the profile
  - question types beyond A/B

---

## 2. Firm creative pillars

The user held these across the whole earlier project. Treat them as hard constraints unless the user says otherwise.

1. **No right answer.**
   - Every question is a genuine one with no correct choice, and it must either divide people or reveal something about the person answering.
   - Questions with an obvious consensus answer are cut, because a lopsided crowd split makes a dead reveal.
   - Every question type is in scope.
   - The game never scores the player as good or bad, and never implies a correct choice.
2. **A portrait, not a verdict.** The silent profile describes which way the player leans on characterful axes where neither pole is the good one. There is never a virtue score, a good or evil meter, or "correct answer" feedback.
3. **No fail state.**
   - He is already dead, so he cannot lose or die again. Choices only steer which ending he reaches.
   - The secret endings are endings, not losses.
4. **Minimal UI.**
   - No large HUD, no big menus, no pop-ups, and minimal on-screen detail. The void and the figures carry the screen, and the UI recedes.
   - The main menu, settings and pause screen are the one sanctioned exception, kept in style (section 13).
5. **Themes, not named politics.**
   - Draw from real current tensions (AI and jobs, surveillance, rationing, misinformation), but abstract each one by one step.
   - Never name real parties, politicians or dated events.
6. **Reusable figures, not bespoke frames.**
   - All characters are stick figures on a small set of reusable rigs, reposed into many scenes.
   - This is what keeps a 5 to 6 hour animated game in scope. Drawing new art for a question is the exception, never the default.
7. **Scope discipline on verbs.**
   - The launch verbs are binary and multiple-choice for the everyday volume, and allocation, coordination gamble and self-sacrifice for the heavy spikes.
   - Any further verbs are post-launch.
   - Most of the earlier build's variety came from different presentations of binary and multiple-choice (section 5).
8. **The crowd reveal is the central hook, and stats are display-only, offline-first and optional.**
   - Every question ends on "how others chose".
   - Stats never gate progress and never require a connection.
   - Only the coordination gamble resolves against a seeded crowd.
9. **Ink on paper.**
   - Black hand-drawn line on a white paper ground. Colour is a deliberate accent for emphasis and meaning, never blanket decoration.
   - There is no hard limit on which colours. The discipline is that colour stays purposeful and the world reads as a sketchbook page, not a full-colour scene.
10. **Dark comedy, not PG.** The imp swears where the tone fits: strong language used deliberately, not gratuitously.

---

## 3. What changed for the remake

- **The engine is now Godot 4.7.**
  - For context: the very first prototype was in Godot 4.6. The project then moved to Unity out of personal preference, and now it returns to Godot.
  - Nothing from either earlier codebase carries over.
  - How to build it in Godot is the new chat's call, made with the user: scene structure, data format, and how figures are rigged and drawn.
- **Voice acting is now in scope.**
  - The user has an ElevenLabs subscription. This replaces the old pillar "text-first: ship text, voice acting is a later upgrade, don't build around VO".
  - The old reason for deferring VO was that recorded voice freezes the script. That mostly falls away with TTS, because a line can be regenerated when its copy changes, so the pipeline should make regenerating cheap.
  - See section 14.
- **"Reposable rigs" is now an intent, not a specific technology.**
  - The earlier build drew its figures natively as living ink strokes on a jointed rig (neck, shoulders, elbows, hips, knees, feet on a ground line). It never used imported sprites, so the line kept its hand-drawn boil while the figures posed by their joints.
  - How the remake gets there is open. The intent is a small set of reusable figures, reposed rather than redrawn, that keep a living hand-drawn line.
- **No code, assets or tech conventions carry over.** That means no scenes, scripts, art, audio, fonts, style-guide PDF, design mockups or Unity-specific architecture. Only this pack carries over: `README.md`, this file and `SCRIPT.md`.
- **English only.**
  - The Unity build shipped English plus a first-pass Turkish translation. This handoff carries only the English copy.
  - Whether to localize again, and into which languages, is the user's call. If the answer is yes, it is worth designing both the text and the VO pipeline for it from the start.
- **Unfinished in the earlier build, so not decided:**
  - the profile-based endings (only a reusable ending shape and the five secret endings existed)
  - Chapter 6, which was never made
  - allocation and self-sacrifice as dedicated mechanics
  - the guess-the-crowd layer
  - the global stats backend

---

## 4. The core loop

1. The imp poses a question, of any type.
2. The player answers using one of the verbs.
3. An animated ink consequence plays, scaled to the question's weight.
   - A light question gets a quick 2 to 4 second beat. A heavy dilemma gets a full scene of 5 to 10 seconds or more.
   - Every question gets one. It is the game's edge over text-based question games.
4. The imp reacts over the world. He mocks the choice, whatever it was (section 8).
5. **A click gate.** The player clicks or presses a key to continue, so the choice lands before the room weighs in.
6. **The crowd reveal** appears on its own: "how others chose". One more input dismisses it.
7. The choice silently feeds the profile, if that question feeds it at all.

The reaction and the stats never share the screen or a click. The consequence owns the continue click, then the reaction clears. While the stats are up, they are the only thing listening for input.

- **Linear, one ordered run.**
  - The path is the same for everyone. This is not a branching story; only the ending differs.
  - The replay value is answering differently to get a different portrait and a different ending.
- **Beats.**
  - The run is an ordered list of beats. A beat is a cutscene, one or more lines from the imp, or a whole question.
  - The imp is always present, and narration runs between the questions.
- **Advancing.**
  - Narration advances by click or key, one dialogue box at a time.
  - Whether some narration should auto-advance after a pause was never settled.

---

## 5. Verbs, and how the earlier presentations map onto them

The verb is the structure of the decision. The presentation is how it is staged. The earlier build got most of its variety from presentations, not from new verbs.

| Verb | What it is | How the earlier build staged it |
|---|---|---|
| **Binary** | Pick one of two. The choice alone decides the outcome. | The trolley lever (pull or do nothing); the illustrated would-you-rather (two doodles); press-or-refuse buttons; buy-or-pass in the money shop; aim-and-fire between two targets, or fire-or-lower on one; the Who Would Win matchups (back one side); the timer (press or wait). |
| **Multiple-choice** | Pick one of several. The everyday question type alongside binary. | The three-track trolley; the three-way confession verdicts; the campaign's menus (class, reason, approach); the Last Bullet (fire at one of five coloured figures, or hold). |
| **Coordination gamble** | The crowd decides the outcome, resolved against a seeded crowd. It decides another soul's fate, never the player's. | The reframed viral blue/red button and its noisier children variant. The duel's seeded "does the other one fire" coin toss is a cousin. |
| **Allocation** | Divide or ration a limited good among parties. | Never built as its own verb. The money chapter's finite pile of cash, spent across many offers, is the closest relative. |
| **Self-sacrifice** | A cost to the player's own standing or how he is read, not his life, since he is already dead. Reserved for late-game climaxes. | Never built. |

Variations on binary that came up more than once:
- **An escalating offer (a ladder):** accept again and again as the stakes move, and stop whenever. The crowd split shown is the one for the tier where the player stopped.
- **An auction with a persistence threshold:** dropping out is free; refusing to drop out fires a secret ending.
- **A buyback:** sell back any, some or none of what you bought, at a loss.
- **Quantity:** buy as many units as you like.
- **Troll beats:** nothing actually happens, and all the weight is in the framing.
- **Two rare dice rolls.**
- **Campaign run flags** that change later options without ever forking the path.

---

## 6. The questions

- **The one rule.** A question qualifies only if it has no right answer **and** it either divides people or reveals something about the person answering. That is the whole test.
- **Every type is in scope.** That includes:
  - would-you-rathers
  - preferences and matters of taste
  - absurd hypotheticals
  - confessions
  - "who would win" arguments
  - "am I the asshole" disputes
  - genuine ethical dilemmas
- **Weight.** Tag every question light, medium or heavy.
  - Light and medium questions are the volume. Heavy dilemmas are rare, spaced spikes.
  - Heavy questions are the expensive units of writing and animation, and their count drives the animation budget. The earlier vision budgeted up to about 10 minutes of dialogue, buildup, consequence and aftermath for a heavy dilemma.
- **Waves, not a straight climb.** A run of lighter or absurd questions, then a gut-punch that lands harder because of the breathers before it. Three dials ramp together across a wave:
  - **Conceptual difficulty:** from clean, near-universal cases toward contested ones with no majority.
  - **Personal implication:** from strangers, to the crowd, to the player himself.
  - **Narrator intimacy:** from observational toward needling the player's emerging patterns.
- **Breathers.**
  - Quick illustrated would-you-rathers from a shared pool are sprinkled between the heavy beats.
  - Lighter chapters get fewer. None goes right before a chapter's finish, so the finale lands clean.
  - Each chapter in the earlier build added fresh items to the pool, so a full run never repeats one.
- **Sourcing.** A mix of:
  - real philosophical dilemmas (the trolley, the footbridge and their relatives)
  - well-known would-you-rathers and this-or-that splits
  - original scenarios
- **Topicality.** Use real current tensions, abstracted one step (pillar 5).
  - The earlier build's example: a baby with two abstract cues, a small square mustache and a paintbrush, asks "would you kill a baby now to stop what it becomes" while naming nothing real.
- **Ordering.**
  - Put famous, clean cases early to teach the loop.
  - Also put intuition-breaking variants, and questions with a surprising crowd split, early, so the stats can surprise the player.
- **Default versus divert.** In trolley-style questions, the worse death or the harder call sits on the track that needs an active pull. Doing nothing keeps the player's hands clean; acting is a choice.

---

## 7. How others chose (the crowd reveal)

- **The central hook, not a nice-to-have.**
  - Every question ends on it as a real beat.
  - It is the reason a question must divide people: a lopsided split says nothing.
- **Display-only.**
  - It never changes an outcome.
  - The one exception is the coordination gamble. There the crowd carries the outcome (the total decides another soul's fate), and the reveal shows the line the crowd had to cross.
- **Offline-first and optional.**
  - Ship with seeded numbers baked in, drawn from real survey data wherever it exists. Examples: MIT's Moral Machine for the classic dilemmas, and would-you-rather and preference surveys for the lighter questions.
  - Then blend toward real players' answers as they come in.
  - The baked seed doubles as the offline fallback, so every shipped question needs one.
  - **Every seed in `SCRIPT.md` is a first-pass placeholder chosen to divide people, not real data.**
- **A tiny global tally, later.**
  - A minimal backend: Supabase or a small serverless endpoint, explicitly not Nakama.
  - Hold off until real players are close. Seeded data covers everything before that.
- **Shapes of the reveal.**
  - Two bars for a binary split, three for a verdict, and up to six coloured bars for a breakdown (which coloured figure the shooters aimed at, plus who held fire).
  - A ladder shows the split at the tier where the player stopped.
  - The heading follows the chapter's voice ("how others chose", "how the room voted", "how the bar voted").
- **The imp can comment on the crowd without grading the player.** In the confession chapter he points out when the room ruled differently ("not the popular call"). That is relative to the crowd, never a moral judgment.
- **Guess the crowd (designed, never built).**
  - Now and then, not on every question, the imp makes the player guess before the reveal: are you with the crowd, or the odd one out?
  - It is a light test of self-knowledge. Keep it optional and occasional so it never becomes a chore.

---

## 8. The imp

**Character**
- A small hand-drawn devil (horns, a tail, a grin) who scribbles into being in the void and delivers all of the narration.
- **A gleeful tormentor and chaotic trickster.** He enjoys the player's confusion, and teases, needles and savours his game.
- **The chaos is a mask.** He seems capricious but is secretly tracking every choice; the ending shows how closely.
- **Cryptic about himself.**
  - He tells the player he is dead and that there is a little game.
  - He stays vague about why, what is at stake, what comes after, and what he is. He is cagey even about his name, as a running bit.
- **The same ceremony for the profound and the idiotic,** so the player never knows which is coming. His voice ties the whole range together.

**The mocking rule.** This is a writing rule, not a suggestion.
- **He mocks you whatever you choose, and never grades it.**
  - He never treats a choice as right, wrong, better or worse.
  - He mocks the hesitation, the speed, choosing at all, thinking it matters, and the hypocrisy of the man who judged everyone. He never mocks a choice for being good or bad.
  - Both options' reactions are mocking, and neither makes the other look like the better call.
- **Heightened glee without a verdict is allowed.**
  - He can relish one outcome more, such as sacrificing your partner, wherever the random nuke pin lands, or trying to abandon the campaign quest.
  - He still refuses to call it wrong ("there is no wrong here, remember").
- **A moment of surprise is not a character break.** The walking button catches him off guard for a beat, then the mask slides back on ("that has never happened, and I have been at this a long time").

**The five sanctioned breaks.** Each one fires a secret ending, then the credits. In play order:
1. **The baby (Chapter 1).** Pull the lever to send the trolley at the baby, and he breaks with genuine fury and real swearing, calls the player a monster and quits.
2. **The dollar (Chapter 2).** He stays business as usual down a halving price for a stranger's life, until the player accepts a whole life for one dollar. Then he drops the act in genuine disgust and quits.
3. **The cigarette auction (Chapter 3).** The player keeps bidding past all sense in an auction rigged so they can never win, and he cracks out of exasperation. He goes to give the player cancer, realises mid-thought that they are already dead, resurrects them so the curse counts, then curses them.
4. **Shoot the imp (Chapter 4).** The player aims at the imp instead of either target. He rounds on the camera: *Oh, you absolute fucking rat. You shot me. You shot the fucking referee.*
5. **Cheat the roll (Chapter 8).** The player lets him fudge the last die, and he turns on them, half awe and half disgust, that they would cheat even here, for a prize that does not exist.

The baby and the dollar are the one line he has. The auction and the cheat condemn the pointlessness of the act, not the morality of a choice, so no right answer sneaks in. Shooting the imp is a joke.

**Registers by chapter.** The same character in a different hat:
- **The gleeful tormentor** is the default. In the gun chapter he spells out its point: the trolley let you kill by standing still, the buttons by proxy, but the gun is your own hand.
- **Chapter 5: the guy egging on a stupid bar bet.** He takes sides, trash-talks the player's pick and stacks absurd modifiers. In the closer he admits that none of it told him a thing about the player's soul.
- **Chapter 7: a bored, snide court clerk.** He runs the docket, heckles the ruling and notes when the room ruled differently, making the dead judge do the old job.
- **Chapter 8: a bad Dungeon Master.** He railroads the player and lampshades it ("sit down, I built a dragon"), and keeps puncturing the fantasy. He notes that the player was more honest pretending to be someone else.

**The DUI** is a light recurring irony, never a thread.
- He lands it once, quickly (a sniff, a smirk), then only winks at it occasionally.
- It is not a mystery, a twist, a guilt arc or his main ammunition.
- Beats that brush against it stay cryptic and never become a reveal.

---

## 9. Writing rules for player-facing text

**No dashes.**
- This applies to all player-facing text in every language: dialogue, prompts, options, labels, stat headings, barks and credits.
- That means no em dashes and no en dashes. In practice the copy also avoids hyphenated compounds: it writes "six year old children" and "a 100 dollar cucumber", and only one "thank-yous" slipped in across roughly 990 strings.
- Use commas, full stops and colons instead. Translations use their own language's punctuation.
- The rule held from the very first prototype through the last commit, and every content pass was checked against it. The docs never say why, so ask the user if the reason matters.
- It does not apply to design documents like this one.

**The voice rules in section 8 are writing rules too:** mocking whatever the choice, no verdicts, heightened glee allowed, and only the five breaks.

**Colour markup.** The imp's lines carry simple inline tags that render the enclosed words in a meaning colour, for example `the [amber]five[/amber] on the main track will [red]die[/red]`.

The full vocabulary:

| Tag | Meaning |
|---|---|
| `[red]` | **Death and the guilty.** Killing and dying, and the words that name the guilty (kill, dies, dead, murderer, killer, guilty, rotten, liars, cheats, monster, cruel, vicious). It is the same red as the red-outlined figures and the red button. |
| `[amber]` | **The stakes, and emphasis.** Counts (five, one, two), money amounts, and genuinely stressed words. It is the one tag with any latitude, and it still has to be earned. |
| `[pink]` | **The player's partner, and love** (Someone You Loved). |
| `[gold]` | **The best life** (the golden crowned figure in The Better Offer). |
| `[blue]` and `[red]` | **The two buttons.** In the blue/red button dilemma only, the words that name the two buttons render in their own colours. |

How to apply it:
- **If a word carries a mapped meaning, colour it,** every time and in every chapter. Leaving it plain is a miss, not restraint.
- **A word with no mapped meaning and no genuine stress stays plain,** however long the line. Colour is never decoration.
- **Many lines carry no colour at all, and that is correct.** By the end of the earlier build, about 38% of roughly 990 strings carried any mark.
- **A coloured line usually has one to four spans.** The count comes out of the mapping; it is not a quota.

Conventions settled by the last pass:
- Money is `[amber]`, not `[gold]`.
- Negated death stays plain: "nobody dies" is not red.
- Choice labels carry no tags, because the option's own hover and commit colours already speak there.
- No invented colours.

Tags only belong in narration.
- In the earlier build, tags rendered only where narration was drawn: the dialogue box, floating pleas and voices, and the dice caption. Labels, readouts and receipt rows were plain text.
- Keep tags out of anything that won't render them, and strip them before text goes to TTS.

---

## 10. The profile and the endings

- **A silent "who you are" portrait, not a moral verdict.**
  - It is never shown during play: no gauge and no hints.
  - It tracks what kind of person the player is, across a small set of characterful axes where neither pole is the good one. It covers more than ethics.
- **First-pass axes.** Aim for four to six; the final list is open.
  - head vs. heart
  - self vs. others
  - order vs. chaos
  - risk vs. safety
  - honest vs. kind
- **The moral axes fold in** as the ethics-flavoured part of the portrait, and the heavy dilemmas still use them:
  - the one vs. the many
  - mercy vs. justice
  - ends vs. rules
  - order vs. freedom
- **What sits underneath.** The axes map onto real leanings (utilitarian, deontological, cautious, candid). That lets the ending say something like "you trusted your gut over your head, and you'd tell a hard truth before a kind lie" without ever scoring the player.
- **The requirement for any axis: neither pole is the right answer.**
  - The rejected framing was selfish vs. selfless, where selfless reads as the good person.
  - Where an axis sounds close to a virtue (self vs. others), it stays descriptive: it records which party the player puts at the centre of their reasoning, never "selfish = bad".
- **Candidate axes that surfaced and were deliberately not added:**
  - human vs. non-human, and present vs. future (from the last bear)
  - identity or self-preservation (from The Better Offer)
  - self-regard (from shooting yourself)

  Add one only if enough questions exercise it.
- **Not every question feeds the profile.**
  - Pure-taste questions exist for the fun and the crowd split, and that is fine. That covers most breathers, most matchups and the gags.
  - In the earlier build, each choice that fed it nudged one or two axes by a small signed value. All of these were first pass, and `SCRIPT.md` lists them.
- **Patterns feed it too:**
  - how far down the price-of-a-life ladder the player went
  - what they hoarded or spent in the money chapter, closed by a short read over a receipt (a portrait in miniature)
  - the pattern of verdicts in the confession booth
  - the class and choices in the campaign
- **Endings.**
  - There are multiple endings. Each is chosen by the portrait and delivered by the imp, never as a score.
  - The earlier build only had a reusable ending shape: an optional line, an effect, then a credits roll. Only the five secret endings used it.
  - Still open: how many endings there are, what each says, and how the profile maps to one (per-axis thresholds, a dominant-axis read, or a combination).
- **The secret endings are part of that set.** The five breaks (section 8) end the run early, each with its own line and the credits. Reaching any ending ends the run.

---

## 11. Structure and chapters

There is one linear run, the same for everyone. All the content is in `SCRIPT.md`; this section is just the shape.

- **Opening.** The crash flash, waking in the void, and the imp scribbling in to frame his game. It flows straight into Chapter 1.
- **Chapter 1, The Tracks.** Trolley problems as the imp's warm-up, each breaking the last one's easy answer. It opens on the baby (a secret ending) and ends on a three-track multiple-choice.
- **Chapter 2, The Buttons.** Temptation and complicity: each button offers something, and the cost lands on someone else, on you, or on no one. Includes the blue/red gamble and the price-of-a-life secret ending.
- **Chapter 3, The Money.** The temptation of value:
  - a finite pile of cash, and a shop of double-edged goods you can't all afford
  - a rigged cigarette auction (a secret ending)
  - a hyped finale that turns out to be a 100 dollar cucumber
  - a closing receipt and the imp's read
- **Chapter 4, The Gun.** The killing is literally in your hands: first person, aim and fire. It opens on the man and the last bear (the shoot-the-imp secret ending).
- **Chapter 5, Who Would Win.** A deliberate change of pace, not a dilemma at all. Barroom fight matchups where the crowd split is the whole payoff, ending on everything you have killed against you.
- **Chapter 6. Never made.** No content or brief exists. Chapters 7 and 8 keep their numbers in the remake, so one can slot in later (2026-10-23).
- **Chapter 7, The Confession Booth.** The dead judge does his old job. "Am I the asshole" disputes go from petty to heavy, with three verdicts each and the room's agreement as the payoff. It ends on two contradictory accounts, with no truth ever revealed.
- **Chapter 8, The Campaign.** A tiny DnD adventure with the imp as a bad Dungeon Master. It is linear with the illusion of choice, and ends on a roll he offers to fudge (a secret ending).
- **Breathers.** A shared pool of twelve illustrated would-you-rathers, placed between the heavy beats: four in Chapter 1, two in 2, three each in 3 and 4, and none in 5, 7 or 8. Stats-only by default.
- **The running gag.** The walking button debuts in Chapter 2 and keeps coming back, indestructible: as the auction rival, the charging mystery, an opponent and a confessor.
- **Not yet wired.** Chapters 7 and 8 were built ahead of Chapter 6 and never chained into the run, and the real endings didn't exist yet. In the remake, Chapter 7 follows Chapter 5 in the run.

---

## 12. Art direction

**The look**
- **Ink on paper.** A warm near-black hand-drawn line on a faint paper ground that feels like a sketchbook page, not blank white. The base is always monochrome.
- **Minimal, not sterile.** Minimal governs how many things are on screen; stylisation governs the character of each one. The style comes from four levers, none of which add clutter:
  - **A living ink line:** rough and hand-drawn, never clean vector, with a subtle boil (cycling two or three near-identical frames at about 5 fps).
  - **A faint paper texture** on the ground.
  - **Characterful type:** a hand-lettered face (the earlier build used **Caveat**, a free Google font, at SemiBold) that inks on in place and never shifts while it types.
  - **Ink-like motion:** things draw on and wipe or dissolve like ink, and figures keep a tiny idle life.
- **Stylisation never means more chrome,** more decoration, or busier screens.

**Figures**
- **Androgynous stick figures on one shared jointed rig, reposed.** Arms bend at the elbow and legs at the knee, the feet are anchored on a ground line, and there is a small breathing idle.
- **A deliberately minimal face: dot eyes only.** A sparse face reads friendly; a detailed one reads creepy. This is a hard rule for every figure and animal.
- **Variants come from reposing and small add-ons, not new art:**
  - children are the rig scaled down
  - elderly figures are stooped with a cane (the imp also names them as old)
  - sleepers trail z marks
  - the partner is pink with a pulsing heart
  - the best life is gold with a little crown

  Bespoke doodles are used only where the rig can't work, such as a baby bundle.
- **Non-human figures follow the same rule:** clean, minimal ink doodles.
  - The last bear is front-facing and sitting, with a rounded body and a tiny smile.
  - Her ears are open bumps on the head outline; full circles laid on top read as creepy.
  - She is filled solid brown.
- **Death is the fall, not a mark.**
  - A struck figure folds, topples and fades in one motion: stand, buckle, collapse, fade. Any add-on follows its joint down.
  - No strike lines, no impact puff, no blood.
- **The imp.**
  - A small ink devil with an idle life: a bob, a lean, a breath, and a nod while he speaks.
  - He scribbles in with a pop and hops springily to a new spot once per dialogue box. He always stays in the side wings, never on content and never in the empty centre stage.
  - The last build tinted him amber (keep it, or go back to black ink: open). A small optional set of expressions (grin, smug, glare, surprised) was used sparingly.
- **Every question gets an animated ink consequence,** scaled by weight.
- **Breathers and matchups use a quicker two-doodle presentation** on purpose: two small labelled doodles side by side, with "or" (or "vs") between them, and a brief amber flourish on the pick.
- **Doodles** are small ink drawings of things, each outlined in a colour matched to what it depicts. Crowds ("100 men") are drawn as a cluster of a dozen or so small copies, with the label carrying the count.

**Colour**
- **Colour is deliberate, for emphasis and meaning, never decoration.** The moment it turns decorative, it stops meaning anything.
- **Amber is attention and consequence:** hover, the lever, the aim lock, the chosen flourish, the player's own pick, money, counts and stressed words. It is never a fill.
- **The drawing follows the same mapping as the text (section 9).**
  - Any figure the imp brands as guilty is drawn with a red line; the red is his branding, not proof.
  - The partner is pink, the best life is gold, the blue/red buttons are blue and red, and the last bear is brown.
- **Identification colours.** Where figures need telling apart (the five in the Last Bullet), they get distinct muted colours, and the stat bars match.
- **Fills.**
  - Outline is the default.
  - A muted wash of the element's own colour inside the line (about 0.4 to 0.55 opacity, like coloured pencil inside a pen outline, never flat and saturated) is a sanctioned exception, for where an outline alone can't read. The wash tucks under the line.
  - The bear was the one solid fill.

**The palette from the last build.** A reference point, not binding.

| Role | Hex |
|---|---|
| Ink (warm near-black) | `#1B1A17` |
| Paper ground | `#F5F2E9` |
| Dialogue box paper fill | `#FBF9F1` |
| Amber accent | `#E8951E` (the imp's amber tint was a slightly darker `#D1851A`) |
| Muted ink (resting choice words) | `#8C887E` |
| Faded ink (the options not picked) | `#C0BBB0` |
| Stat heading | `#B0AB9F` |
| Crowd bar ink | `#46433B` |
| Other secondary ink | `#9A968C` |
| Red | `#AA483A` |
| Blue | `#3C6496` |
| Pink | `#D97392` |
| Gold | `#DBB447` |
| Brown | `#805C3D` |
| Green | `#4E8C55` |
| Orange | `#CC7A33` |
| Sky | `#5E9BC4` |
| Purple | `#8A5FA6` |

---

## 13. UI philosophy

- **The interface recedes** so that the void and the figures dominate.
  - No persistent meters, bars or status clusters, and the profile never shows.
  - No pop-ups or modal windows; prefer presentation inside the scene.
  - Every element has to justify itself. When in doubt, remove it.
- **The dialogue box** is the one softening of the "no boxes" rule.
  - A rounded, hand-drawn ink frame floating just above the bottom edge. Its wobbling border boils like every other line, as if the hand went around twice.
  - No shadow, gradient, portrait or buttons.
  - It sizes to its text and grows upward.
  - Text is centred in the hand-lettered face, and long narration pages by whole sentences, never splitting one across two boxes.
- **The choice row.**
  - Muted hand-lettered words in a row just above the dialogue box, with no box and no divider.
  - On hover a word turns amber and gets a hand-drawn underline. On commit the pick stays amber and the others fade.
  - Mouse or keys (1/2/3).
  - Where a beat has a control in the scene (the lever, a button, the crosshair), that control is the main way to pick, and the text row is the fallback.
- **The stat reveal.**
  - A lowercase muted heading, then one solid ink bar per option with a living edge, in option order.
  - Each label sits just above its bar. The bars ink in from left to right over about a second while their bare numbers (no percent sign) count up just past each bar's end.
  - The player's pick is amber and the crowd is a darker ink. Coloured splits use each bar's meaning colour.
  - No container, no flash, no bounce.
- **Floating ink text over a figure, with no bubble.** Used for pleas, the confessors' headlines, the walking button's own voice, and the menu barks. There is always a clear gap above the figure's head.
- **Controls in the scene, drawn in the same ink:**
  - an amber lever
  - round push buttons with a soft colour wash in the cap (the blue and red ones also carry a ring and a dot, so they never depend on colour alone)
  - a crosshair that tightens onto a target, which takes four amber corner brackets and nothing else (there is no on-screen gun; the aim reads through the crosshair alone)
  - a hand-drawn die
- **Readouts appear only where a chapter needs a running number,** such as the money chapter's amber balance and price tags.
- **Composed, centred tableaux.** Each question is laid out balanced above the dialogue box, on a consistent baseline.
- **The sanctioned menu exception.** The main menu, settings and pause are the one place a real menu belongs, kept hand-drawn and spare.
  - **Main menu:** a hand-lettered title, then New Game, Continue, Settings and Quit, with the current option in amber (2026-10-23: Quit added).
  - **Settings:** music, sound effects and voice volume, fullscreen, and auto skip (2026-10-23; the earlier build had music, SFX, fullscreen and language).
  - **Pause (Esc):** Resume, Save, Settings and Quit to Menu (2026-10-23: Settings added).
- **The menu imp.**
  - Every so often he says one short bark as floating ink text over his head, then hops to a fresh spot.
  - Barks come at random from a small pool, never repeat back to back, and never block input.
- **Credits:** a clean paper page scrolling upward, with each role in amber over its name in ink.

---

## 14. Audio and voice

**Music and SFX**
- Keep them spare, to match the visual minimalism.
- The earlier build had a single quiet looped track under everything, carried unbroken from the menu into the game, and sparse SFX (a gunshot, a button click).
- All of the earlier audio was placeholder.

**The earlier imp voice**
- A gibberish blip voice: short pitched blips every couple of characters as the text typed, in the style of Animal Crossing or Undertale.
- The user had it reworked lower and warmer, with a narrow pitch spread, so it read as a talky mutter rather than a shrill stutter. Treat that as a taste signal: the user tuned away from squeaky.

**Voice acting now (ElevenLabs)**
- **The imp's lines become voiced.** The text stays on screen, and the dialogue box remains the frame. Voice is added on top.
- **Strip the colour tags before TTS.** You might treat `[amber]` spans as hints for stress in the delivery, but never send the tags themselves.
- **Regeneration is the point.** Keep a stable id per line, and track which audio matches which copy, so the writing can stay fluid.
- **Decide with the user:**
  - whether text types out in sync with the voice or appears whole
  - whether the gibberish blip survives for anyone (the walking button, perhaps)
  - whether the per-chapter register shifts are one voice or distinct takes
  - how the swearing is handled

**A starting voice brief for the imp.** This is drawn from the docs, for the user to refine.
- A small devil with a big personality: gleeful, quick, theatrical and delighted with himself. Lower and warmer than a squeaky cartoon goblin (inferred from the blip tuning above).
- **His default register** is a smug, needling tormentor who savours every second. He gives the silly questions and the heavy ones the same ceremony, so the absurd can sound grave and the grave can sound amused.
- Never preachy, and never sincere approval or disapproval. The needle is always amused.
- **He can turn on a dime:**
  - genuine fury and disgust in the baby and dollar breaks
  - spluttering exasperation in the auction break
  - wounded indignation when shot ("you shot the fucking referee")
  - half awe, half disgust at the cheat
  - one genuinely startled crack at the walking button before the smugness snaps back
- **His register hats:**
  - the guy egging on a stupid bar bet (Chapter 5)
  - a bored, procedural, snide court clerk (Chapter 7)
  - an over-eager, railroading Dungeon Master whose earnest fantasy narration he keeps puncturing by stepping out of character (Chapter 8)
- He swears naturally and with timing, not constantly.

**Other speakers in the script**
- **The walking button:** a small, put-out, easily offended voice that swears. It confesses in total earnest in Chapter 7 and taunts the player as an auction rival.
- **Pleas and confessions.** Several souls have a line or two:
  - the begging figure, the parent and the dying soul
  - the loyal friend and the one who ran
  - the person who wants you to shoot them
  - the confessors filing into the booth, and the two contradictory accounts

  These could be voiced, or stay as floating text. In the remake each confessor is voiced, with a voice of their own (2026-10-23); the pleas are still open.
- **The player character never speaks.** He is the point of view.

---

## 15. Save, continue, settings and languages

- **One continuous save, not slots.**
  - It captures everything a faithful resume needs: the position in the run (chapter and beat), the profile so far, and any run state that later beats read.
  - The earlier build saved the position, the profile and the money chapter's economy (the balance, plus what was bought and skipped).
  - It had not yet saved the campaign's class and flags or the kill tally, which was a known gap.
  - Any new state that carries across beats belongs in the save.
- **Auto-save on entering each beat.**
  - It happens silently, so quitting never loses more than the current beat, which replays cleanly on resume.
  - A manual save also lives in the pause menu.
- **Continue** resumes at the exact beat with the run state restored. It is greyed out when there is no valid save, and a missing or corrupt save simply counts as no save.
- **New Game** asks for confirmation first if a run exists, then clears the save and the profile.
- **Reaching any ending clears the run save,** because the run is over. The earlier build kept a rough record of which endings were seen, with a possible endings gallery in mind.
- **Settings.**
  - **The remake has (2026-10-23):** music, sound effect and voice volume, fullscreen, and auto skip, kept between sessions.
  - **The earlier build had:** music volume, SFX volume, fullscreen and language.
  - **Candidates never added:** text speed (asked for in the original brief), resolution, a master volume and key rebinding.
  - **With voice acting,** a voice volume and probably a text speed or auto-advance setting join the list.
- **Languages.**
  - The earlier build shipped English and Turkish, with one translation file per language keyed by the English text.
  - Colour tags travelled per language: each translation marked its own words.
  - Numbers and currency were formatted for the locale.
  - Some jokes swapped per language. The free-food offer showed a burrito for English and a kebab for Turkish.
  - Swearing was translated idiomatically, not literally.
  - This handoff carries English only. Whether and how to localize the remake is the user's call.

---

## 16. Open questions

Moved to `OPEN_QUESTIONS.md`, which now tracks every unsettled question, including the ones carried over from the earlier build.
