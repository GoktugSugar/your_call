# Open questions

Everything not yet settled. Park unknowns here instead of guessing, and decide them with the user. When one is settled, log the answer in `DECISIONS.md` with its date and remove it from this file.

Creative questions are the user's to answer. Technical ones are the developer's, and they are only listed here while they wait on a creative answer.

## To review in the morning

Creative calls made overnight on 2026-10-22, while the user slept. Each is provisional and logged in `DECISIONS.md`; confirm or change them.

**Chapter 3, The Money** (review page: https://claude.ai/artifact/QA5qDmmYa42PervaPb7Kaw)
- The trimmed copy, 14% shorter. Alternatives: trim harder, or keep more of the original.
- The teases about the end play as narration after the crowd reveal. Alternative: back after the reaction, before the reveal, as the old build had it.
- 3.02's brand became burritos. Alternatives: another everyday food, or a placeholder per language later.
- The 3.08 tease and 3.18 spike line reworded to hold whatever the player has spent. Alternative: two versions of each, picked by the wallet.
- The cut DUI winks (3.10's ask, 3.16's purchase). Alternative: keep them all.
- The auction's button comes in from the left. Alternative: from the right, as the script says, walking past the imp's wing.
- Each auction round is one line from the imp (the needle and the prompt together). Alternative: the needle clears by itself first, then the prompt.
- The rage's delivery: glaring, voiced with "[exasperated]". Alternative: another direction, or none.
- The buyback points at the row instead of naming the thing and the amount; he reacts to the first sale and keep only. Alternative: voice each item's name and offer (a take per item and amount).
- The years cost $100 more each ($700 up), with a line when the money runs out and one after the first year. Alternatives: a flat $700, or a steeper climb.
- The colours of the items the script left uncoloured.
- The weights given to Chapter 3's questions.

**Chapter 4, The Gun** (review page: https://claude.ai/artifact/HDpDmK7RQpz8XC5v2dv4i9)
- The trimmed copy, 21% shorter.
- 4.02: lowered, the dying one dies anyway a moment later. Alternative: it stays alive, pleading, while the imp speaks.
- 4.03: no hold option, and "Aim, or do not" cut. Alternative: add a "Lower the gun" option.
- 4.05: a six second charge. Alternative: a shorter or longer one. (Shot, it now stops where it was hit: the user's call.)
- 4.05: the button's "Again?" only if it woke in 2.11. Alternative: always "Again?" (the button remembers the player either way).
- 4.06: "Fire blind" in the row fires at random. Alternative: list the five colours in the row.
- 4.08: no choice row, eight seconds, then the gun lowers itself. Alternatives: a choice row after all, or a different wait.
- 4.12: the brackets frame the whole view for the gun turned on the player. Alternative: another way to show it with no avatar.
- 4.13: the reveal split into each option's reaction.
- The imp's shot line voiced with "[outraged]".
- The pleas (4.02, 4.03, 4.14) stay unvoiced: there are no free voice slots for new speakers.

**Chapter 4's figures** (drawn by a helper on 2026-10-22, provisional, logged in `DECISIONS.md`)
- The bear's tiny smile on a lighter muzzle, against the dot eyes only rule for faces. Alternatives: the smile without the muzzle, or dot eyes alone (both are switches).
- The bear's outline in ink around the solid brown. Alternative: a brown outline, so she is a brown shape with no ink edge.
- The future baby's mustache, a flat topped block high under the eyes, and the paintbrush on the ground beside the blanket with sky paint. Alternatives: another identification colour, or the brush propped against the bundle.
- The future baby at 2.4 times the bundle. Alternatives: anywhere from 2.2 to 2.6.
- The armed stranger's pistol in a muted grey wash, held at mid chest with the elbows out. Alternative: an outline only.
- The dying soul's kneel with its shins splayed along the ground, reaching out and up with one hand. Alternatives: a lower slump propped on one hand, or both hands raised.

**Chapter 5, Who Would Win** (review page: https://claude.ai/artifact/Pic5ATmJtsKUYSDBFJjnZi)
- The trimmed copy, 13% shorter.
- 5.03's corrected sum: nine hundred and sixty to one.
- 5.06's two asks, by whether the button was shot in 4.05. Alternative: one ask that names none of its history.
- 5.10 points at the count on the label instead of naming the bear and the man. Alternative: versions by what was killed.
- 5.10 counts a nuked country's people, so the label can read in the billions. Alternative: count only the souls on screen.
- 5.10's mob has the last bear in it only if she was shot in 4.01; the script always puts her there. Alternative: always the bear.
- 5.10's lead in still says "whoever you put a bullet in" on a run that shot nothing in Chapter 4. Alternative: a version for a run with no shots.
- Both "You" and the button in green in 5.06's reveal. Alternative: another colour for one of them.

## To review: the first trailer

Made on 2026-10-22 without the user, who asked for no questions. Each call is provisional, logged in `DECISIONS.md` and described in `docs/TRAILER.md`; confirm or change it, then re-render (`python tools/trailer/render_trailer.py`).

- The twelve lines. Alternatives: rewrite any of them; let the imp swear once; say more of the premise ("a little game", "no right answer") in words rather than through the lever line.
- The shots: the lever, the nuke on Monaco, the burritos, the five colours under the gun, a hundred men or one gorilla. Alternatives: another country for the pin, another shop item or gun question, a would you rather, or more crowd reveals.
- The walking button is held back, as the user wanted to be asked before showing it come alive. Alternative: show it, in 2.11 or charging in 4.05.
- The portrait is held back: the imp only says he is reading you.
- The title card: "Your Call" (the working title) with "Wishlist on Steam" and no date. The final title, a date, or other words for the call to action are one line each in the cut.
- The music: Eleven Music, a dark carnival waltz and a title sting. Alternatives: other takes (in `music_auditions/`), a new prompt or plan, a licensed track, or no music.
- The waltz take 1, sting take 3, crash take 2 and pen scribble take 2 were picked by measurement, not by ear. Pick again with `python tools/music/music_takes.py <piece> --save <take>` or `python tools/sfx/sound_takes.py <sound> --save <take>`.
- How long it runs: 63 seconds. Alternatives: trim the cold open or the montage to land under a minute.
- A custom thumbnail for the Steam page (a frame of the video, 1920x1080, without text), if Steam's own pick is not wanted.

## Carried over from the earlier build

These came from `PREMISE.md` on 2026-10-21: all of its former section 16, plus the points sections 9 and 14 leave to the user.

**Design**
- The final title. *Your Call* is the working title; check that it's available before release.
- The final profile axes (how many, and their names), which questions feed which axes and how heavily, and how to keep every axis sampled when most of the volume is light.
- The endings:
  - how many there are, what each says, how the profile picks one, and how the imp's delivery shifts between them
  - whether Yourself or The Person Who Wants You To should become secret endings too
- What Chapter 6 is, and the running order from Chapter 5 through to 8.
- The total question count, and the light/medium/heavy ratio, for 5 to 6 hours. The original estimate of 25 to 35 full scenes predates the shift to mostly light questions.
- Whether allocation and self-sacrifice get dedicated beats, or the presentations in section 5 of `PREMISE.md` already cover that ground.
- Guess the crowd: how often it happens, how it's presented, and whether a right or wrong guess gets a reaction.
- The imp's name: does he ever give one, or keep refusing?
- The imp's expressions: everywhere, or only at specific moments. (His ink is settled: amber.)
- Replayability: should there be a New Game+? Do the endings and the imp's treatment change enough to make replays worth it?
- The would-you-rather pool:
  - growing it
  - whether breathers should draw randomly from the pool each run
  - whether Chapters 7 and 8 get breathers
- The killed-everything finale: a full log of every kill across all the killing beats, for a mob that is truly specific to the run.
- More "same fight, one change" matchup gags, and more confession cases with an "everyone at fault" middle.

**Crowd data**
- Where the real seeds come from: surveys, polls, playtests. Every number in `SCRIPT.md` is a placeholder chosen to divide people.
- When to build the global tally, and how to blend the seeds toward real players' answers.
- A richer "how much did others pay" stat for the money chapter.

**Colour and text**
- Three meanings have no tag. Either add tags or leave these words plain:
  - the green, orange and purple figures in the Last Bullet, which the imp names aloud
  - the brown bear
- Whether choice labels should ever carry their mapped colour.
- Whether the fuller colour pass reads as rich or as busy in places.
- Why player-facing text has no dashes. The rule holds either way; the reason only matters if it ever needs bending.

**Voice and pacing**
- Whether the pleas and the confessors are voiced. (The walking button gets its own voice.)
- Whether the gibberish blip voice survives for anyone (the walking button, perhaps).
- Whether the imp's per-chapter register shifts are one voice or distinct takes.

**Music**
- The real background music. The current track is a placeholder of unknown licence, played locally and kept out of the public repository.

**Language**
- Whether to localize again, and into which languages. If yes, the text and voice pipelines should be designed for it from the start.
