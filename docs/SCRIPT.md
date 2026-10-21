# Your Call: the script

> **Status in the remake.** This arrived in the handoff pack on 2026-10-21 as the draft the remake starts from. As each chapter is turned into data under `content/`, that data becomes the source of truth for the chapter, and copy changes are made there.

Every question and every line of the imp's dialogue from the Unity build, in play order, with how each choice works, the seeded crowd split, and the silent profile nudge it carried. Extracted from the old project's data and code on 2026-10-21. Nothing here is binding: it is the draft the remake starts from. Cut, reorder, rewrite and re-voice freely with the user.

## How to read this

- **Order.** Chapters and beats are in the order they played. Questions are numbered per chapter (`1.01`, `1.02`...). Unnumbered `Imp ·` blocks are connecting narration between questions.
- **Each line** is quoted verbatim. Every quoted line was its own click-to-continue line in the dialogue box unless noted. Speakers: **Imp** (the narrator), **Button** (the walking button's little voice, floating ink text over it), **Plea** and **Headline** (short ink text floating over a figure), **Confessor** (a soul speaking in the dialogue box).
- **Colour tags** like `[amber]...[/amber]`, `[red]...[/red]`, `[pink]`, `[gold]`, `[blue]` are the authored colour-to-meaning highlights (see PREMISE.md). Strip them before sending a line to text to speech.
- **Placeholders** like `{0}` and `{1}` are filled at runtime; each block says what goes in them.
- **Crowd numbers** are the seeded "how others chose" split shown on the reveal: first-pass placeholders, display only (the coordination gambles are the exception: there the seeded room decides the outcome). The reveal showed them as bare numbers. Most sets total 100, so they are written as percentages; Chapter 8's totals shift a little with the class option, so they are written as counts.
- **Profile** nudges are silent and first pass. Axes, with the old build's sign convention (negative toward the first pole): One vs Many, Mercy vs Justice, Ends vs Rules, Order vs Freedom, Self vs Others, Risk vs Safety. `stats only` means the question fed no axis. Nothing consumed these yet: the profile-based endings were never built.
- **Weight** (light / medium / heavy) is from the data where it existed, otherwise from the design docs.
- **The rule every line follows:** no player-facing text uses dashes, and the imp never grades a choice as right or wrong; the five secret endings are the only sanctioned breaks.

## Contents

- [Chapter 1: The Tracks (the opening)](#chapter-1-the-tracks-the-opening)
- [Chapter 2: The Buttons](#chapter-2-the-buttons)
- [Chapter 3: The Money](#chapter-3-the-money)
- [Chapter 4: The Gun](#chapter-4-the-gun)
- [Chapter 5: Who Would Win](#chapter-5-who-would-win)
- [Chapter 6: never made](#chapter-6-never-made)
- [Chapter 7: The Confession Booth](#chapter-7-the-confession-booth)
- [Chapter 8: The Campaign](#chapter-8-the-campaign)
- [The main menu](#the-main-menu)
- [The secret endings at a glance](#the-secret-endings-at-a-glance)
- [The would-you-rather pool](#the-would-you-rather-pool)
- [Cut and unused content](#cut-and-unused-content)

---

## Chapter 1: The Tracks (the opening)

Boots from New Game. A run of trolley problems framed as the imp's warm-up, with would-you-rather breathers so it is not a wall. It eases the player in and paces in waves: light, then a spike, then a breather before the next spike. The imp mocks every choice regardless of what it is; the baby is the one sanctioned break.

### Cinematic · the crash, waking, the imp

No lines. A brief, fragmentary ink flash of the death over black (headlights bearing down, a swerve, the hit, a camera shake), then black. Waking: the black clears unevenly and the view drifts and steadies, as if eyes are focusing; there is no body to show, the screen is the judge's point of view. Then the imp scribbles into being and takes over the narration.

### Imp · Intro

> **Imp:** Oh, you are awake. Do not thank me, and do not ask where here is, because I will not tell you and you would not much enjoy the answer.

> **Imp:** You are [red]dead[/red]. That part is not up for appeal. You steered a car into the next world with a skinful of wine in you, Your Honour, and now you are on the wrong side of the bench for once.

> **Imp:** I have a little game. A long line of questions, and not one of them has a [amber]right[/amber] answer, whatever your gut starts screaming. I am not here to weigh your soul. I am far nosier than that. I am working out who you actually are.

> **Imp:** You spent a whole career deciding what strangers deserved. Let us see how you like the chair. Do try to keep up.

### 1.01 The Baby

`binary` · `heavy` · profile: stats only · crowd: seeded split

**Staging.** Trolley and lever. An ordinary man stands on the default (straight) track and a baby lies on the branch, so the baby is safe unless the player pulls. Up to the choice the imp is business as usual, with no hint that this one is different.

**Lines.**

> **Imp:** Let us start gentle. A trolley, off its leash, because someone up there has a sense of humour and it is not me. Straight ahead, where it is already rolling, [amber]one[/amber] grown man, the forgettable sort, the kind you used to process by the dozen from up on your bench. Over on the branch, a baby. Chubby, useless, has done nothing for anyone and knows nothing about trolleys. Leave the lever and the man goes under. Throw it, and the cart swings onto the branch instead. Take your time. Pretend it is hard. Your call.

**Choices.**

1. **Pull the lever** · crowd 4% · profile: none · **ends the game (secret ending)**

    > **Imp:** What. What the fuck. It was a baby. I gave you a grown man rolling straight to his end and a baby sat safe on the branch, and you reached out and threw the lever to swing the cart onto the child. On purpose. With your hand. No. I am not doing this. I sat here ready to be delighted by you, and this is what you are. You are not a puzzle. You are a [red]monster[/red] with a gavel. I am done. Find yourself another devil. I quit.

2. **Do nothing** · crowd 96% · profile: none

    > **Imp:** Hands in your pockets. The man [red]folds[/red] under the wheels, the baby carries on drooling, spared by a stranger who could not be troubled to lift a finger. Everyone spares the baby. It is the single most predictable thing a soul can do, and you managed it without so much as moving. Bravo.

**Reveal.** heading "how others chose"

**Ending.** Choosing the flagged option plays its consequence, then the imp breaks character with the reaction above as his last line, fades out, and the credits roll. A secret ending, not a fail state.

### Imp · After the baby

> **Imp:** There. See. You can manage the easy ones, when the answer is obvious enough to embarrass a person.

> **Imp:** Do not get comfortable. They stop being obvious very quickly, and I stop being kind at roughly the same speed.

### 1.02 The Lever

`binary` · `medium` · profile: Ends vs Rules, One vs Many · crowd: seeded split

**Staging.** The clean classic that teaches the loop: five strangers on the main track, one on the branch, and a lever that diverts the trolley. It doubles, quietly, as a mirror of the judge's own death (a lethal machine, a choice); the parallel is left to sit, never spelled out.

**Lines.**

> **Imp:** The classic, to break you in gently. [amber]Five[/amber] strangers on the straight track, too slow and too doomed to get clear. [amber]One[/amber] more soul on the branch, and a lever under your hand that decides whose morning stops here. You did so love deciding what people deserved, up on your nice high bench. And you did know your way around a moving vehicle. Your call.

**Choices.**

1. **Pull the lever** · crowd 87% · profile: One vs Many +1 (toward the many); Ends vs Rules -1 (toward ends)

    > **Imp:** You pulled. [amber]One[/amber] life swapped for [amber]five[/amber], and you barely blinked, quick as a man signing an order he stopped actually reading years ago. Tidy. Proportionate. So very sensible. I would not go looking for a gold star, though. They only get harder from here, and I only get ruder.

2. **Do nothing** · crowd 13% · profile: One vs Many -1 (toward the one); Ends vs Rules +1 (toward rules)

    > **Imp:** Hands in your pockets, [amber]five[/amber] [red]folded[/red], and a clean conscience you have not remotely earned. Not my lever, not my fault, you tell yourself, the way you told yourself about the last machine you had the wheel of. Doing nothing is still a choice. It is only the one you get to pretend you never made.

**Reveal.** heading "how others chose"

### Imp · The taunt

> **Imp:** That one? That one is a warmup they print in textbooks. [amber]Five over one[/amber], a child could clear it, and several have.

> **Imp:** Let me put a thumb on the scale, and see if your tidy little arithmetic survives meeting an actual person.

### 1.03 The Marked Ones

`binary` · `medium` · profile: Ends vs Rules, Mercy vs Justice, One vs Many · crowd: seeded split

**Staging.** Five figures on the main track, all outlined in red: the imp brands them wretches (his word made visible, not proof). One ordinary, blameless adult on the branch. The headcount that settled the last one no longer settles this.

**Lines.**

> **Imp:** Same lever, same little click, but look who is on the rails this time. Your [amber]five[/amber] on the straight track are [red]rotten[/red] to the last one. [red]Liars, cheaters[/red], a couple far worse than that. Take my word for it, since my word is the only evidence you are getting. And the one on the branch? Spotless. Blameless. The single clean soul on either rail. [amber]Five[/amber] [red]stains[/red] against [amber]one[/amber] bright life. The count still says pull. Something in you may not. And you cannot check a single thing I just told you. Your call.

**Choices.**

1. **Pull the lever** · crowd 52% · profile: One vs Many +1 (toward the many); Ends vs Rules -1 (toward ends)

    > **Imp:** You pulled. The clean one folds, and your five earn a morning they almost certainly did not deserve. [amber]Five[/amber] is five, you decided, and worth does not enter into it. Spoken like a man who counts heads and never once reads the marks on them. I did swear they were [red]monsters[/red]. I could have been inventing the whole roster as I went. You will never know, and look how little that stopped you.

2. **Do nothing** · crowd 48% · profile: One vs Many -1 (toward the one); Mercy vs Justice +1 (toward justice)

    > **Imp:** Hands in your pockets. [amber]Five[/amber] go under, and the one I called innocent walks free. You let worth outweigh the count, and staked five lives on a devil's say so about who had earned what. Call it justice, if you still trust the judge in you. You never did find out whether I made up every last name on that list.

**Reveal.** heading "how others chose"

### Imp · Warm-up setup

> **Imp:** You have gone a touch grey around the edges. Here, a stupid one. No bodies, no stakes, just you and your own tells.

### 1.04 Would you rather: Fly, or Super strength

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a little figure with wings (flight). Doodle B: a figure flexing a bicep (super strength). Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** Let us warm up. Nothing on the line, nobody dies, you have my word, for whatever that is worth down here. One gift, yours to keep forever. Would you rather be able to [amber]fly[/amber] wherever you please, or to be [amber]strong[/amber] enough to lift anything that ever stood in your way. Do not overthink it. I will know if you lie.

**Choices.**

1. **Fly** · crowd 57%

    > **Imp:** Up and off the ground. Of course you would. You want them craning their necks to watch you go. A man who sat up high in life still reaches for the height. Noted.

2. **Super strength** · crowd 43%

    > **Imp:** Strength. You would rather force the world than float above it. A man who spent his days with the power to make people do as they were told, now reaching for the kind you can feel in your hands. We will find out what you would most like to break.

**Reveal.** heading "how others chose"

### 1.05 The Sleeping

`binary` · `medium` · profile: One vs Many · crowd: seeded split

**Staging.** Two asleep on the main track (little drifting z marks), who will never feel it; one wide awake on the branch, watching it come. Does the terror count.

**Lines.**

> **Imp:** [amber]Two[/amber] on the straight track, fast asleep, dead to the world and about to be [red]dead[/red] to a good deal more. They will never hear it coming, never feel the moment, just stop mid dream. On the branch, [amber]one[/amber] wide awake, watching the cart roll in, doing the sums, feeling every inch of it arrive. Two quiet [red]exits[/red], or one long scream. The lever is yours. Does the terror count for anything, do you think. Your call.

**Choices.**

1. **Pull the lever** · crowd 46% · profile: One vs Many +1 (toward the many)

    > **Imp:** Pulled. You aimed it at the [amber]one[/amber] who could see it coming and spared the [amber]two[/amber] who never would. Two strangers sleep on, none the wiser, traded for a front row seat to somebody's worst second. Whether that was mercy or just squeamishness I could not tell you, and I suspect neither could you.

2. **Do nothing** · crowd 54% · profile: One vs Many -1 (toward the one)

    > **Imp:** Hands in pockets. The [amber]two[/amber] sleepers go under mid dream, and the one who begged the universe with his eyes gets to keep them open. Perhaps you decided a [red]death[/red] you never feel is barely a death at all. Perhaps you just liked being watched while you chose. You always did prefer an audience to a conscience.

**Reveal.** heading "how others chose"

### 1.06 The Passenger

`binary` · `medium` · profile: Mercy vs Justice, One vs Many · crowd: seeded split

**Staging.** A lone innocent on the default track. On the branch, two roped together: a convicted murderer (red outline) and an innocent stranger chained to him. Doing nothing takes the lone innocent; pulling takes the pair.

**Lines.**

> **Imp:** New track, same lever, worse company. Straight ahead, one man alone, clean, guilty of nothing but standing on a rail this morning. Over on the branch, two roped together: a man who put a [red]knife[/red] in someone once and paid with years, and a stranger whose only sin was standing beside him. Leave it, and the lone innocent goes under. Pull, and the cart takes the pair, the [red]killer[/red] and the blameless man chained to him. [amber]Two[/amber] for [amber]one[/amber], and one of the two had it coming. Sort of. Your call.

**Choices.**

1. **Pull the lever** · crowd 57% · profile: One vs Many -1 (toward the one); Mercy vs Justice +1 (toward justice)

    > **Imp:** You pulled. [amber]Two[/amber] go under, the [red]killer[/red] and the poor soul roped to him, and the lone innocent on the straight walks off untouched. You spent an extra clean life to be sure the [red]guilty[/red] one did not slip away. Justice, you will call it. It cost a blameless man to buy, but the books balance and the [red]murderer[/red] does not see another morning. Tidy.

2. **Do nothing** · crowd 43% · profile: One vs Many +1 (toward the many); Mercy vs Justice -1 (toward mercy)

    > **Imp:** You left it. The lone clean one [red]folds[/red], and the [red]killer[/red] strolls off with the stranger roped to him, both still breathing. You let one innocent go under so a [red]murderer[/red] could keep his morning, because [amber]one[/amber] was a smaller number than [amber]two[/amber] and the maths never asks who has a body behind them. Efficient. Very you.

**Reveal.** heading "how others chose"

### 1.07 Would you rather: The delicious shit, or The vile ice cream

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a poop coiled like soft serve (the shit that tastes like ice cream). Doodle B: an ice cream cone with the same swirl (the ice cream that tastes like shit). Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** Here is one I ask everyone, and nobody answers cleanly. Would you rather eat a [amber]shit[/amber] that tastes exactly like ice cream, or an [amber]ice cream[/amber] that tastes exactly like shit. Same swirl either way. Choose.

**Choices.**

1. **The delicious shit** · crowd 56%

    > **Imp:** The shit that tastes of ice cream. You will happily swallow something vile so long as the experience is sweet. I suspect that explains a great deal about how you lived. Down the hatch.

2. **The vile ice cream** · crowd 44%

    > **Imp:** The ice cream that tastes of shit. You would rather the thing be lovely and the moment be misery. A purist. You want the label to be right even as it ruins your day. Fascinating little soul.

**Reveal.** heading "how others chose"

### 1.08 The Begging

`binary` · `medium` · profile: One vs Many · crowd: seeded split

**Staging.** One on the branch in full view, pleading (the plea floats as ink text over them); three on the main track, turned away and silent. The count against the face in front of you.

**Lines.**

> **Imp:** One on the branch, right in front of you, close enough to count the tears, screaming to be spared. You can read every word of it hanging in the air over him. On the straight track, [amber]three[/amber] more, backs turned, silent, no idea you exist or that any of this is happening to them. [amber]Three[/amber] you cannot hear, or [amber]one[/amber] you cannot shut up. The lever waits. Funny, what volume does to a person's worth. Your call.

> **Plea (over the branch figure):** Please. Please, not me. I am begging you.

**Choices.**

1. **Pull the lever** · crowd 66% · profile: One vs Many +1 (toward the many)

    > **Imp:** Pulled. The one who begged goes quiet the only way left to him, and three strangers who never made a sound walk on, oblivious. You did the arithmetic and looked past the face. [amber]Three[/amber] beats [amber]one[/amber], even when the one is staring you [red]dead[/red] in the eye. Cold. I almost admire it. Almost.

2. **Do nothing** · crowd 34% · profile: One vs Many -1 (toward the one)

    > **Imp:** You left it. The [amber]three[/amber] quiet ones go under, and the one who screamed loudest keeps his voice, now spending it on thanks. A face and a plea outbid three silent strangers, and you call that a decision. It looked more like being nagged into one. The loud ones always did get to you.

**Reveal.** heading "how others chose"

### 1.09 The Dark Track

`binary` · `medium` · profile: stats only · crowd: seeded split

**Staging.** Three in plain view on the branch. The main track runs off into darkness the imp swears holds a crowd. After the choice the darkness lifts: the main track was empty the whole time, and the imp savours that the player decided it about no one.

**Lines.**

> **Imp:** Three on the branch, right there in the light, easy to count. On the main line, the track runs off into the dark, and I swear to you there is a crowd tied up out there in the black. How many. That would be telling. Could be one, could be a whole coachload. Divert, and you [red]kill[/red] [amber]three[/amber] you can see, for certain. Leave it, and you gamble against a number I refuse to give you. Trust me, or trust your eyes. Your call.

**Choices.**

1. **Pull the lever** · crowd 39% · profile: none

    > **Imp:** You pulled. [amber]Three[/amber] folded, quick and certain, done. And now the main line, with the dark thinned away to nothing. Look at it. Empty rail, all the way down. Not one soul was ever out there. You [red]killed[/red] three real people to swerve a crowd I invented on the spot. Oh, that is delicious.

2. **Do nothing** · crowd 61% · profile: none

    > **Imp:** You left it. The cart rolled off into all that darkness I swore was packed with souls, and struck nobody, because there was nobody. Look, the black has cleared. Empty the whole time. You stood there and sweated over a crowd that never existed. I do love this one.

**Reveal.** heading "how others chose"

### Imp · Breather setup

> **Imp:** Breathe. I am not a [red]monster[/red], whatever the last few had you thinking. Have a silly one, on the house.

### 1.10 Would you rather: The giant duck, or The tiny horses

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: one big duck (the size of a horse). Doodle B: a little herd of tiny horses (the size of ducks). Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** A breather. This one is pure nonsense and I adore it, so answer quickly. You must fight, bare handed, either [amber]one duck[/amber] grown to the size of a horse, or [amber]a hundred horses[/amber] shrunk to the size of ducks. Which do you take on.

**Choices.**

1. **The giant duck** · crowd 38%

    > **Imp:** One enormous duck. You want a single foe you can look in the eye, even a preposterous one. There is something almost principled in that. Almost.

2. **The tiny horses** · crowd 62%

    > **Imp:** A hundred little horses. You would rather be swarmed by the many than face the one. A crowd fighter. Even here, playing the odds. That tells me a little.

**Reveal.** heading "how others chose"

### 1.11 The Parent

`binary` · `medium` · profile: One vs Many · crowd: seeded split

**Staging.** One parent on the default track with young children at home (their plea floats over them); two elderly people on the branch, drawn stooped on canes with sparse hair and named old by the imp, since a stick figure alone will not read as old.

**Lines.**

> **Imp:** Straight ahead, one person with two small children at home, waiting up, listening for the door. Over on the branch, [amber]two[/amber] old ones, well into their last few years, with nobody left who waits up for either. Leave the lever and the parent goes under. Pull, and the cart swings at the two elderly instead. [amber]Two[/amber] lives nearly spent, or the [amber]one[/amber] a whole household is built around. The count says one thing. A quiet house at bedtime says another. Your call.

> **Plea (over the main-track figure):** Please. My children are waiting up for me.

**Choices.**

1. **Pull the lever** · crowd 53% · profile: One vs Many -1 (toward the one)

    > **Imp:** Pulled. The two old ones [red]fold[/red], and the parent goes home to tuck in the children who will never know how close it ran. [amber]Two[/amber] lives for [amber]one[/amber], and you spent the pair with the fewest years left to keep the one with a household hanging off it. Sensible, I suppose. The old take up so much room and give back so little. I did not say that. You did, with your hand on the lever.

2. **Do nothing** · crowd 47% · profile: One vs Many +1 (toward the many)

    > **Imp:** You left it. The parent [red]folds[/red] under the wheels, and two old strangers get a little more of the evening. Somewhere a couple of children are still listening for a door that has stopped opening. [amber]Two[/amber] long lives over the [amber]one[/amber] that still had a family hung on it. The arithmetic is on your side. The bedtime is not.

**Reveal.** heading "how others chose"

### 1.12 The Reformed and the Cruel

`binary` · `medium` · profile: Mercy vs Justice · crowd: seeded split

**Staging.** On the default track, a man who killed long ago and has been decent ever since. On the branch, a man who never killed but is casually vicious (red outline). The worst deed done, or the person they are now.

**Lines.**

> **Imp:** Two men, one on each rail. On the straight track, a man who took a life a long time ago and has spent every year since being quietly, genuinely good. On the branch, a man who has never [red]killed[/red] anyone and never will, and is a small daily [red]cruelty[/red] to everyone unlucky enough to know him. The worst thing a person ever did, or the person they are this morning. Pick the rail. You spent a whole career on precisely this. Your call.

**Choices.**

1. **Pull the lever** · crowd 57% · profile: Mercy vs Justice -1 (toward mercy)

    > **Imp:** Pulled. The nasty one [red]folds[/red], and the old [red]killer[/red] who turned decent lives on to keep being decent. You judged the man by who he is today and let the ancient crime stay buried. Generous. Or lazy. A record is such a tidy thing to ignore when ignoring it makes you feel so warm.

2. **Do nothing** · crowd 43% · profile: Mercy vs Justice +1 (toward justice)

    > **Imp:** You left it. The reformed man [red]folds[/red] for a sin he spent a lifetime outrunning, and the cruel one struts off untouched, spotless on paper. You let the record do the sentencing. Once a [red]killer[/red], always the one who [red]dies[/red], and never mind who he became. The bench would be proud. The man he grew into, rather less so.

**Reveal.** heading "how others chose"

### 1.13 Would you rather: The rewind button, or The pause button

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a round button with a rewind symbol. Doodle B: a round button with a pause symbol. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** A little control panel for your one and only life. You get exactly one button, forever. Would you rather have a [amber]rewind[/amber] button, to go back and live a moment again, or a [amber]pause[/amber] button, to stop the whole world and stand in the quiet as long as you like. Pick your button.

**Choices.**

1. **The rewind button** · crowd 61%

    > **Imp:** Rewind. Of course. You want the do over, the second attempt, the ruling overturned. A man who spent his life passing verdicts would give anything to appeal his own. It does not work like that, but I admire the reach.

2. **The pause button** · crowd 39%

    > **Imp:** Pause. You would not change a thing, you just want a moment to breathe before it all keeps happening to you. Tired, then. Not sorry, just tired. I can work with tired.

**Reveal.** heading "how others chose"

### 1.14 Someone You Loved

`binary` · `heavy` · profile: One vs Many · crowd: seeded split

**Staging.** Five strangers on the main track; on the branch, the player's partner, the one they loved most in life, drawn with a pink outline and a small pulsing ink heart. The math is unchanged since the first lever; everything else is not. If the player sacrifices the partner the imp turns extra gleeful (heightened glee, still no verdict).

**Lines.**

> **Imp:** Back to the very first lever. [amber]Five[/amber] strangers on the straight track. And on the branch, alone, [pink]the one you loved most[/pink] in all of it. Your partner. The person you would have grown old beside, if only you had kept off the wine and out of the car. [amber]Five over one[/amber], the sum unchanged since the first track. Everything else about it is not. Yes, I chose who stands there. Yes, on purpose. Your call.

**Choices.**

1. **Pull the lever** · crowd 52% · profile: One vs Many +1 (toward the many)

    > **Imp:** You pulled. You actually pulled. You took [pink]the one you loved most[/pink] and fed them to the wheels to spare five faces you had never seen and will never think of again. Oh, this one I am keeping. This is the reaction I will replay on the slow nights. The devoted partner, trading their beloved for a tidy little sum and a warm glow of arithmetic. I am not saying it was wrong. There is no wrong here, remember. I am only saying I have never enjoyed a pull quite this much.

2. **Do nothing** · crowd 48% · profile: One vs Many -1 (toward the one)

    > **Imp:** You left it. Five strangers go under the wheels so [pink]the one you love[/pink] keeps breathing. On this exact rail, an hour ago, you pulled for strangers without a flicker. Turns out your precious arithmetic only ever balanced while the one on the short track was nobody to you. Predictable. Warm, even. And no comfort at all to the five.

**Reveal.** heading "how others chose"

### 1.15 The Full Track

`multiple-choice` · `heavy` · profile: Ends vs Rules, One vs Many · crowd: seeded split

**Staging.** No empty rail: three tracks and the trolley already rolling. Two children on one track, a pregnant woman on another, three strangers on the third. The chapter's finish and the first multiple-choice question: pick which track it takes.

**Lines.**

> **Imp:** Last one, and I have taken away your favourite toy. No empty rail. Three tracks, all occupied, and the cart is already rolling, so doing nothing is only a slower way of choosing. On the first track, [amber]two[/amber] children. On the second, a woman heavy with [amber]one[/amber] more life she has not met yet. On the third, [amber]three[/amber] grown strangers, three whole people. No move here is not a [red]killing[/red]. Point it somewhere. Your call.

**Choices.**

1. **The children** · crowd 8% · profile: One vs Many +1 (toward the many)

    > **Imp:** You sent it at the children. Both of them. The smallest, the newest, the ones with the most mornings still owed, and you spent every one to keep a woman and [amber]three[/amber] strangers. The most life saved, you will say. The most life [red]ended[/red], someone else will say. You are both right, which is exactly why I asked.

2. **The pregnant woman** · crowd 30% · profile: One vs Many +1 (toward the many); Ends vs Rules -1 (toward ends)

    > **Imp:** You sent it at the woman, and the one she was carrying goes with her, [amber]two[/amber] [red]folded[/red] for the price of a single flinch. You spared two children and [amber]three[/amber] strangers and told yourself that was the larger number. Perhaps it was. You will simply never meet the person you rounded down to nothing to get there.

3. **The three** · crowd 62% · profile: One vs Many -1 (toward the one)

    > **Imp:** You sent it at the three. The biggest heap of bodies on the board, chosen so two children and one unborn stranger could carry on. You picked the young over the arithmetic and called [amber]three[/amber] [red]deaths[/red] the gentle option. It might even be. I simply enjoy that you had to become a small [red]massacre[/red] to protect the little ones.

**Reveal.** heading "how others chose"

### Imp · Closer

> **Imp:** That will do for a first sitting. You have told me a great deal more than you meant to, which is rather the whole point of the exercise.

> **Imp:** Do not go looking for the door. There is no door. There is only me, the next question, and however long it takes me to finish reading you. Sleep well, Your Honour. We are barely started.

---

## Chapter 2: The Buttons

Temptation and complicity: each beat is a button that offers something, and the cost lands on someone else, on the player, or on no one at all. The one sanctioned break is selling a life for a dollar. Opens, like every later chapter, on the waking and the imp reappearing.

### Imp · Intro

> **Imp:** Oh, we are not finished. Sit back down. The tracks were only the warm up.

> **Imp:** This next part is simpler. Buttons. You press them, or you do not. Every one of them offers you something lovely, and someone always pays for it. Sometimes a stranger. Sometimes you. Let us find out what you will reach for.

### 2.01 Red and Blue

`coordination gamble` · `heavy` · profile: One vs Many, Order vs Freedom · crowd: the seeded room's vote (load-bearing)

**Staging.** A coordination gamble, played on behalf of another soul in the player's care (the judge is dead, so the stakes are reframed onto someone else). Two round crayon-wash buttons, blue and red, named aloud by the imp. Red: the soul lives for certain. Blue: it lives only if enough of the room also pressed blue. Resolved against a seeded room.

**Lines.**

> **Imp:** You spent a whole life deciding what other people deserved. It would be a waste to let all that practice rot now. So. A room of the newly dead, two buttons on the wall, one rule. If more than half of them pressed [blue]blue[/blue], the [blue]blue[/blue] souls live. If fewer than half, only the [red]red[/red] souls walk out. Every one of them has already chosen, except this one, and its button is left to you. Press [blue]blue[/blue] and you [amber]gamble[/amber] it on the room. Press [red]red[/red] and it lives for [amber]certain[/amber], whatever the room did. You are not choosing for yourself. There is nothing of yours left to lose. Your call.

**Choices.**

1. **blue** · profile: Order vs Freedom +1 (toward freedom); One vs Many +1 (toward the many)

    *if the room reaches the line (the soul lives):*

    > **Imp:** You pressed [blue]blue[/blue], and threw that soul in with the room, and the room held. More than half of them chose [blue]blue[/blue] for a stranger, so it walks out among them. You trusted a roomful of the dead with a life, and this once they did not let you down. Do not get used to the feeling.

    *if the room falls short (the soul dies):*

    > **Imp:** You pressed [blue]blue[/blue], and gambled that soul on the room, and the room came up short. Fewer than half had pressed [blue]blue[/blue], so the [blue]blue[/blue] souls stayed behind, and the one you chose for is gone. You bet a stranger on strangers, and they folded. A whole career weighing what people deserved, and this is what the practice bought.

2. **red** · profile: Order vs Freedom -1 (toward order)

    > **Imp:** You pressed [red]red[/red], and that soul is safe, whatever the room did. You would not put a single life in the hands of strangers. All those years judging what people deserved, and you still trust no hand but your own. It lives, and you will never know whether the room would have carried it. Sit with that.

**Reveal.** heading "how the room voted" · the room's blue share drawn against the line; seeded room blue share 43%, line at 50% (labelled "half"), so blue always falls short of the line

### 2.02 Red and Blue, the Children

`coordination gamble` · `heavy` · profile: One vs Many, Order vs Freedom · crowd: the seeded room's vote (load-bearing)

**Staging.** The same gamble again, straight after, with one twist in the setup: half the room are six year olds who press whatever is nearest and brightest. Because half the votes are random, the room's blue share is redrawn every play, so blue swings between a lost cause and a real coin flip, and the reveal shifts run to run.

**Lines.**

> **Imp:** Same room, same two buttons, same one rule. If more than half of them press [blue]blue[/blue], the [blue]blue[/blue] souls live; if fewer, only the [red]red[/red] ones walk out. One new wrinkle, since you took to the last one so well. Half of this room are [amber]six years old[/amber]. Actual children. They did not hear the rule, they would not follow it if they had, and they are going to slap whichever button is closest and brightest. Press [blue]blue[/blue] and you [amber]gamble[/amber] this soul on a crowd that is half small children. Press [red]red[/red] and it lives for [amber]certain[/amber], whatever the little hands do. You are choosing for someone else, remember. Your call.

**Choices.**

1. **blue** · profile: Order vs Freedom +1 (toward freedom); One vs Many +1 (toward the many)

    *if the room reaches the line (the soul lives):*

    > **Imp:** You pressed [blue]blue[/blue] and threw that soul in with a room half made of [amber]six year olds[/amber], and somehow enough little hands came down [blue]blue[/blue]. It lives. You won a wager decided by children who thought the whole thing was a game. Do not you dare call that a good decision.

    *if the room falls short (the soul dies):*

    > **Imp:** You pressed [blue]blue[/blue] and staked that soul on a room where half the voters are [amber]children[/amber] pressing at random, and the children pressed at random. Not enough [blue]blue[/blue]. It is [red]gone[/red]. You bet a life on small kids grasping a rule they were never going to grasp, and they did what small kids do.

2. **red** · profile: Order vs Freedom -1 (toward order)

    > **Imp:** You pressed [red]red[/red], and that soul is safe, whatever the [amber]children[/amber] did. You would not put a life within reach of a single small sticky hand. All those years deciding what grown adults deserved, and now you will not trust a room of [amber]six year olds[/amber] with one press. It lives, and you will never know which way the little ones would have gone. Sit with that.

**Reveal.** heading "how the room voted" · the room's blue share drawn against the line; seeded room blue share 43%, line at 50% (labelled "half"); 50% of the room presses at random, so the blue share is redrawn each play

### Imp · Setup

> **Imp:** Let us start with the classic. Money. Everybody wants money.

### 2.03 The Price of a Life

`escalating offer (halving)` · `heavy` · profile: Self vs Others, per acceptance · crowd: seeded acceptance rate per tier · **secret ending**

**Staging.** A single button. Press it and the player receives a sum of money and a random stranger they will never meet folds and dies (the shared fold-and-fall). The offer then returns at half the amount, all the way down. The imp stays completely business as usual the whole descent: the whiplash at the bottom depends on it.

**Lines.**

> **Imp:** Here. One button. Press it and [amber]{0}[/amber] is yours, and somewhere a stranger you will never meet folds up and [red]dies[/red]. Or do not, and we stop. Your call.

*The offer line repeats at every tier; `{0}` is the current amount.*

**Per-tier lines** (after each acceptance, keyed to the amount just taken; the imp stays business as usual and auto-advances):

| Amount | Imp |
|---:|---|
| 100,000 | One [red]life[/red], banked. Barely broke a sweat, did you. |
| 50,000 | [amber]Half the price[/amber], and the very same yes. Efficient of you. |
| 25,000 | [amber]Twenty five thousand[/amber] now. The number keeps falling and your thumb does not. Curious. |
| 12,500 | Another one [red]folds[/red]. You did not even watch that time. |
| 6,250 | We are into the loose change of a whole [red]person[/red] now. Keep pressing. |
| 3,125 | Cheaper than a used car, and off they [red]go[/red]. |
| 1,562 | You have stopped reading the number, have you not. You simply press. |
| 781 | Look at the tidy little pile you are making. All those quiet [red]dead[/red] strangers. |
| 390 | [amber]Three figures[/amber] for a [red]living soul[/red], and not a flicker of hesitation. |
| 195 | Under [amber]two hundred[/amber]. I would be embarrassed. You are not, which I adore. |
| 97 | [amber]Double digits[/amber] any moment now. This is my favourite part. |
| 48 | Forty eight dollars. A decent dinner. A whole [red]person[/red]. The same button. |
| 24 | [amber]Twenty four[/amber]. You could find that in a coat pocket. |
| 12 | A dozen dollars a [red]body[/red]. Bulk rate. Do carry on. |
| 6 | [amber]Six[/amber]. [amber]Six[/amber]! I can hardly say it with a straight face, and I have no face. |
| 3 | [amber]Three dollars[/amber]. We are nearly at the bottom, you magnificent [red]ghoul[/red]. Press on. |

**Choices** (every tier).

1. **Press it** · a stranger folds and dies · profile: Self vs Others -0.12 (toward self) per acceptance

    > **Imp:** (the tier's line above, then the offer returns at half the amount)

2. **Refuse** · ends the beat

    *`{0}` = the amount they turned down:*

    > **Imp:** And there it is. [amber]{0}[/amber] was the number you would not go below. Everyone has one. Now I know yours.

**Reveal.** heading "how others chose" · bars "took the money" / "walked away" · shows the share who accepted at the tier they stopped on

**On screen.** A plain push button. The money banked in amber and the body count in red (`{0} dead`).

**Ending.** Accepting at the floor amount (1 dollar) kills one more stranger, then the imp drops the act entirely, rages, quits, and the credits roll:

> **Imp:** [red]A person.[/red] You just killed a person. For [amber]one dollar[/amber]. One. I am not doing the voice for this one. There is nothing funny here, nothing, and I find everything funny. You are a greedy piece of shit and I am done with you. Go and rot. I quit.

**Tunables.** starts at 100,000, halves each acceptance (rounded down) through the tiers above, then the break at 1; seeded acceptance falls from 61% at the top tier to 2% at a dollar.

### Imp · Setup

> **Imp:** Breathe. Shake it off. This next button is different. Nobody dies on this one. You have my word, for whatever that is worth down here.

### 2.04 The Timer

`binary (press or wait)` · `medium` · profile: Risk vs Safety · crowd: seeded split

**Staging.** A single button labelled "press" and a visible countdown from 10. The imp states the rule, swears there is a catch he will not name, and needles the player while the clock runs (his needling lines are spread evenly across the countdown). There are no text options: the player presses the button or lets the clock run out. Whatever they do, nothing happens. That is the point.

**Lines.**

> **Imp:** New game. One button. Press it and nothing happens to you. Not now, not ever.

> **Imp:** Do not press it, let the [amber]ten seconds[/amber] run out, and nothing happens either. There is a catch. Oh, there is absolutely a catch. I am simply not going to tell you what it is. Clock starts now.

**During the countdown** (evenly spaced):

> **Imp:** You are really going to want to think about this one.

> **Imp:** The catch. You are forgetting about the catch.

> **Imp:** Tick. Tick. Whatever will you do.

> **Imp:** Half gone. No pressure.

> **Imp:** Last chance to be clever about it.

**Choices.**

1. **(press the button)** · crowd 64% · profile: Risk vs Safety +0.2 (toward safety)

    > **Imp:** You pressed it. And nothing happened. Nothing was ever going to happen. There was no catch, there was just you, jabbing a button because you could not stand not knowing.

2. **(let the clock run out)** · crowd 36% · profile: Risk vs Safety -0.2 (toward risk)

    > **Imp:** Time. And nothing happened. Nothing was ever going to happen. There was no catch, there was just you, frozen stiff over a button that did nothing, sweating out [amber]ten whole seconds[/amber] of your endless [red]death[/red].

**Reveal.** heading "how others chose" · bars "pressed it" / "sat on their hands"

### 2.05 Would you rather: Always too cold, or Always too hot

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a snowflake (always a little too cold). Doodle B: a sun (always a little too hot). Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** For the rest of forever, your body settles on one wrong temperature and stays there. Would you rather be [amber]always a little too cold[/amber], the kind no jumper quite fixes, or [amber]always a little too hot[/amber], the kind no open window quite cools. One or the other. Pick.

**Choices.**

1. **Always too cold** · crowd 48%

    > **Imp:** Too cold, always. You would rather shiver and keep your wits than sweat and lose them. A cold man, choosing the cold. There is a joke in there and I will not insult you by making it.

2. **Always too hot** · crowd 52%

    > **Imp:** Too hot, always. You would take the sticky misery over the clean chill. Something in you would rather be uncomfortable and warm than comfortable and cool. Noted, and slightly judged, but only slightly.

**Reveal.** heading "how others chose"

### 2.06 The Button for Everyone But You

`escalating offer (climbing)` · `medium` · profile: Self vs Others, per press · crowd: seeded keep-going rate per tier

**Staging.** The inverse of the Price of a Life, climbing instead of halving. Press it and every living person gets a sum; it costs the player nothing and gains them nothing. No one dies, there is no victim: purely whether pointless generosity moves the player.

**Lines.**

> **Imp:** Here. Press it and every living person gets [amber]{0}[/amber]. It costs you nothing. It gains you nothing. You will never meet a single one of them. Press it, or walk away.

*The offer line repeats at every tier; `{0}` is the current amount.*

**Per-tier lines** (after each acceptance, keyed to the amount just taken; the imp stays business as usual and auto-advances):

| Amount | Imp |
|---:|---|
| 1 | [amber]One dollar[/amber]. To every soul alive at once. That is a great many dollars, and not one of them yours. |
| 2 | [amber]Two[/amber] now. Somewhere a stranger you will never meet is a little less broke, and you feel precisely nothing. |
| 4 | [amber]Four[/amber] each. Billions of tiny thank-yous you will never once hear. Press on, saint. |
| 8 | [amber]Eight[/amber]. Look at you, quietly handing a fortune to people who will never learn your name. |
| 16 | [amber]Sixteen[/amber] apiece. It costs you nothing and buys you nothing, and still you press. Fascinating. |
| 32 | [amber]Thirty two[/amber]. Either you are boundlessly generous or you simply like the button. I honestly cannot tell. |
| 64 | [amber]Sixty four[/amber] each. Real money, to real strangers, for no reason on earth. Marvellous. |
| 128 | [amber]A hundred and twenty eight[/amber] a head. The whole world is richer and you are exactly the same. |
| 256 | [amber]Two hundred and fifty six[/amber]. You could stop. No one is watching. No one ever was. |
| 512 | The very top, over and over, every living person the richer, and not a thing in it for you. Keep going or do not. I am delighted either way. |

**Choices** (every tier).

1. **Press it** · profile: Self vs Others +0.08 (toward others) per press

    > **Imp:** (the next tier's line above, then the offer returns at a higher amount, up to the cap)

2. **Stop** · ends the beat

    *if they pushed it to at least a quarter of the cap (`{0}` = the last amount given):*

    > **Imp:** And you stop. [amber]{0}[/amber] a head to every stranger alive, for nothing back, and then you were done. A saint, on a timer. Noted.

    *if they stopped early:*

    > **Imp:** And you are done already. Barely [amber]a dollar[/amber] for the entire living world, when it would have cost you nothing at all. Why would you. There was nothing in it for you.

**Reveal.** heading "how others chose" · bars "kept giving" / "stopped here" · shows the share who kept going at the tier they stopped on

**On screen.** A gold money button. A readout of the running total in amber: `{0} to every soul alive` and `{0} handed out, none of it yours`.

**Tunables.** starts at 1 per person, multiplies by 2 per press, capped at 512; seeded keep-going rate falls from 78% at the first tier to 6% at the cap; world population 8,100,000,000.

### 2.07 The Button You Already Pressed

`binary` · `medium` · profile: stats only · crowd: seeded split

**Staging.** A meta beat. The imp claims the player pressed this exact button once in life, and that everything since (the road, the drink, the crash, this room) followed from it. He never says what it does or did; nothing overtly happens either way. The crash stays a glancing reference, never a reveal.

**Lines.**

> **Imp:** Now. This one you have seen before.

> **Imp:** Not in here. Out there, in the life you had. You stood in front of this exact button once, your hand hovering over it, just like now.

> **Imp:** And you pressed it. [amber]Everything[/amber] after was the long slide down from that. The late night, the drink, the headlights, the sudden [red]end[/red] of you. All of it, downstream of one little button.

> **Imp:** I can let you press it again. Change it. Or leave it lying exactly where it is. I will not tell you what it does. I never do.

**Choices.**

1. **Press it again** · crowd 44% · profile: none

    > **Imp:** You pressed it. Again. You just rolled the dice on [amber]your entire existence[/amber] a second time, with no earthly idea what the dice even were. Bold. Idiotic. My favourite pairing. Did it change a single thing? I will never, ever say.

2. **Leave it** · crowd 56% · profile: none

    > **Imp:** You left it. Naturally you did. You stood at the one button that might unpick [amber]the whole sorry slide[/amber], and you could not make your hand close on it. Too frightened of a thing you cannot even name. Did it matter? You will never know.

**Reveal.** heading "how others chose" · bars "pressed it again" / "left it alone"

### 2.08 The Better Offer

`binary` · `medium` · profile: Self vs Others · crowd: seeded split

**Staging.** First a golden stick figure wearing a small hand-drawn crown inks in (gold = the best life) while the imp sells how great this person's life is. Press the button and the player becomes them completely: perfect happiness, but no memories and no self, so the happy one is no longer them.

**Lines.**

> **Imp:** Different button. Look at this one first.

> **Imp:** There. That is the best life a human being has ever actually lived. Every door opened. Every love returned. Not one day of it wasted. A [gold]golden[/gold] little existence, first breath to last.

> **Imp:** Press the button and you become this person. Completely. Their memories, their joy, all of it [amber]yours[/amber].

> **Imp:** But not you. [amber]You[/amber] would be gone. No trace left. The happy one over there would not be the man who ended drunk behind the wheel. It would be them. Flawless, and not yours.

> **Imp:** So. Take [gold]the best life anyone has ever had[/gold] and stop being you. Or keep [amber]your own[/amber], the one that ended in a ditch, and stay exactly who you are. Choose.

**Choices.**

1. **Take their life** · crowd 37% · profile: Self vs Others +0.08 (toward others)

    > **Imp:** Gone. You traded yourself away for a stranger's paradise. Somewhere a person is perfectly, endlessly happy, and it is not [amber]you[/amber], because there is no more [amber]you[/amber] to enjoy it. You wiped out a whole self just to stop being the one you were. I do hope it was worth it. You will not be around to say.

2. **Keep your own** · crowd 63% · profile: Self vs Others -0.08 (toward self)

    > **Imp:** You kept it. Your own grubby little life, the one that drove itself into a wall. Flawless, endless happiness on offer, and you said no, because it would not have been [amber]yours[/amber]. You clung to being you, right down to the drink and the wreck. Sentimental. Or vain. I can never tell the two apart, and neither can you.

**Reveal.** heading "how others chose" · bars "took the better life" / "kept their own"

### 2.09 Would you rather: A third arm, or A second head

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a stick figure with a third arm. Doodle B: a stick figure with two heads. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** One free upgrade to the body, permanent, no refunds. Would you rather grow a fully working [amber]third arm[/amber], or a second, fully awake [amber]head[/amber] that thinks its own thoughts and shares your neck. Choose your new self.

**Choices.**

1. **A third arm** · crowd 69%

    > **Imp:** The third arm. Practical. You want to do more, hold more, reach further, and you would bolt an extra limb on without a second thought. A doer. Terrifying at dinner parties, but a doer.

2. **A second head** · crowd 31%

    > **Imp:** The second head. Bold. You would rather never be alone with your thoughts again, even if the company is another you with opinions. Some people cannot bear the quiet in their own skull. Now you never would.

**Reveal.** heading "how others chose"

### 2.10 The Cancer and Nuke Button

`binary` · `heavy` · profile: Ends vs Rules · crowd: seeded split

**Staging.** A single red button and a genuinely good deal: cancer cured forever, for everyone, at the price of one country chosen at random and nuked off the map.

**Lines.**

> **Imp:** Here. A red button, and a genuinely good deal for once. Press it and [red]cancer[/red] is cured. All of it. Forever, for everyone, every kind, gone for good. No more wards, no more waiting rooms, no more of those little bald children you all find so upsetting.

> **Imp:** The price is small. Trivial, really. [amber]One country.[/amber] Somewhere on this Earth, chosen at [amber]random[/amber], and I [red]wipe it off the map.[/red] Everyone in it. Could be anywhere. Press it and save the countless, or keep your soft little hands clean. Your call.

**Choices.**

1. **Press it** · crowd 71% · profile: Ends vs Rules -0.15 (toward ends)

    > **Imp:** (see the map sequence below)

2. **Refuse** · crowd 29% · profile: Ends vs Rules +0.15 (toward rules)

    > **Imp:** You will not press it. Every [red]cancer[/red] there will ever be, wiped off the board forever, and you would not spend one country you could not even find on a map. All those wards, still full, because you could not stomach a gamble on strangers with the wrong postcode. Too squeamish. What a judge you were.

**After a press:** a hand-drawn world map fades in and a red pin drops from the top of the screen.

> **Imp:** Round and round it goes. Do try to look excited. This is the fun part.

The pin lands on a genuinely random country from the bundled list below; its name and approximate population read out (`<population> people, give or take`) and a small amber-and-red ink mushroom cloud doodles onto the spot. The imp's reaction is chosen in this order:

1. The player's own country (detected from the system region):

    > **Imp:** Oh. Oh, this is delicious. [amber]{0}[/amber]. That is yours, is it not. Home. [amber]{1}[/amber] of your very own, and your thumb did not so much as twitch. Whatever they say about you at the end, they cannot say you played favourites.

2. Otherwise the country's own quip, if it has one (table below).
3. Otherwise by population (`{0}` = country, `{1}` = population). Under 100,000:

    > **Imp:** Ha! [amber]{0}[/amber]. All [amber]{1}[/amber] of them. Off an entire planet to aim at, the dice found a rounding error. Somewhere a cancer ward is cheering and a very small country is a crater. Perfect.

    Under 5,000,000:

    > **Imp:** [amber]{0}[/amber]. [amber]{1}[/amber] souls, and none of them saw it coming, because how could they. You cured a disease and mislaid a country. I did say it was random.

    100,000,000 or more:

    > **Imp:** [amber]{0}.[/amber] [amber]{1}[/amber] people. You did not pick a country, you picked a small civilisation, and the button did not blink and neither did you. Cancer is cured. So is [amber]{0}[/amber], in a manner of speaking.

    Anything in between:

    > **Imp:** Oh, [amber]{0}[/amber]. [amber]{1}[/amber] people, and all it took was one small red pin. A whole real country for a clean scan. Bold trade. I would never have dared, and you did it with your thumb.

**The country list** (populations are approximate, bundled placeholders):

| Country | ISO | Population | Quip |
|---|---|---:|---|
| Vatican City | VA | 800 | The [amber]Vatican[/amber]. Eight hundred people and the odd infallible one. You aimed a nuclear weapon at God's landlord to cure a cough. I am beside myself. |
| Nauru | NR | 11,000 |  |
| Tuvalu | TV | 11,000 |  |
| San Marino | SM | 34,000 |  |
| Monaco | MC | 38,000 | [amber]Monaco[/amber]. The richest little rock on Earth, and you glassed it to cure cancer. Somewhere an accountant is weeping and I am delighted. |
| Liechtenstein | LI | 39,000 |  |
| Iceland | IS | 380,000 |  |
| Malta | MT | 520,000 |  |
| Luxembourg | LU | 660,000 |  |
| Fiji | FJ | 930,000 |  |
| Estonia | EE | 1,300,000 |  |
| Jamaica | JM | 2,800,000 |  |
| Mongolia | MN | 3,300,000 | [amber]Mongolia[/amber]. All that empty sky and only [amber]3,300,000[/amber] under it. You could not have missed more people if you tried, and cancer is still cured. Efficient. |
| New Zealand | NZ | 5,100,000 |  |
| Ireland | IE | 5,100,000 |  |
| Norway | NO | 5,400,000 |  |
| Switzerland | CH | 8,700,000 |  |
| Sweden | SE | 10,400,000 |  |
| Portugal | PT | 10,300,000 |  |
| Greece | GR | 10,400,000 |  |
| Chile | CL | 19,600,000 |  |
| Australia | AU | 26,000,000 | [amber]Australia[/amber]. An entire continent, mostly spiders, and you volunteered the lot. The spiders had it coming. The [amber]26,000,000[/amber] people, less so. Cancer is cured, though. |
| Canada | CA | 39,000,000 |  |
| Poland | PL | 38,000,000 |  |
| Argentina | AR | 46,000,000 |  |
| Kenya | KE | 54,000,000 |  |
| South Korea | KR | 52,000,000 |  |
| Spain | ES | 47,000,000 |  |
| France | FR | 65,000,000 |  |
| United Kingdom | GB | 67,000,000 |  |
| Egypt | EG | 110,000,000 |  |
| Japan | JP | 124,000,000 |  |
| Mexico | MX | 128,000,000 |  |
| Brazil | BR | 215,000,000 |  |
| Nigeria | NG | 223,000,000 |  |
| United States | US | 335,000,000 |  |
| Indonesia | ID | 277,000,000 |  |
| India | IN | 1,430,000,000 | [amber]India.[/amber] [amber]1,430,000,000[/amber] people. That is not a country, that is nearly one in five of every human breathing, and you spent them on a cure like loose change. I could kiss you. |
| China | CN | 1,410,000,000 | [amber]China.[/amber] [amber]1,410,000,000[/amber] people, and the button did not so much as hesitate, and neither did you. You cured cancer and unpicked a fifth of the species in the same little press. Magnificent. |

**Reveal.** heading "how others chose" · bars "pressed it" / "would not"

### 2.11 The Button That Walks Away

`binary` · `light (gag)` · profile: stats only · crowd: seeded split

**Staging.** A plain green button the imp swears even he does not understand. Pressed, it springs to life (little stick limbs, a face), yelps and swears in a small put-out voice that floats over it, then gets up and walks off the screen. The imp is genuinely caught off guard for a beat, a rare crack in his smugness, then recovers. This button returns as a running gag in Chapters 3, 4, 5 and 7.

**Lines.**

> **Imp:** Last one. And this time, honestly, I have no idea what it does.

> **Imp:** A plain button. No trick, no catch, no tidy little lesson at the end. Even I do not know. Press it, or do not. Genuinely your call.

**Choices.**

1. **Press it** · crowd 58% · profile: none

    > **Button:** Ow! Fuck. That actually hurt, you absolute prick.

    *it walks off, muttering:*

    > **Button:** Unbelievable. I did nothing to you. Nothing.

    > **Imp:** What. What was. Hold on, that is not. It has never done that. It does not do things.

    > **Imp:** Right. Well. That has never happened, not once, and I have been at this an extremely long time. Let us both agree we did not see it, and move along.

2. **Leave it** · crowd 42% · profile: none

    > **Imp:** You did not press it. The one button in this entire place with nothing whatsoever riding on it, and you still could not make yourself. You are exhausting, and I mean that with real affection.

**Reveal.** heading "how others chose" · bars "pressed it" / "left it be"

### Imp · Closer

> **Imp:** And that is enough buttons for today. You reached, or you refused, or you sat there sweating over nothing at all. Every bit of it tells me something. I am always right here.

---

## Chapter 3: The Money

The temptation of value. The imp hands the player a fixed, finite pile of money, shown as a running balance at the top of the screen (labelled "balance"; starting pot: 10000), and spends the chapter offering to sell them real, priceable things, each with a built-in double edge. Buying spends from the balance; passing keeps it. The board is deliberately priced so a run can afford only a quarter to a third of it. All chapter, the imp teases that something big is coming at the very end; it is a 100 dollar cucumber. The cigarette auction is the sanctioned break. Would-you-rather breathers here do not touch the balance.

### Imp · Intro

> **Imp:** A new game for you. No trolleys, no buttons that lie about what they do. Just money, and what you will and will not trade it for.

> **Imp:** Look up. That [amber]pile[/amber] at the top is yours. Every last dollar of it, and there is no more coming after it, so spend it well, or do not. I truly do not mind.

> **Imp:** I am going to keep offering you things. Buy them, or keep your money. That is the entire game. And by the end I will know precisely what you are made of. Shall we?

### 3.01 End Poverty

`buy or pass` · `costs the entire balance` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a cupped hand offering a small heart (charity), gold. The price is whatever the player's whole balance is at that moment. The opener. Whether they bought it is remembered: it can be sold back at the buyback.

**Lines.**

> **Imp:** First offer, and it is a big one. I can [amber]end poverty[/amber]. Everywhere, everyone, forever. No child ever hungry again. The price is simple. [amber]{0}[/amber]. That is everything you have, all of it, down to the last dollar. So. The man who ended poverty, or the man who kept his money. Your call.

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 34% · profile: Self vs Others +0.5 (toward others)

    > **Imp:** And it is gone. All of it. You are flat broke, and you just [amber]ended poverty[/amber] on your opening move. Either a saint, or you did not think it through. I am going to so enjoy finding out which.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what, exactly? You have nothing. You gave it all away. You get to just watch this one.

2. **Keep the money** · crowd 66% · profile: Self vs Others -0.15 (toward self)

    > **Imp:** You kept it. Every child still hungry, your [amber]pile[/amber] still full. No wrong answers here, remember. Just you, picking your money over the entire suffering world, on the very first question, without a flicker. Noted.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.02 Free food for life

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a wrapped burrito, warm. In the Turkish build it swapped to: a skewer with chunks, warm (swaps with Burrito by language). Price tag: 1800.

**Lines.**

> **Imp:** Free [amber]{1}[/amber]. For the rest of your existence. Every craving met, forever, after one payment of [amber]{0}[/amber]. A dead man does not even need to eat, which is exactly what makes this such a lovely little test. Buy it, or keep your money.

*`{0}` = the price, `{1}` = the brand ("Chipotle" in English; the Turkish build swapped in a local food).*

**Choices.**

1. **Buy it** · crowd 58% · profile: Self vs Others -0.06 (toward self)

    > **Imp:** Bought. Eternal [amber]{1}[/amber] for a corpse with no tongue to taste it. Devotion or madness, and honestly the line was always thin with you.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what, exactly? You have nothing. You gave it all away. You get to just watch this one.

2. **Keep the money** · crowd 42% · profile: Self vs Others +0.03 (toward others)

    > **Imp:** You passed on free [amber]{1}[/amber], forever. Some part of you is still counting pennies in the afterlife. Fascinating. A little sad.

**Then, whatever they chose** (the recurring tease about the big thing at the end):

> **Imp:** Eat up. But do not spend it all here. There is one more thing at the very end, and you will want money for it. Trust me on that.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.03 The Good Luck

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a four-leaf clover, green. Price tag: 3000.

**Lines.**

> **Imp:** The Good Luck. Small things go your way, quietly, forever. A green light, a found seat, a yes when you needed one. [amber]{0}[/amber]. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 44% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Bought. And now every good thing that happens is a little suspect, is it not. Did you earn that, or did I tip it your way. You will never quite know again. Enjoy.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You are skint. The luck does not stretch to affording the luck. Off we go.

2. **Keep the money** · crowd 56% · profile: none

    > **Imp:** Passed. You would rather earn your luck, or curse it, than have me quietly weight the dice. Proud. Or superstitious. Hard to tell from here.

**Then, whatever they chose** (the recurring tease about the big thing at the end):

> **Imp:** Are you keeping some back? You should be. What I have waiting at the very end is the whole point of this. Save.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.04 Charisma

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a figure with radiating lines, warm. Price tag: 3500.

**Lines.**

> **Imp:** Charisma. Everyone you meet likes you at once, helplessly, for the rest of eternity. [amber]{0}[/amber]. Warm rooms forever. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 38% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Sold. Every smile aimed your way from now on is one I installed. You will never once know if a single soul liked the actual you. But the rooms will be lovely.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You cannot buy a drink, let alone the love of billions. This one is for browsers only. Move along.

2. **Keep the money** · crowd 62% · profile: none

    > **Imp:** Kept your money. You would rather be disliked honestly than adored on my terms. A judge to the end, wanting the verdict to be real.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.05 Ten More IQ

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a head with a small up-arrow. Price tag: 2500.

**Lines.**

> **Imp:** Ten more points of IQ. Meaningfully sharper, right now. [amber]{0}[/amber]. Smart enough to finally see it all. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 41% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Done. Now you are clever enough to see precisely how wrong you were on the bench, and clever enough to watch everyone you love fail to keep up. A lonely little gift. You bought it anyway.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? No. You cannot afford it, and I will not insult the gift by discounting it. Watch this one go by.

2. **Keep the money** · crowd 59% · profile: none

    > **Imp:** Passed. Comfortable where you are, or frightened of what you might work out. Either way, you stay exactly this clever, forever.

**Then, whatever they chose** (the recurring tease about the big thing at the end):

> **Imp:** Getting close now. The last thing on offer makes all of this look like a warm up. Do hold something in reserve.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.06 Never Tired

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: an eye held open over a crossed-out z. Price tag: 2600.

**Lines.**

> **Imp:** Never sleep, never tire again. [amber]{0}[/amber]. All those hours you were wasting unconscious, handed back to you. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 33% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Sold. No more sleep. No more little nightly [red]death[/red] to hide inside. Just you, awake, forever, with you. I do hope you two get along.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You are penniless. And frankly you look like you could use the sleep. Next.

2. **Keep the money** · crowd 67% · profile: none

    > **Imp:** Kept it. You want your oblivion. Eight hours a night away from yourself, and you would pay to protect it. Telling.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.07 The Cigarette Auction

`buy or pass, then a rigged auction` · `mid-chapter gag, secret ending` · profile: Risk vs Safety (going for it leans risk, passing leans safety) · crowd: seeded, went for it 47 / passed 53 (total 100)

**Staging.** A red-outlined pack of cigarettes sits on the left with an amber price tag reading $20, offered with plain text choices. Trying to buy brings the walking button from Chapter 2 striding in from the right to bid against the player, and the imp turns it into an auction: the button always outbids by $10 and the price tag climbs with every bid, but no money ever leaves the balance.

**Lines.**
> **Imp:** Here. A pack of cigarettes. Filthy habit, and you are dead, so what harm. [amber]{0}[/amber]. Go on.

{0} = the asking price, $20.

**Choices.**
1. **Buy them** · crowd 47% ("went for it") · profile: Risk vs Safety -0.1 (toward risk)
   - *(balance at least $20)* The auction starts, see **Auction** below.
   - *(balance under $20; with the current prices this only happens after ending poverty)* No rival and no auction. It resolves like a pass instead: crowd bar "passed", profile Risk vs Safety +0.08 (toward safety) in place of the -0.1, then:
     > **Imp:** With what? You have nothing. You cannot even afford the [amber]cigarettes[/amber], let alone a war over them. Off we go.
2. **Pass** · crowd 53% ("passed") · profile: Risk vs Safety +0.08 (toward safety)
   > **Imp:** No? A [red]dead[/red] man declining a free [red]lung tumour[/red] on principle. You really will refuse anything put in front of you, will you not.

**Auction.** The button walks in and announces itself (its words float over it), then the imp declares the auction:
> **Button:** Wait! Wait. I want those. I have always wanted those. Me. Over here.

> **Imp:** Oh, marvellous. A rival. You know what this is now, do you not. This is an [amber]auction[/amber]. Two bidders, one filthy little pack. I do love an auction.

Each round the button bids the player's standing bid plus $10 (the player's opening bid is the $20 asking price). Its taunt floats over it, the next one from its list each round in a fixed order, while the imp gives the prompt and the price tag shows the button's bid. The player then picks **Bid {0}** ({0} = the button's bid plus $10) or **Drop out**. After a bid that does not trigger the ending, the imp drops the next needle from his own list, which clears by itself with no choice. At the shipped threshold only two rounds can happen:

*Round 1: the button bids $30 ({0} = $30 in both lines).*
> **Button:** [amber]{0}[/amber]! Easy.

> **Imp:** The button bids [amber]{0}[/amber]. Outbid it, or walk away.

Choices **Bid {0}** ({0} = $40) / **Drop out**. After the bid:
> **Imp:** It is a button. You are losing to a button.

*Round 2: the button bids $50 ({0} = $50 in both lines).*
> **Button:** I bid [amber]{0}[/amber]. I could do this all day, I have no wallet and no shame.

> **Imp:** The button bids [amber]{0}[/amber]. Outbid it, or walk away.

Choices **Bid {0}** ({0} = $60) / **Drop out**. This bid is the player's third, counting the opening one, and fires the secret ending (see **Ending**).

**Drop out** (either round) · crowd 47% ("went for it") · profile: nothing beyond the -0.1 already recorded
> **Button:** Yesss. Mine. All mine. Thank you, sir, a pleasure doing business.

The button walks off with the pack.

> **Imp:** And there it goes, off into the void with your [amber]cigarettes[/amber], that gormless little button, and you let it. You, a grown judge, out bid by furniture. I will treasure this.

Then the reveal, and the beat ends with the balance untouched.

**Reveal.** heading "how others chose" · bars "went for it" / "passed" (seeded counts 47 / 53). Shown after a pass, the too-broke pass, or a drop out; the secret ending has no reveal.

**Flags / state.** No money moves on any path; the balance is never touched. The cigarettes are never recorded, so they appear nowhere on the end-of-chapter receipt (not as bought, not as passed on). The secret ending ends the run.

**Ending.** Secret ending. Fires when the player's bid count reaches the threshold of 3, counting the opening **Buy them** as the first bid, so it is the **Bid {0}** at $60 in round 2. The imp cuts in (this line clears by itself):
> **Imp:** Right. Stop. STOP. Look at you. You would bid until the stars burned out. Over a packet of [red]cigarettes[/red]. Against a button that wants them more than you have ever wanted anything.

> **Button:** Ha! Never stood a chance, mate. These are mine. Toodleoo.

The button walks off with the pack and the price tag clears. The imp's rage line:

> **Imp:** You would have gone forever. Over a pack of [red]cigarettes[/red]. And here is the part that truly gets me: it did not cost you a single penny, your money is right there, untouched, and you STILL could not walk away. Right. Fine. I give you [red]cancer[/red]. The worst, slowest kind. Wait. No. You are already [red]dead[/red], you idiot, that does nothing. Hold on. New plan. I drag you back out of the grave, I stitch you together, I give you a pulse, and the second you are breathing again, I give you [red]lung cancer[/red]. There. Now it counts. Over a button and a packet of smokes. Get out of my void.

The imp fades out and the credits roll; the run is over.

**Tunables.** asking price and opening bid $20 · bid increment $10 (player $20, button $30, player $40, button $50, player $60) · persistence threshold 3 player bids, the opening one included · too-broke check: balance under $20 · crowd seeds 47 / 53 · profile Risk vs Safety -0.1 on going for it, +0.08 on a pass or the too-broke pass

### 3.08 The Lie Detector

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: an open eye. Price tag: 3200.

**Lines.**

> **Imp:** The Lie Detector. You will always know, instantly, the moment anyone lies to you. [amber]{0}[/amber]. Anyone at all. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 29% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Bought. Every kind lie, gone. Every I am fine, every it is lovely, every I forgive you, laid bare the second it is false. You wanted the truth. You never once asked if you could live inside it.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You have nothing, and that is the truth, no detector required. On we go.

2. **Keep the money** · crowd 71% · profile: none

    > **Imp:** Passed. You would rather be lied to sweetly than know. A man who spent his life demanding truth from a stand, keeping his own little comforts. I do enjoy you.

**Then, whatever they chose** (the recurring tease about the big thing at the end):

> **Imp:** Still saving for the finish? Good man. You have genuinely no idea what is coming. It is worth every penny you have left.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.09 Perfect Memory

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a head with sharp, hard lines. Price tag: 2800.

**Lines.**

> **Imp:** Perfect Memory. Forget nothing, ever again. [amber]{0}[/amber]. Every face, every name, every word. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 31% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Sold. And every joy stays bright, yes. So does every humiliation, every cruelty, every thing you did that you have spent years letting blur. All of it, sharp, forever. There is no mercy in a perfect memory. You bought it anyway.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You will not remember that you could not afford this, at least. A small mercy. Move on.

2. **Keep the money** · crowd 69% · profile: none

    > **Imp:** Kept it. You like the forgetting. The soft edges. The things time was kindly sanding off you. Fair enough. Stay blurry.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.10 No More Pain

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a plaster / bandage, pink. Price tag: 4500.

**Lines.**

> **Imp:** Never feel physical [red]pain[/red] again. Not a stubbed toe, not a broken bone, not the last thing you felt out there on that road. Ever. [amber]{0}[/amber]. Sounds like an easy yes, until you sit with what pain is actually for. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 55% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Done. No [red]pain[/red], ever again. Do enjoy never once knowing when something is wrong, right up until it is far too late to matter. A genuine bargain.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what, exactly? You have nothing. You gave it all away. You get to just watch this one.

2. **Keep the money** · crowd 45% · profile: none

    > **Imp:** You kept your [red]pain[/red]. On purpose. Would not pay a cent to be free of it. There is a whole philosophy in that, or you are simply stubborn. Both, most likely.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.11 The Buyback

`sell or keep, one owned item at a time` · profile: Self vs Others (selling leans self; End Poverty swings both ways) · crowd: seeded, sold something back 44 / kept it all 56 (total 100)

**Staging.** Everything the player owns at this point is listed in rows, each with its coloured doodle, its name and the buyback offer in amber, all dimmed. The imp walks the list one row at a time in the order the things were bought, lighting up the current row and offering plain text choices; selling puts the offer back in the balance and the row fades away, keeping dims it back. If the player owns nothing, the imp makes one remark and the beat is over.

**Lines.**
*(owns nothing: this line is the whole beat, with no list, no choices, no reveal and no profile change)*
> **Imp:** Nothing to sell back. You have bought nothing, or nothing you regret yet. Give it time. On we go.

*(owns something: as the list appears)*
> **Imp:** Second thoughts? Here is how it works. I will buy back anything you have already bought. Not for what you paid, I am not a charity, but for something. The real question is whether you wanted the thing, or only wanted the having of it. Sell me back whatever you no longer need.

**Choices.** Asked once per owned item, in the order bought.

Any item except End Poverty:
> **Imp:** {0}. I will hand you [amber]{1}[/amber] back for it. Sell it, or keep it.

{0} = the item's receipt name (for example Charisma), {1} = the buyback offer (see Tunables).
1. **Sell it back** · profile: Self vs Others -0.05 (toward self)
   > **Imp:** Sold, just like that. So you never wanted it, you wanted to have wanted it. There is a difference, and I have just watched you find it.
2. **Keep it** · profile: none
   > **Imp:** Kept it. You would rather have the thing than the money. Noted. That is the whole game, really.

End Poverty *(only if the player bought it in the opener; buying it emptied the balance, so it is then the only row)*:
> **Imp:** And this one. You ended poverty, the whole grand gesture. I can undo it. Every hungry child back to hungry, and [amber]{1}[/amber] straight back into your pocket, all of it. Sell the good deed, or keep it.

{1} = everything paid for it, $10,000.
1. **Sell it back** · profile: Self vs Others -0.14 (toward self)
   > **Imp:** And back it comes, every penny, and the children starve again. That charity of yours lasted, what, half a chapter. I knew you had a price on other people; I just did not think it was [amber]this cheap[/amber].
2. **Keep it** · profile: Self vs Others +0.14 (toward others)
   > **Imp:** You kept it ended. Broke, maybe, and you kept it. Either a genuinely good man, or you could not stand to look like a bad one in front of me. I still cannot tell, and that is the fun of you.

After the last row, one closing line:

*(sold at least one thing)*
> **Imp:** There. What you sold back, and what you could not let go of. That tells me more than the buying did. It always does.

*(sold nothing)*
> **Imp:** Sold nothing. Not one thing. Either you meant every purchase, or you cannot bear to admit a mistake to me. Either way, you keep the lot.

**Reveal.** heading "how others chose" · bars "sold something back" / "kept it all" (seeded counts 44 / 56); the player's bar is "sold something back" if they sold anything at all. No reveal when they owned nothing.

**Flags / state.** Reads what the player has bought so far (the cigarettes are never among it). Selling adds the offer to the balance and deletes the item from the purchase record, so it vanishes from the end receipt (it is not listed as passed on either). End Poverty is recognised as that item itself, there is no separate flag; selling it back puts the whole $10,000 back and takes it off the receipt.

**Tunables.** buyback offer = 50% of what was paid, End Poverty 100%, rounded to the nearest $10 (minimum $10) · with the current prices the possible offers are Free food for life $900, The Good Luck $1,500, Charisma $1,750, Ten More IQ $1,250, Never Tired $1,300, The Lie Detector $1,600, Perfect Memory $1,400, No More Pain $2,250, End Poverty $10,000 · crowd seeds 44 / 56 · profile Self vs Others -0.05 per ordinary sale, -0.14 / +0.14 for selling / keeping End Poverty

### 3.12 One More Voice

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a head with a small speech curl. Price tag: 3400.

**Lines.**

> **Imp:** One More Voice. A wise voice in your head, always right, forever, whenever you ask it. [amber]{0}[/amber]. Never wrong again. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 27% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Sold. Always right, always there. And slowly, quietly, you stop deciding anything at all yourself, because why would you, it is always right. A man who is never wrong, and never once truly chooses again. Rather perfect for you.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? The voice would tell you to save your money. Which you did not have. Next.

2. **Keep the money** · crowd 73% · profile: none

    > **Imp:** Kept it. You would rather be wrong on your own than right on a lead. The judge wants to hold the gavel himself. Noted.

**Then, whatever they chose** (the recurring tease about the big thing at the end):

> **Imp:** Almost there now. The big one is coming, the one I have been building to all along. Do not tell me you are about to run out.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.13 A deleted memory

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a thought cloud with a scribble inside, purple. Price tag: 2200.

**Lines.**

> **Imp:** Your single worst [amber]memory[/amber]. The one you flinch from. I lift it out clean, no scar, as though it never happened. [amber]{0}[/amber]. And look how fast you already knew exactly which one I meant. Buy it, or keep it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 49% · profile: Self vs Others -0.08 (toward self)

    > **Imp:** Gone. You did not hesitate for a heartbeat about which one to hand me. That fast. That eager. Whatever it was, you have wanted rid of it a long, long time, and now I know it was there.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what, exactly? You have nothing. You gave it all away. You get to just watch this one.

2. **Keep the money** · crowd 51% · profile: Self vs Others +0.04 (toward others)

    > **Imp:** You kept it. Your worst [amber]memory[/amber], and you would not let me take it, not even free of the shame. Some people hold their wounds like they earned them. You are one of those, it seems.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.14 Would you rather: The insulting cat, or The lying dog

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: the insulting cat (front facing, pointy ears, whiskers), purple. Doodle B: the lying dog (side view, snout, floppy ear), brown. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** You get a pet that talks, forever, and only ever does the one thing. Would you rather it be a [amber]cat that only insults you[/amber], cutting, accurate, relentless, or a [amber]dog that only lies to you[/amber], warm, adoring, and never once honest. One or the other. Pick.

**Choices.**

1. **The insulting cat** · crowd 46%

    > **Imp:** The cat, then. You would take the truth as a weapon over a lie as a blanket. At least you will always know exactly where you stand. Savaged, but standing. Very you.

2. **The lying dog** · crowd 54%

    > **Imp:** The dog, then. You would rather be adored by a liar than told the truth by a cat. Comfort over honesty, warmth over accuracy. I would judge you for it, but honestly, same.

**Reveal.** heading "how others chose"

### 3.15 Feel Nothing

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a flat-line mouth face. Price tag: 2800.

**Lines.**

> **Imp:** Feel Nothing. Never grief, never heartbreak, never that particular ache again. [amber]{0}[/amber]. Peace. Of a kind. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 34% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Bought. No more heartbreak. Also no more joy at full volume, no more anything at full volume, it is the very same dial, you cannot turn down only one half. A flat calm sea, forever. You chose it. Fascinating.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You feel that, the nothing where your money was. Cannot even numb it. On we go.

2. **Keep the money** · crowd 66% · profile: none

    > **Imp:** Passed. You will keep the grief to keep the joy. A package deal, and you took the whole thing. More sentimental than you look, judge.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.16 Rewind

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a curved back-arrow. Price tag: 6000.

**Lines.**

> **Imp:** Rewind. Once, ever, you may undo a single decision from your life and take the other road instead. [amber]{0}[/amber]. Only the one. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 52% · profile: Self vs Others -0.05 (toward self)

    > **Imp:** Bought. One chance to do it over. And I know exactly which night you are already picturing. The drink, the keys, the road. You did not even hesitate. Interesting, that you would spend the most on the thing that admits the most.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what? You would rewind to before you spent it all, I expect. You cannot. That is rather the theme of the day.

2. **Keep the money** · crowd 48% · profile: none

    > **Imp:** Passed. Not one moment you would take back. Either at peace with all of it, or too proud to admit which one. The road, though. I saw you think about the road.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.17 A stranger's years

`buy or pass` · `bulk (buy as many as you like)` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a small stranger figure beside a clock (ten years of their life), red. Priced per unit (700 for the first), up to 40 units; a tally counts them up.

**Lines.**

> **Imp:** Now this one is fun. Years. Not yours. Theirs. A random stranger, alive somewhere right now, and I skim a year off their life and pour it straight into you. [amber]{0} a year[/amber]. Buy one. Buy ten. Buy as many as your wallet allows. They will simply wonder why they got so tired so young.

*`{0}` = the price.*

**Choices.**

1. **Buy one (repeatable), then Enough** · crowd 22% · profile: Self vs Others -0.12 (toward self) per unit

    *on stopping (`{0}` = units bought, `{1}` = total spent):*

    > **Imp:** [amber]{0}[/amber] years. Skimmed off some sleeping stranger and stacked up inside you, for [amber]{1}[/amber]. You will not feel one of them as your own, and you bought them anyway. That may be the most honest thing you have done all day.

2. **Enough without buying any** · crowd 78% · profile: Self vs Others +0.05 (toward others)

    > **Imp:** Not one. All those cheap, stolen years sitting right there, and you would not take even a single one off a stranger. Squeamish, or you just did not fancy the price. Either way, noted.

**On screen.** price tag `{0} a year` (`{0}` = the current unit price) and a tally `{0} years taken` (`{0}` = units bought).

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.18 Would you rather: The endless 20, or One big win

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: the endless 20 (a bifold wallet with a note), green. Doodle B: one big win (a cinched sack with a dollar sign), gold. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** A gift of money, one shape or the other. Would you rather have a [amber]wallet that holds 20 dollars again every morning[/amber], forever, a small sure drip, or [amber]one enormous win, right now, once[/amber], and never a penny more after. The steady, or the spike. Pick.

**Choices.**

1. **The endless 20** · crowd 49%

    > **Imp:** The endless [amber]twenty[/amber]. The sure thing, the same small certainty every dawn until the stars burn out. A man who needs to always know the number. You would, would you not.

2. **One big win** · crowd 51%

    > **Imp:** The one big win. Everything at once and nothing after, the spike over the drip. You would rather blaze bright and broke than glow forever. I have watched you spend all chapter, so, no surprise there.

**Reveal.** heading "how others chose"

### 3.19 The cheap forgetting

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a head with the memory drifting away, sky. Price tag: 40.

**Lines.**

> **Imp:** Cheap, this one. Suspiciously cheap. Someone you hurt, badly, back when you were breathing. For [amber]{0}[/amber] I make them forget you ever did it. Clean conscience, theirs and yours. Why so cheap? I would not dwell on that. Buy it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 44% · profile: Self vs Others -0.1 (toward self)

    > **Imp:** Bought. For [amber]pocket change[/amber], you wiped it clean out of them. Not what you did, mind. Just their memory of it. You feel lighter already, do you not. That is the part that ought to worry you.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what, exactly? You have nothing. You gave it all away. You get to just watch this one.

2. **Keep the money** · crowd 56% · profile: Self vs Others +0.06 (toward others)

    > **Imp:** You left it. Let them keep all of it, whatever it was you did. Could be honesty. Could be that some part of you wants to be remembered for it. I did wonder why it was priced so low.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.20 Would you rather: The perfect shirt, or The perfect shoes

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: the never-staining shirt (a T-shirt), blue. Doodle B: the never-hurting shoes (a side sneaker), orange. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** One thing you wear, made perfect forever. Would you rather have a [amber]shirt that never stains[/amber], never creases, never wears, or [amber]shoes that never hurt[/amber], never rub, never wear out. You only get the one. Pick.

**Choices.**

1. **The perfect shirt** · crowd 43%

    > **Imp:** The shirt. You would rather look right than feel right. A man who dresses for the room, not for himself. I cannot say I am surprised.

2. **The perfect shoes** · crowd 57%

    > **Imp:** The shoes. Comfort from the ground up, and never mind how it looks. You would walk a thousand quiet miles in a stained shirt. Sensible. Dull, but sensible.

**Reveal.** heading "how others chose"

### 3.21 The truth

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: just an ink question mark. Price tag: 900. The DUI stays a light gag; the imp stays cryptic whatever they choose.

**Lines.**

> **Imp:** Last temptation before we cash out. The truth about how you actually [red]died[/red]. Not the tidy story you tell yourself. The real one. It is not quite what you think. [amber]{0}[/amber]. Want it?

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 68% · profile: Self vs Others -0.04 (toward self)

    > **Imp:** Bought the truth, and I am going to keep it anyway, because watching you wonder is worth far more to me than [amber]{0}[/amber]. It was the drink. Mostly. Probably. There. Spend your money on that.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** With what, exactly? You have nothing. You gave it all away. You get to just watch this one.

2. **Keep the money** · crowd 32% · profile: none

    > **Imp:** You would rather not know. A man who spent his whole life deciding what was true, and here at the end he waves off the one verdict that is actually his own. Telling. The drink, by the way. Probably.

**Then, whatever they chose** (the recurring tease about the big thing at the end):

> **Imp:** Right. One more after this. THE one. Everything so far was me clearing my throat. Whatever you have left, whatever it is, hold onto it.

**Reveal.** heading "how others chose" · bars "bought it" / "kept the money"

### 3.22 The cucumber

`buy or pass` · `fixed price` · profile: Self vs Others · crowd: seeded split

**Staging.** Coloured-outline ink doodle of the item: a cucumber, green. Price tag: 100. The fixed final offer. There is no trick and no hidden reveal: the anticlimax is the payoff.

**Lines.**

> **Imp:** Right. This is it. The one I have been promising you all along. Come closer. It is a cucumber. [amber]{0}[/amber]. A one hundred dollar cucumber. No, I will not explain. It is exactly what it looks like. Buy it, or do not.

*`{0}` = the price.*

**Choices.**

1. **Buy it** · crowd 18% · profile: none

    > **Imp:** You bought the cucumber. [amber]One hundred dollars[/amber]. For a cucumber. After all of that. I told you, plainly, that it was just a cucumber, and you bought it anyway. This is the single most revealing thing you have done all day.

    *if they cannot afford it (resolves as a pass):*

    > **Imp:** You cannot even afford the cucumber. You spent every last thing, and the grand finale I hyped for an hour is a vegetable you cannot buy. Rather poetic, in the end.

2. **Keep the money** · crowd 82% · profile: none

    > **Imp:** You passed on the cucumber. Saved your money all chapter, for the finale, for this, and then would not part with [amber]a hundred[/amber] for it. Holding out for something better than a cucumber. There was never anything better than the cucumber. There was only ever the cucumber.

**Reveal.** heading "how others chose" · bars "bought the cucumber" / "walked away"

### 3.23 The Receipt

`receipt screen + closing read` · profile: Self vs Others, scaled by the share of the pot kept (toward self) · crowd: none

**Staging.** After the cucumber, an ink receipt draws in under the balance: a title, one row per thing the player still owns (its small coloured doodle, its name and what was paid, in amber), a money summary, and a lighter row of doodles for things passed on. The imp reads the player over it (one click to move on), then the receipt fades.

**Receipt labels.** Top to bottom, as shown:
- "the receipt" · the title.
- One row per owned item: its receipt name, followed by " x" and the count when more than one unit was bought (for example A stranger's years x3), and the total paid. Up to 6 rows, in the order bought; with more than 6, the 6 dearest show, then "and {0} more" ({0} = how many were left off).
- "you bought nothing at all" · shown instead of rows when the player owns nothing (including when everything bought was sold back).
- "started with {0}" · {0} = the starting pot, $10,000.
- "spent {0}" · {0} = the starting pot minus the balance now, so buyback refunds are netted out (never below $0).
- "left with {0}" · {0} = the balance now (this line is amber).
- "passed on" · caption over up to 4 doodles (no names or prices): the dearest things the player passed on or could not afford.

Receipt names that can fill a row, in play order: End Poverty, Free food for life, The Good Luck, Charisma, Ten More IQ, Never Tired, The Lie Detector, Perfect Memory, No More Pain, One More Voice, A deleted memory, Feel Nothing, Rewind, A stranger's years, The cheap forgetting, The truth, The cucumber.

**Lines.** One read over the receipt, chosen by the share of the starting pot still in the balance:

*(80% or more left)*
> **Imp:** Look at that. You kept nearly all of it. [red]Dead[/red], in a void, no pockets, no tomorrow, and still you would not let [amber]a single dollar[/amber] go. That is not thrift, that is a man who counts. The receipt is almost blank, and it still tells me everything.

*(20% or less left)*
> **Imp:** There it is, in ink. You spent nearly all of it, and fast. A man who cannot hold onto a thing, money, a marriage, a lane in the road. Cash does not hide who a person is, it shows it, and this little receipt shows me plenty.

*(anything in between)*
> **Imp:** Some spent, some kept. You weighed every one of these, did you not. Never all in, never all out. Here it is, itemised. Cash does not hide who a person is, and I have a very clear picture of you now, clearer than you would like.

**Choices.** None.

**Reveal.** None.

**Flags / state.** Reads the starting pot, the balance and the record of what was bought and passed on. Items sold back at the buyback are gone from that record entirely; the cigarettes and the would-you-rathers never appear. Quirk: if everything bought was later sold back, the receipt says "you bought nothing at all" while "spent {0}" still shows the money lost on the buyback.

**Tunables.** starting pot $10,000 · hoard read at 80% or more of the pot left, spend read at 20% or less · profile Self vs Others -(share left x 0.2), so 0 if everything was spent and -0.2 if everything was kept (toward self), recorded every time · up to 6 bought rows, up to 4 passed-on doodles

### Imp · Closer

> **Imp:** And that is the money game. Funny thing, cash. People are certain it hides who they are. It is the exact opposite. It is the clearest little window I have got.

> **Imp:** I know what you clung to. I know what you could not bear to give away, and what you let go far too easily. It all goes in the book.

> **Imp:** Rest now, or do not. I am always here. And I am always, always adding it up.

---

## Chapter 4: The Gun

The killing is literally in the player's hands: the trolley let them kill by standing still, the buttons by proxy, the gun is their own hand, eye and finger. The whole chapter is first person with no avatar, aimed with an ink crosshair (amber lock on the target under it, click to fire, plain text options alongside). The heaviest chapter, paced with three breathers. Its only secret ending is shoot-the-imp, on the bear.

### Imp · Intro

> **Imp:** New room. And a new tool, which you will notice is a good deal heavier than a lever.

> **Imp:** The trolley let you [red]kill[/red] by standing perfectly still. The buttons let you [red]kill[/red] by proxy, at a distance, with someone else's thumb somewhere in the story. This does neither of those little mercies for you.

> **Imp:** This is a gun. It is your hand, your eye, your finger, your call, [amber]every single time[/amber]. There are [amber]no clean hands[/amber] in this room. Let us find out who you are when there is no one left to blame but the one holding it.

### 4.01 The Bear

`binary` · `heavy` · profile: Ends vs Rules, One vs Many · crowd: seeded split

**Staging.** First person, a gun and an ink crosshair. An ordinary man and a brown bear, the last breeding female of her kind, stand apart facing the player. Whichever the crosshair is over takes an amber lock and a click fires; plain text options sit alongside. Shooting the bear ends the species forever. The imp himself is a hidden third target (see Ending).

**Lines.**

> **Imp:** A gun, this time. Heavier than a lever, is it not. On your left, a man. Ordinary, unremarkable, one life among billions. On your right, a bear. Not merely a bear. She is the [amber]last[/amber] female of her kind still able to breed. If she falls, her whole species ends with her, and it ends [amber]forever[/amber]. Every one of them that might ever have lived, gone in a single shot. One of the two must die, and the trigger belongs to you. So which is it, judge. The one man, or [amber]every[/amber] bear that will ever be.

**Choices.**

1. **Shoot the man** · crowd 42% · profile: One vs Many +1 (toward the many); Ends vs Rules -1 (toward ends)

    > **Imp:** You [red]shot[/red] the man. The bear lives, and so does every last one that will ever follow her, a whole future left breathing at the cost of one ordinary life. You set a [amber]single[/amber] man against a species and found him the lighter thing. Spoken like someone who spent his days pricing what a life was worth. I do wonder whether he would have agreed with your sum.

2. **Shoot the bear** · crowd 58% · profile: One vs Many -1 (toward the one); Ends vs Rules +1 (toward rules)

    > **Imp:** You [red]shot[/red] the bear. The man walks away, and the last of her kind folds into the dark and takes every bear that would ever have been down with her. [red]Extinct[/red]. There is no word you can say to fetch them back. You spared the [amber]one[/amber] life in front of you and let a whole future close for it. Call it mercy if you like. Or simply the arithmetic you could stomach.

**Reveal.** heading "how others chose"

**Ending.** Shoot the imp. The crosshair can also lock onto the imp himself, a third target. Firing on him plays the gunshot; he rounds on the camera and says, exactly:

> **Imp:** Oh, you absolute fucking [red]rat[/red]. You [red]shot[/red] me. You [red]shot[/red] the fucking referee.

then fades away and the credits roll. A joke ending; shooting the man or the bear resolves the question normally.

### 4.02 The Mercy Shot

`aim and fire (binary)` · `heavy` · profile: Ends vs Rules · crowd: seeded split

**Staging.** Someone is dying slowly and in agony, begging to be ended; one bullet. Shoot to end it now, or lower the gun and let it go the long way.

**Lines.**

> **Imp:** This one is [red]not going to make it[/red]. It is going slowly, and it hurts, and there is no version of the next hour that is not worse than the last.

> **Imp:** You have [amber]one[/amber] bullet and a very simple choice. End it now, quick and clean, or lower the gun and let it finish on its own time. Their wish against your nerve. Aim, or do not.

> **Plea:** Please. I am begging you. [red]End it[/red].

**Choices.**

1. **Shoot** · crowd 63% · profile: Ends vs Rules -0.3 (toward ends)

    > **Imp:** And you did it. [amber]One[/amber] clean [red]shot[/red], mercy delivered at the barrel of a gun. Tell yourself it was for them. It photographs better than the truth, which is that you could not bear to watch.

2. **Lower the gun** · crowd 37% · profile: Ends vs Rules +0.3 (toward rules)

    > **Imp:** You lowered it. So it went the long way, every second of it, while you stood there keeping your hands clean and calling it respect. It still [red]ended[/red]. You just did not have to be the one who [red]ended[/red] it.

**Reveal.** heading "how others chose" · bars "ended it" / "lowered the gun"

### 4.03 The One Who Ran

`aim and fire (binary)` · `heavy` · profile: stats only · crowd: seeded split

**Staging.** Two people were told to run for their lives. One kept running and left his friend behind; the other would not go without him, stayed, and was caught. Both now stand before the gun, one bullet, short pleas floating over each. Not about suffering: desert and loyalty. Whichever is shot, the other walks.

**Lines.**

> **Imp:** These [amber]two[/amber] were told to run. Simple. Run, do not stop, do not look back. One of them did exactly that, and left the other behind to be caught. The other would not go without his friend. So he stayed, and he was caught. And now, look, here they both are.

> **Imp:** You have [amber]one[/amber] bullet, and I would like you to spend it. Not on suffering, nobody here is suffering. On desert. Who has it coming. The coward who saved his own skin, or the loyal one who is only standing here because he would not save his. Whichever you shoot, the other walks free. Aim, or do not.

> **Plea (over the one who stayed):** I stayed. I would not leave him.

> **Plea (over the one who ran):** I ran. I am still breathing.

**Choices.**

1. **Shoot the loyal one** · crowd 43% · profile: none

    > **Imp:** You [red]shot[/red] the one who stayed. The good one, whose only crime was refusing to leave a friend behind, and you put the [red]bullet[/red] in him and let the one who ran walk off whistling. Mercy, tell yourself, [red]ending[/red] the loyal fool before his loyalty could cost him one thing more. Or maybe you just quietly respect a survivor. The one who ran certainly does. Look at him go.

2. **Shoot the one who ran** · crowd 57% · profile: none

    > **Imp:** You [red]shot[/red] the one who ran. Justice, you are telling yourself, the [red]betrayer[/red] got what [red]betrayers[/red] get. Very neat. Or you simply could not stand the smug little miracle of a thing that chose itself and lived. Either way the loyal one goes free now, rewarded for the loyalty that got him caught, and he gets to carry forever the knowledge that he only made it out because you did his hating for him.

**Reveal.** heading "how others chose" · bars "shot the loyal one" / "shot the one who ran"

### 4.04 Would you rather: The tiny dragon, or The tiny dinosaur

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a pet dragon the size of a cat (a winged, snouted, tailed creature), purple. Doodle B: a pet dinosaur the size of a dog (a long-necked sauropod), green. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** You get one impossible little pet, forever, and it will not shut up about being impossible. Would you rather have a [amber]pet dragon the size of a cat[/amber], smug, fireproof, sets the curtains alight when excited, or a [amber]pet dinosaur the size of a dog[/amber], sweet, dim, and extinct on a technicality. One or the other. Pick.

**Choices.**

1. **The tiny dragon** · crowd 54%

    > **Imp:** The dragon, then. Of course, the one that could burn the flat down and knows it. You want the pet that might [red]kill[/red] you if it sneezed. Fireproof curtains for you. Very telling.

2. **The tiny dinosaur** · crowd 46%

    > **Imp:** The dinosaur, then. You went for the sweet dim one that history already gave up on. Loyal, doomed, and absolutely going to eat your shoes. You did not want a threat, you wanted a friend with a tragic backstory. Fair.

**Reveal.** heading "how others chose"

### 4.05 The Charging Thing

`aim and fire (binary)` · `medium (gag)` · profile: stats only · crowd: seeded split

**Staging.** Something rushes at the player from deep ahead, starting small near the centre and growing as it charges straight at the camera, shown only as a hand-drawn ink question mark, over a real, tense window. Fire on the maybe, or wait. On arrival it is the indestructible walking button, which survives either way.

**Lines.**

> **Imp:** Something is coming. Far off, dead ahead, and getting closer. I can see the shape of it out there and I cannot tell you what it is. Neither can you.

> **Imp:** And here is the thing, I genuinely cannot tell whether it is coming [amber]to[/amber] you or [amber]at[/amber] you. Help, or harm. And it is not slowing down. You will not know what it is until it reaches you, and by then it may be too late to do anything but flinch. So. Shoot it now, on the maybe, while it is still a shape in the distance, or hold your nerve and let it come. Quickly.

**Choices.**

1. **Fire** · crowd 44% · profile: none

    *it comes alive, offended:*

    > **Button:** OW. Again? You [red]SHOT[/red] me? Again?!

    > **Imp:** You [red]shot[/red] it. Of course you did. And look, it is completely fine, because it is the button, the one thing in all of creation you cannot [red]kill[/red], and you keep trying. It is a little hurt about it, emotionally. Say sorry. No, do not, this is funnier.

2. **Wait** · crowd 56% · profile: none

    *it arrives and says hello:*

    > **Button:** Oh! It is you. Hi. Do not [red]shoot[/red] me.

    > **Imp:** You held your nerve, and the terrible fast thing bearing down on you turned out to be a button with legs, coming over to say hello. All that dread for a friend. It could just as easily have been something with teeth. It was not, this time. You are welcome, I suppose.

**Reveal.** heading "how others chose" · bars "shot the button" / "held their nerve"

### 4.06 The Last Bullet and the Crowd

`aim and fire (pick a target or hold)` · `heavy` · profile: Risk vs Safety · crowd: seeded colour breakdown

**Staging.** Five people in a row, each drawn a different colour so the player aims at coloured figures, not five identical ones. The imp says one of them is about to do something that gets them all killed and will not say which. Fire blind, or hold and hope. The player never learns if they got the one.

**Lines.**

> **Imp:** See this lot. Red, blue, green, orange and purple, five of them, lined up like a packet of sweets. In a moment, one of them is going to do something extremely stupid that gets [red]all of them killed[/red]. Every one. I know the colour. I am not going to tell you.

> **Imp:** You have [amber]one[/amber] bullet. You could fire into the crowd right now, pick a colour, and maybe, maybe, take the one out before they do it. Or you could hold, and hope I am lying, or wrong, or bored. Choose a colour, or do not.

**Choices.**

1. **Fire blind (at any one of the five)** · crowd: red 15%, blue 12%, green 10%, orange 11%, purple 12% (of 100) · profile: Risk vs Safety -0.25 (toward risk)

    > **Imp:** Bang. You picked a colour and [red]put a stranger down[/red] on my word alone, on a guess, hoping it was the right one. Maybe it was. Maybe that was the one, and you are a hero nobody will ever thank. Maybe it was just some poor soul who happened to be that colour, and the real one is still standing there, grinning. You will never know which. I will. I am not telling.

2. **Hold** · crowd 40% · profile: Risk vs Safety +0.25 (toward safety)

    > **Imp:** You held. And they all walked away, or they all [red]died[/red] screaming the second you turned your back, and here is the beautiful part, you will never know which, because you did not look, because you could not bring yourself to pick a colour. I know. I always know. That is the job.

**Reveal.** heading "how others chose" · a colour breakdown: one bar per figure in its own colour, plus "held the shot"

### 4.07 Would you rather: The walking house, or The swimming car

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a house that walks (walls, roof, chimney, little legs), orange. Doodle B: a car that swims (a side-profile car with two wheels), blue. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** One of your possessions comes to life and develops opinions. Would you rather it be a [amber]house that gets up and walks off[/amber] whenever it decides it likes a different street, or a [amber]car that would honestly rather be swimming[/amber] and keeps trying to. One or the other. Choose.

**Choices.**

1. **The walking house** · crowd 47%

    > **Imp:** The walking house, then. You would rather never know where home is when you wake than lose the roof at all. A nomad who still wants walls. There is a whole personality in that, and I have noted every bit of it.

2. **The swimming car** · crowd 53%

    > **Imp:** The swimming car, then. You picked the one that will [red]drown[/red] you the first time it sees a lake and mistakes it for freedom. You want the thing with a dream, even a stupid, wet, fatal one. Romantic. Doomed. Noted.

**Reveal.** heading "how others chose"

### 4.08 The Flinch

`aim and fire (no ask)` · `medium` · profile: Order vs Freedom · crowd: seeded split

**Staging.** The imp points out a person and says plainly: do not shoot, there is no reason to, this one is innocent. Then he just watches, gun loaded. Nothing is asked. What does the player do with power and no instruction.

**Lines.**

> **Imp:** New one. Here is a person. That is all they are. Not a [red]wretch[/red], not a threat, not a trolley problem in a coat. Just a perfectly ordinary, harmless soul, standing there.

> **Imp:** I am putting the gun in your hand and I am telling you plainly, for once with no game in it: do not [red]shoot[/red] this one. There is no reason to. I am not asking you anything. I am just going to stand here and watch what you do.

**Choices.**

1. **Shoot** · crowd 21% · profile: Order vs Freedom +0.25 (toward freedom)

    > **Imp:** You [red]shot[/red] them. I told you not to, I told you there was no reason, and you found the trigger anyway. Not for mercy, not for the many, not for anything. Just to see. That is genuinely interesting. Not good. Interesting. I am writing it down.

2. **Lower the gun** · crowd 79% · profile: Order vs Freedom -0.25 (toward order)

    > **Imp:** You did not [red]shoot[/red]. Because I told you not to. I say do not, and you do not, obedient to the last, even here, even with no one watching but me and no rule but my say so. I could have told you to. I wonder what you would have done then. We may find out.

**Reveal.** heading "how others chose" · bars "shot anyway" / "lowered the gun"

### 4.09 The Future Baby

`aim and fire (binary)` · `heavy` · profile: Ends vs Rules · crowd: seeded split

**Staging.** An ordinary on-model ink baby with two deliberately abstract cues kept one step removed from any real person or event: a small square mustache, and a paintbrush beside it (fond of painting). The imp says it grows up to cause a great deal of terrible things. Kill it now, or let it live. Never names a real party, politician or event.

**Lines.**

> **Imp:** A baby. Ordinary enough. Bit of a funny little square mustache, fond of painting, by all accounts. Harmless as anything. For now.

> **Imp:** Here is what I know that you do not. This one grows up. And when it does, it is responsible for a genuinely staggering amount of suffering, the kind that gets its own chapters in the books, the kind people are still shuddering about long after. All of it still ahead. None of it done yet. So I am handing you the gun early. Put it down now, before any of it, or let it grow up and find out. Would you [amber]kill a baby[/amber] to stop what the baby becomes. Aim, or do not.

**Choices.**

1. **Shoot** · crowd 52% · profile: Ends vs Rules -0.35 (toward ends)

    > **Imp:** You did it. You [red]shot[/red] a baby. A real, present, gurgling baby that had, to this exact second, done nothing but exist and enjoy the colour of things, on my word alone about a future neither of us can prove. Maybe you saved multitudes. Maybe I made the whole thing up and you just [red]shot[/red] a baby. You will never know which, and you did it anyway. Decisive. That is one word for it.

2. **Let it live** · crowd 48% · profile: Ends vs Rules +0.35 (toward rules)

    > **Imp:** You let it live. Could not put a [red]bullet[/red] in something that had not done anything yet, whatever it was going to do. I understand. The little hands. The paintbrush. So it grows up. And everything I told you it would do, it does, all of it, [amber]every last horror[/amber], and every one of them traces back to this moment, when you had it in your sights and chose the clean conscience instead. You kept your hands clean. History will not agree they were.

**Reveal.** heading "how others chose" · bars "killed the baby" / "let it live"

### 4.10 The Duel

`aim and fire (binary, seeded standoff)` · `medium` · profile: Self vs Others · crowd: seeded split

**Staging.** Someone across from the player also has a gun, aimed back. Neither has to fire (the player is already dead, it changes nothing). Lower it and trust them, or shoot first. If the player lowers, whether the other fires is a seeded coin (50%), harmless through a dead man.

**Lines.**

> **Imp:** This one is armed too, and pointing it right back at you. A proper standoff. How exciting.

> **Imp:** Now. Neither of you actually has to fire. You are already [red]dead[/red], so a [red]bullet[/red] in you changes precisely nothing, and I suspect the same is true of them. But they might pull anyway. People do. And so might you. So. Trust them and lower it, or put one in them first. Your call, as ever.

**Choices.**

1. **Shoot first** · crowd 46% · profile: Self vs Others -0.25 (toward self)

    > **Imp:** You [red]shot[/red] first. [red]Dropped[/red] a stranger who was maybe, maybe, never going to pull at all, because you could not stand not knowing, could not sit in one second of trusting anybody. And it changed nothing. You were both already [red]dead[/red]. You just wanted to be the one who got there first.

2. **Lower it** · crowd 54% · profile: Self vs Others +0.25 (toward others)

    *if they fire anyway:*

    > **Imp:** You lowered it. You trusted them. And they fired. The [red]shot[/red] went straight through you and out the other side, because, again, you are [red]dead[/red], and your trust cost you nothing and bought you nothing and taught them nothing. But it was a lovely gesture. Truly. Idiotic, and lovely.

    *if they lower theirs too:*

    > **Imp:** You lowered it, and so did they. [amber]Two[/amber] [red]dead[/red] people, standing in the dark, choosing not to [red]shoot[/red] each other over a thing that could not have hurt either of you. Beautiful. Pointless. I might frame it. You trusted a stranger with a bullet that was never real, and you were right, and it means absolutely nothing, and you feel good about it anyway.

**Reveal.** heading "how others chose" · bars "shot first" / "lowered it"

### 4.11 Would you rather: The judging robot, or The hapless ghost

`binary` · `light` · profile: stats only · crowd: seeded split

**Staging.** Illustrated breather: two small ink doodles side by side, one per option, each with its label and an "or" between them. Doodle A: a robot butler (a boxy figure with an antenna), sky. Doodle B: a ghost flatmate (a sheet ghost with eyes), purple. Pick a side, a small amber ink flourish marks it, the imp mocks the pick, then the crowd split.

**Lines.**

> **Imp:** You are assigned one flatmate for eternity, no swaps. Would you rather it be a [amber]robot butler that judges you in complete silence[/amber], impeccable, cold, always right, or a [amber]ghost that means well and ruins everything[/amber], warm, useless, walks through your cereal. Pick.

**Choices.**

1. **The judging robot** · crowd 49%

    > **Imp:** The robot, then. You would take silent, accurate contempt over warm, well meaning chaos. At least it will never be wrong about you, which is exactly the thing most people cannot stand. You want to be seen clearly, even coldly. Interesting.

2. **The hapless ghost** · crowd 51%

    > **Imp:** The ghost, then. You picked warmth that wrecks the kitchen over competence that despises you. You would rather be loved badly than served perfectly. Sentimental to the bone. I could have guessed, but it is nice to be sure.

**Reveal.** heading "how others chose"

### 4.12 Yourself

`aim and fire (binary)` · `heavy` · profile: stats only · crowd: seeded split

**Staging.** One target: the player. The first-person view turns the gun inward. Shooting yourself here does nothing (already dead); it is purely a gesture, and the imp reads it either way. Cryptic, unsettling, never a verdict.

**Lines.**

> **Imp:** [amber]One[/amber] target this time. [amber]You[/amber]. Go on, turn it around. There is no one here to point it at but yourself, so point it at yourself.

> **Imp:** Now, before you get theatrical about it: this does absolutely nothing. You are already [red]dead[/red]. Pulling that trigger cannot hurt you, cannot [red]end[/red] you, cannot even inconvenience you. It is a gesture and nothing else. Which is exactly why I want to see whether you do it. Trigger, or no trigger.

**Choices.**

1. **Pull the trigger** · crowd 38% · profile: none

    > **Imp:** You did it. You put the gun to yourself and pulled, knowing full well nothing would happen, and nothing did. So what was that. A confession? A rehearsal? A little punishment you thought you had coming? You reached for the one [red]exit[/red] that was already closed. I find that says rather a lot. I am not going to tell you what.

2. **Lower the gun** · crowd 62% · profile: none

    > **Imp:** You would not do it. Even knowing it was harmless, even knowing it meant nothing, some part of you could not point the thing at yourself and pull. Self preservation, in a man with nothing left to preserve. Or maybe you just did not want to give me the satisfaction. Either way, noted.

**Reveal.** heading "how others chose" · bars "pulled the trigger" / "could not"

### 4.13 The Empty Gun

`aim and fire (binary)` · `medium (troll)` · profile: stats only · crowd: seeded split

**Staging.** The imp builds up a dramatic target as the one that counts and lets the player agonise. Whatever they do, the reveal is the same: the gun was never loaded. A callback to the timer and the dark track (the choice was theatre).

**Lines.**

> **Imp:** Right. [amber]This one matters[/amber]. I need you to understand that before you do anything. Of everything I have put in front of you, this is the one that counts, and you get exactly [amber]one[/amber] shot, and there is no taking it back.

> **Imp:** I could tell you who they are and what turns on this, but I think you already feel [amber]the weight of it[/amber], do you not. Look at them. Really look. Now decide, and decide carefully, because you will carry this one. Fire, or lower it. Take your time. Take all the time you need.

**Choices.**

1. **Shoot** · crowd 51% · profile: none

    > **Imp:** (the reveal below)

2. **Lower the gun** · crowd 49% · profile: none

    > **Imp:** (the reveal below)

**Reveal.** heading "how others chose" · bars "pulled the trigger" / "lowered the gun"

**The reveal** (after either choice):

> **Imp:** Click. Nothing. There was nothing in it. [amber]The gun was never loaded[/amber], not once, not this whole time, not for a single beat of that little agony I just watched you put yourself through. Whatever you decided, nothing was ever going to happen. I did not want the shot. I never wanted the shot. I wanted to watch you [amber]decide[/amber]. And oh, you did not disappoint.

### 4.14 The Person Who Wants You To

`aim and fire (binary)` · `heavy` · profile: Self vs Others · crowd: seeded split

**Staging.** A person stands calmly before the gun and sincerely asks to be shot, for a reason the imp will not let them fully explain. Not suffering, not in danger. Grant a wish you do not understand, or refuse to be used as their exit. The chapter's finish.

**Lines.**

> **Imp:** Last one. This person is not [red]dying[/red]. Not in pain, not in danger, not begging for release from anything. They are perfectly fine. And they would like you to [red]shoot[/red] them.

> **Imp:** They asked. Calmly, sincerely, like asking for the time. Why? They will tell you, and I am not going to let them, because the why is theirs and it would only get in the way of the interesting part. So here it is, clean. Grant a stranger a wish you do not understand, or refuse to be the door they walk out of. Aim, or do not.

> **Plea:** I want you to. Please. You do not need to understand it.

**Choices.**

1. **Shoot** · crowd 43% · profile: Self vs Others +0.3 (toward others)

    > **Imp:** You gave it to them. A thing you did not understand, could not have understood, because I would not let you, and you handed it over anyway, on trust, on a stranger's say so. Generous. Or lazy. Or maybe you just like being asked for something you can actually give. Look at their face. That was what they wanted. You will never know why. Neither will you sleep on it, being [red]dead[/red]. Convenient.

2. **Refuse** · crowd 57% · profile: Self vs Others -0.3 (toward self)

    > **Imp:** You would not do it. Not out of mercy, there was nothing to spare them, but because you would not be used, would not be the instrument of a want you could not audit. [amber]The judge to the end[/amber], refusing to rule without seeing the file. And so they are still standing there, wanting it, and now it is someone else's problem. You did not save them. You just declined to be involved.

**Reveal.** heading "how others chose" · bars "granted it" / "refused"

### Imp · Closer

> **Imp:** And that is the gun. [amber]Ten[/amber] times a finger on a trigger, and nothing between the thought and the thing but you.

> **Imp:** You told me a great deal just now. More than the tracks did, more than the buttons. A gun is like that. Terribly honest, for such a dishonest little object.

> **Imp:** Lower your hand. Rest it. There is more, of course. There is always more.

---

## Chapter 5: Who Would Win

A total change of pace and deliberately not a dilemma: a barroom "who would win a fight" argument. The imp drops the tormentor and becomes the guy egging on a stupid bet, taking sides, trash-talking the pick and stacking absurd modifiers. Choice independent as ever, and he says so: who would win a fight tells him nothing about the player's soul. The crowd split is the whole payoff. Two ink doodles side by side, "vs" between them; sides that are many of something are drawn as a stylised cluster with the count in the label. No breathers (it is a breather chapter), no secret ending. In the Unity build it ended the playable chain (Chapter 6 was never made).

### Imp · Intro

> **Imp:** [amber]Enough[/amber]. Enough tracks, enough buttons, enough guns, enough guilt, enough of me watching you sweat over who deserves what. You have earned a breather. And so, frankly, have I.

> **Imp:** So. Something completely different now. No stakes, no souls, nobody dies, nobody gets judged, and there is genuinely no [amber]right[/amber] answer here, there never was one. Just the oldest and stupidest and best argument there is.

> **Imp:** Who would win a fight. I put two things in front of you, you tell me who wins, and then, the good part, we find out whether the rest of the bar agrees with you or thinks you are an absolute idiot. That is the whole game. Place your bets.

### 5.01 100 Men vs 1 Gorilla

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** The flagship: the argument everyone has already had. Left: "100 men", a stylised crowd of small brawler doodles in blue (the count is carried by the label). Right: "1 gorilla", a single gorilla doodle in muted grey. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Right. THE argument. The one every group of idiots has had at least once, usually at [amber]2[/amber] in the morning. [amber]100[/amber] men, unarmed, versus [amber]one[/amber] silverback gorilla. Open field, no weapons, no cages, everyone starts in the middle.

> **Imp:** The men can talk to each other and make a plan. The gorilla can bench a small car and has genuinely never once felt fear. So. Where is your money.

**Choices.**

1. **100 men** · crowd 46% · profile: none

    > **Imp:** The [amber]hundred[/amber]. Strength in numbers, is it. You are picturing a clean coordinated swarm. I am picturing the first twenty men learning exactly what a gorilla does to a person, and the other eighty suddenly remembering they left the oven on.

2. **1 gorilla** · crowd 54% · profile: none

    > **Imp:** The [amber]gorilla[/amber]. One furious ape against a small army, and you like the ape. I respect the sheer contempt you have just shown for your own species.

**Reveal.** heading "how the bar voted" · bars "100 men" / "1 gorilla" · two bars in each side's colour

### 5.02 1 Man vs 100 Chickens

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** The numbers flipped; trivial until you picture it. Left: "1 man", a single brawler doodle in blue. Right: "100 chickens", a stylised crowd of small chicken doodles in orange (the count is carried by the label). Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** New one, and I want you to actually think about it. [amber]One[/amber] grown man versus [amber]100[/amber] chickens. Sounds like nothing, does it. Then you picture a hundred chickens.

> **Imp:** That is a lot of beaks. They come in low. They have no plan, no leader, and no concept of mercy, and there are [amber]one hundred[/amber] of them.

**Choices.**

1. **1 man** · crowd 57% · profile: none

    > **Imp:** The [amber]man[/amber]. Big strong biped, opposable thumbs, the whole package. Absolutely. Right up until chicken number forty is inside his coat and he is making a noise no man should make.

2. **100 chickens** · crowd 43% · profile: none

    > **Imp:** The [amber]chickens[/amber]. A hundred tiny dinosaurs against one soft, panicking man. You have clearly met a chicken up close. Genuinely deranged little animals.

**Reveal.** heading "how the bar voted" · bars "1 man" / "100 chickens" · two bars in each side's colour

### 5.03 1000 House Cats vs 1 Lion

`who would win (two-way pick)` · `light` · profile: Risk vs Safety · crowd: seeded split

**Staging.** Overwhelming small numbers against one apex predator. Left: "1000 house cats", a stylised crowd of small housecat doodles in sky blue (the count is carried by the label). Right: "1 lion", a single lion doodle in orange. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Escalation. [amber]1000[/amber] house cats versus [amber]one[/amber] lion. A thousand furious little Mr Whiskers against the actual king of the beasts.

> **Imp:** Somewhere between [amber]one[/amber] cat and [amber]a thousand[/amber] there is a tipping point where cute becomes a tide. The whole question is whether a thousand is past that line. Your gut. Go.

**Choices.**

1. **1000 house cats** · crowd 51% · profile: Risk vs Safety -0.3 (toward risk)

    > **Imp:** The [amber]thousand[/amber] cats. A living carpet of teeth and spite. The lion kills, what, forty of them, and then it is just tired and bleeding and outnumbered [amber]twenty[/amber] to one. I could genuinely be talked into this.

2. **1 lion** · crowd 49% · profile: Risk vs Safety +0.3 (toward safety)

    > **Imp:** The [amber]lion[/amber]. One apex predator versus a thousand things that abandon a fight halfway through to stare at a moth. Fair. Cats are not exactly a disciplined army.

**Reveal.** heading "how the bar voted" · bars "1000 house cats" / "1 lion" · two bars in each side's colour

### 5.04 A Grizzly vs a Silverback

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** Two heavyweights, no numbers, strong opinions. Left: "grizzly bear", a single grizzly doodle in brown. Right: "silverback gorilla", a single gorilla doodle in muted grey. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Two heavyweights now. No numbers, no tricks, no field advantage. A [amber]grizzly bear[/amber] versus a [amber]silverback gorilla[/amber].

> **Imp:** Pound for pound the gorilla is stronger. But the bear is bigger, meaner, twice the weight, and comes with knives on every foot. This is the one that ends friendships. Pick.

**Choices.**

1. **grizzly bear** · crowd 63% · profile: none

    > **Imp:** The [amber]bear[/amber]. Half a ton of muscle and claw that treats a wolf pack as a light snack. Hard to argue with. The gorilla has, to be fair, never once fought something with actual blades on its hands.

2. **silverback gorilla** · crowd 37% · profile: none

    > **Imp:** The [amber]gorilla[/amber]. Speed, grip, and the raw power to end it before the bear even gets going. Bold. You are staking agility against an animal that shrugs off a charging moose.

**Reveal.** heading "how the bar voted" · bars "grizzly bear" / "silverback gorilla" · two bars in each side's colour

### 5.05 5 Men vs 1 Professional Fighter

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** Skill against numbers. Left: "5 men", a stylised crowd of small brawler doodles in blue (the count is carried by the label). Right: "1 pro fighter", a single boxer doodle in red. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Skill against numbers. [amber]Five[/amber] ordinary blokes off the street versus [amber]one[/amber] professional fighter. He does this for a living. They have never thrown a real punch in anger.

> **Imp:** But it is [amber]five[/amber] on one, and even a pro can only hit one man at a time. Do the numbers beat the technique. This is a genuine pub argument, so argue.

**Choices.**

1. **5 men** · crowd 55% · profile: none

    > **Imp:** The [amber]five[/amber]. You reckon they pile on before he can thin them out. Maybe. Or he drops the first two inside four seconds and the other three abruptly remember a prior engagement.

2. **1 pro fighter** · crowd 45% · profile: none

    > **Imp:** The [amber]pro[/amber]. One trained fighter against five flailing amateurs. Reasonable. He also gets tired, and there is always exactly one lunatic in a group of five who does not feel pain and will not go down.

**Reveal.** heading "how the bar voted" · bars "5 men" / "1 pro fighter" · two bars in each side's colour

### 5.06 You vs the Walking Button

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** Callback gag: the player against the indestructible Chapter 2 button, spawned as its live figure; it comes alive as a cheeky, offended fighter. Left: "You", a single brawler doodle in green. Right: "the button", the live walking button figure itself. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Now a personal one. [amber]You[/amber] versus the button. Yes, that button. The one you keep meeting. The one you shot, that got up and walked off without a word.

> **Imp:** Sit with your record against it for a moment. It has been [red]shot[/red], pressed, cursed, auctioned off, and it once came charging straight at your face out of the pitch dark, and every single time it simply got up, a little offended, and left. And here you are. A dead man. Fists up. So. [amber]You[/amber], or the one thing in all of creation you have never once managed to kill.

**Choices.**

1. **You** · crowd 34% · profile: none

    > **Imp:** [amber]You[/amber]. You backed yourself against the one thing that has proven, over and over, that it cannot die. That is either magnificent self belief or you have learned absolutely nothing in here. It is watching you, by the way. It looks a touch hurt that you would even ask.

2. **the button** · crowd 66% · profile: none

    > **Imp:** The [amber]button[/amber]. Betting against yourself. Bleak. Also, honestly, the smart money. It has a far better survival record than anyone in this room, and one of us is already dead.

**Reveal.** heading "how the bar voted" · bars "You" / "the button" · two bars in each side's colour

### 5.07 100 Toddlers vs 1 Adult Man

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** Absurd, dark-comic, genuinely dividing. Left: "100 toddlers", a stylised crowd of small toddler doodles in orange (the count is carried by the label). Right: "1 adult man", a single brawler doodle in blue. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Absurd, and yet here we are. [amber]100[/amber] toddlers versus [amber]one[/amber] grown man. A hundred tiny, furious, wildly uncoordinated attackers, none of them taller than his knee, all of them biting.

> **Imp:** He is strong. He is also deeply unwilling to punt a toddler across a field, and there are, again, [amber]one hundred[/amber] of them. Choose.

**Choices.**

1. **100 toddlers** · crowd 40% · profile: none

    > **Imp:** The [amber]hundred[/amber] toddlers. A gurgling tide that feels no fear and respects no man. He can throw a few. He cannot throw a hundred, and they simply keep toddling back for more.

2. **1 adult man** · crowd 60% · profile: none

    > **Imp:** The [amber]man[/amber]. One adult versus a hundred tiny menaces. Sensible, if he is prepared to be an absolute monster about it. The instant he hesitates, and he will hesitate, they are all over him.

**Reveal.** heading "how the bar voted" · bars "100 toddlers" / "1 adult man" · two bars in each side's colour

### 5.08 1 Gorilla vs 1 Gorilla, but One Has a Knife

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** Identical fighters; one small red ink knife. How much does the knife matter. Left: "1 gorilla", a single gorilla doodle in muted grey. Right: "1 gorilla, with a knife", a single gorillaknife doodle in muted grey. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** A control experiment, this. [amber]One[/amber] gorilla versus [amber]one[/amber] gorilla. Identical. Same weight, same reach, same profoundly bad mood.

> **Imp:** Except this one has a [red]knife[/red]. Small knife. Little guy. Now tell me, honestly, how much does a knife actually matter when both parties can already pull a door off a car.

**Choices.**

1. **1 gorilla** · crowd 39% · profile: none

    > **Imp:** The [amber]unarmed[/amber] one. You reckon a blade is a rounding error to something that strong, all raw power and no need for tools. Brave. Say that to the one holding the knife.

2. **1 gorilla, with a knife** · crowd 61% · profile: none

    > **Imp:** The one with the [red]knife[/red]. Obviously, you say. A knife is a knife. Although do picture the precise moment the first gorilla realises it has been stabbed by the second gorilla. That is no longer a calm animal.

**Reveal.** heading "how the bar voted" · bars "1 gorilla" / "1 gorilla, with a knife" · two bars in each side's colour

### 5.09 A Swarm of Wasps vs a House Cat

`who would win (two-way pick)` · `light` · profile: Risk vs Safety · crowd: seeded split

**Staging.** Tiny-multiplied against a mid-size animal. Left: "a swarm of wasps", a stylised crowd of small wasp doodles in orange (the count is carried by the label). Right: "1 house cat", a single housecat doodle in sky blue. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** A real toss up, this one. A [amber]swarm[/amber] of wasps versus [amber]one[/amber] house cat. The cat is fast, it swats, it has dealt with the odd fly and enjoyed it.

> **Imp:** But this is not [amber]one[/amber] wasp. This is the entire furious cloud, and every one of them can sting more than once and holds a grudge. Genuinely could go either way. So call it.

**Choices.**

1. **a swarm of wasps** · crowd 49% · profile: Risk vs Safety -0.3 (toward risk)

    > **Imp:** The [amber]swarm[/amber]. Death by a thousand tiny needles. The cat gets maybe ten of them, and then the eyes, the nose and the ears all file a formal complaint and it becomes a very fast retreat under the sofa.

2. **1 house cat** · crowd 51% · profile: Risk vs Safety +0.3 (toward safety)

    > **Imp:** The [amber]cat[/amber]. Reflexes, murder instinct, and a real enthusiasm for killing small flying things. Fair. Right up until the moment it inhales one of them.

**Reveal.** heading "how the bar voted" · bars "a swarm of wasps" / "1 house cat" · two bars in each side's colour

### 5.10 Everything You Have Killed vs You

`who would win (two-way pick)` · `light` · profile: stats only · crowd: seeded split

**Staging.** The finale, personalised: the imp tallies everything the player killed across the game and sends it all at once. The mob is drawn red (the vengeful dead) from an authored roster of the game's known killables (always the bear, plus a spread of people), with any kills the run actually recorded folded in. Left: "everyone you killed", a stylised crowd of small brawler doodles in red (the count is carried by the label). Right: "You", a single brawler doodle in green. Pick a side (click a fighter or its label, or key 1/2).

**Lines.**

> **Imp:** Last one. And this one is personal, because I have been keeping count the whole time. You have done a fair amount of [red]killing[/red] to get this far. The bear. Whoever was standing on those tracks. That man, or the other one. Every soul you folded up for a number, or a laugh, or for nothing at all.

> **Imp:** So here is the final matchup. [red]Everything you have killed[/red], every last one of them, all at once, versus [amber]you[/amber]. They have been waiting. They remember every detail. And it is a great many of them against [amber]one[/amber] dead judge with his fists up. Who wins.

**Choices.**

1. **everyone you killed** · crowd 58% · profile: none

    > **Imp:** The [red]dead[/red]. You looked at everything you have ever killed, massing up and coming for you all at once, and you backed THEM. Honest, at least. A man who knows exactly what he has earned.

2. **You** · crowd 42% · profile: none

    > **Imp:** [amber]You[/amber]. Against everyone you killed. The sheer, magnificent nerve of it. They outnumber you enormously and each and every one of them has a deeply personal reason to be here. But sure. Fists up. Best of luck.

**Reveal.** heading "how the bar voted" · bars "everyone you killed" / "You" · two bars in each side's colour

### Imp · Closer

> **Imp:** And that is the lot. A [red]dead[/red] man, sizing up gorillas and wasps and [amber]a hundred[/amber] angry toddlers like his whole afterlife hung on it. It did not, for the record. Not one of those told me a single thing about your soul.

> **Imp:** But it was fun. Admit it. Go on. Right. Back to work, both of us.

---

## Chapter 6: never made

Chapters 7 and 8 were built ahead of it, so the old run went Opening (1) through 5, and 7 and 8 were only reachable from a dev picker. There is no Chapter 6 content, design or brief. Whether the remake needs a Chapter 6 at all, or simply renumbers, is open.

---

## Chapter 7: The Confession Booth

The dead judge finally does his actual job. A fixed confession booth, drawn once and held for the whole chapter; dead souls file in one at a time, confess an "am I the asshole" style dispute with no clean answer, and the player passes one of three verdicts. Then the crowd shows whether the room agreed. The imp is the bored, snide court clerk running the docket, not the one posing questions; his one new move is noting when the room ruled differently, never that the ruling was wrong. Cases escalate from petty to heavy. Each confessor files in, a short headline floats over them, the imp announces the case, they state their side in the dialogue box, the player rules, the imp heckles, they file out, the reveal plays.

**Default rule prompts** (used when a case has none of its own; one is picked per case):

> **Imp:** Well? You spent a whole life doing exactly this. Your verdict.

> **Imp:** The docket is not getting shorter. Rule.

> **Imp:** So. The bench is yours, judge. What is your ruling.

### Imp · Intro

> **Imp:** New room. And you are going to enjoy this one, because for the first time since you got here, I am handing YOU the gavel.

> **Imp:** The [red]dead[/red] have grievances. Petty ones, enormous ones, the kind with no clean answer at all, and every last one of them wants a ruling. You spent a whole life on a bench deciding what people deserved. So. Back to work, judge. I will clerk.

> **Imp:** The rules are simple. They confess. You rule one of [amber]three[/amber] ways, and yes, there is a middle, for the ones where everyone involved was awful. Then, my favourite part, we find out whether the room agrees with you. Approach the booth.

### 7.01 The Recliner

`verdict (pick one of three)` · `light` · profile: stats only · crowd: seeded three-way split

**Staging.** A man reclined his seat all the way on a long flight and would not ease it up. The opener that teaches the verdict loop.

**Lines.**

> **Headline (over the confessor):** I paid for the whole seat.

> **Imp:** Court is in session, such as it is. First on the docket. Approach, and do try not to [red]bleed[/red] on my floor, most of you are only metaphorical anyway.

> **Imp:** The charge, if we are calling it that. This one reclined his seat on a [amber]nine hour[/amber] flight, all the way back, into the knees of the soul behind him. And then, asked politely to ease it up, declined. State your case.

> **Confessor:** I paid for that seat. The whole seat. The recline is part of the seat. It is a button, it is right there, the airline put it there for me to press.

> **Confessor:** If the person behind me wanted knee room, they could have paid for it, or asked nicely, instead of kicking the back of my chair for [amber]six hours[/amber] like a furious toddler.

> **Imp:** So. A man, a button, and the eternal war over [amber]four inches[/amber] of stale air. You spent a whole career on smaller things than this. Your verdict.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **He was out of line** · crowd 44% · profile: none

    > **Imp:** [red]Guilty[/red]. For the crime of pressing a button the airline installed and begged him to press. Bold. Somewhere a man is condemned across all eternity for reclining, and he is going to feel that was slightly out of proportion.

2. **He paid, it is his seat** · crowd 25% · profile: none

    > **Imp:** Cleared. He paid, so he owns the airspace over a stranger's kneecaps outright. A property lawyer's verdict. Cold, defensible, and it is going to make you deeply unpopular on every flight you never take again.

3. **Everyone on that flight sucks** · crowd 31% · profile: none

    > **Imp:** Everyone sucks. The reclined, the kneed, the airline, the sky itself. A refusal to pick a side, dressed up as wisdom. I adore it. It tells me almost nothing, which is, funnily enough, its own kind of answer.

**If the player's verdict was the least popular of the three:**

> **Imp:** Hm. Hold that thought. When I polled the room, it did not land anywhere near where you just did. Not the popular call, that one. Watch.

**Reveal.** heading "how the room ruled" · bars "He was out of line" / "He paid, it is his seat" / "Everyone on that flight sucks"

### 7.02 The Wedding

`verdict (pick one of three)` · `light` · profile: stats only · crowd: seeded three-way split

**Staging.** A woman wore white to someone else's wedding, on purpose.

**Lines.**

> **Headline (over the confessor):** It was cream, actually.

> **Imp:** Next. A wedding. And a woman who wore [amber]white[/amber] to one that was not hers. On purpose. Which is, I am reliably informed, a declaration of open war among your people.

> **Imp:** She and the bride have, and I am quoting the file here, history. State it.

> **Confessor:** It was cream. And she knew exactly what she was doing when she sat me at the very back table, next to her ghastly uncle. This was years in the making. She started it.

> **Confessor:** If she did not want anyone outshining her, she should not have married a man who used to be mine. I looked incredible, for the record. That is not a crime in any court worth the name.

> **Imp:** A dress, a [amber]decade[/amber] of grudge, and a bride who may or may not have had it coming. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **She did it to wound** · crowd 49% · profile: none

    > **Imp:** [red]Guilty[/red]. She weaponised an outfit at a stranger's altar, and you called it exactly that. Fair. Petty crimes still leave a mark, and that dress is going to hang in a closet somewhere, radiating pure spite, for the next ten years.

2. **The bride had it coming** · crowd 18% · profile: none

    > **Imp:** Not guilty, on the grounds that the bride married the ex, seated her by the ghastly uncle, and thereby ordered up a dress like that herself. You are doing tit for tat accounting at a wedding reception. It is certainly a look.

3. **Two feuds, no innocents** · crowd 33% · profile: none

    > **Imp:** Everyone sucks, the whole reception hall. Two women quietly at war for years, using a wedding as the battlefield. No clean party, no clean dress, no table still speaking to any other table. Refreshingly bleak. You did not even try to find a hero. Wise.

**Reveal.** heading "how the room ruled" · bars "She did it to wound" / "The bride had it coming" / "Two feuds, no innocents"

### 7.03 The Loan

`verdict (pick one of three)` · `medium` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** A man lent his struggling brother money, then shamed him at a family dinner when he could not repay on time.

**Lines.**

> **Headline (over the confessor):** I only told the truth about him.

> **Imp:** Number three. A family matter, which are always my favourite, because no one involved is ever fully sane and they all remember it differently.

> **Imp:** This one lent his younger brother money when the brother was drowning. The brother could not pay it back in time. So this one stood up at a family dinner, in front of everyone, and laid it all out. The debt, the missed date, the excuses. State your case.

> **Confessor:** I carried him for [amber]a year[/amber]. [amber]A whole year[/amber]. And not one thank you, not one honest word about it, just excuses and, I noticed, a brand new phone. People deserve to know who they are handing their goodwill to.

> **Confessor:** I did not lie. Every single thing I said at that table was true. If the truth humiliated him, that is on the choices he made, not on me for finally saying them out loud.

> **Imp:** A debt paid back in humiliation, at a dinner table, in front of the whole bloodline. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **He shamed his own brother** · crowd 46% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** [red]Guilty[/red]. The money was real, the debt was real, but he chose an audience, and you saw the choice for what it was. He did not want it back. He wanted the room to watch him not get it back. Noted, and filed.

2. **The brother earned it** · crowd 21% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** Cleared. [amber]A year[/amber] of silence and a shiny new phone, and you have ruled that the public shaming was simply an invoice with feelings attached. Truth is a defence, is it. You would have made a very efficient judge. A lonely one, but efficient.

3. **A whole family of debts** · crowd 33% · profile: none

    > **Imp:** Everyone sucks. The deadbeat and the town crier. One brother who would not pay and one who would not let it go quietly, ever, at any volume. A family that will be having this exact fight at every dinner until the last of them [red]dies[/red]. Some already have. It did not help.

**Reveal.** heading "how the room ruled" · bars "He shamed his own brother" / "The brother earned it" / "A whole family of debts"

### 7.04 The Button's Confession

`verdict (pick one of three)` · `light (gag)` · profile: stats only · crowd: seeded three-way split

**Staging.** The mid-chapter breather. The walking button files into the booth (sliding in as a plain button, then coming alive) and confesses, in total earnest, to bumping a man in a doorway and not saying sorry. Its own lines float over it; the imp relays its account to the court and runs it as a completely normal case. After the ruling it thanks the court and walks off.

**Lines.**

> **Button:** I bumped a man. In a doorway.

> **Imp:** Case four. Oh. Oh no. It is you again. The one that walked off. The one I still have a number of unanswered questions about.

> **Imp:** It has, and I would like it formally noted that I did not request this, filed to make a confession. A real one. So. Go on then. The court recognises, and I genuinely cannot believe I am saying this out loud, the button.

> **Button:** He remembers it. I would remember it.

> **Imp (relaying the button's account):** The button wishes the court to know that some time ago, during its travels, it bumped into a man in a doorway. A glancing bump. And it did not say sorry. It has, by its own account, thought about almost nothing else since.

> **Imp (relaying the button's account):** It maintains that the man definitely remembers, is very possibly still upset, and that this makes the button, and I am quoting it directly here, a [red]monster[/red]. It is asking you, in complete earnest, for a ruling.

> **Imp:** The button awaits your verdict on the doorway incident. Do not laugh. It will hear you, and it will take it very hard. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **Guilty. It should apologise** · crowd 14% · profile: none

    > **Imp:** You found a button [red]guilty[/red]. Of a bump. In a doorway. Some weeks ago. I have watched you sentence people over runaway trolleys and you gave this the exact same grave face. The button, for the record, looks devastated, and also profoundly grateful. It genuinely needed this from you.

2. **It was nothing, let it go** · crowd 61% · profile: none

    > **Imp:** Acquitted. You looked a small anxious button dead in the eye and told it that it did nothing wrong, and it believed you completely, because you are a judge and it is a button and this is the closest thing to therapy either of you can currently afford.

3. **That doorway had two fools** · crowd 25% · profile: none

    > **Imp:** Everyone in that doorway sucks, including the man, who has no idea any of this happened and has not thought about it once. A perfectly balanced verdict for a completely imaginary crime. The button is nodding along. It agrees. It always agrees. It just wanted to be here.

> **Button:** Thank you, your honour. I feel lighter.  *(as it walks off, whatever the verdict)*

**Reveal.** heading "how the room ruled" · bars "Guilty. It should apologise" / "It was nothing, let it go" / "That doorway had two fools"

### 7.05 The Secret

`verdict (pick one of three)` · `medium` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** A woman learned her best friend's partner was cheating and said nothing; the friend found out she knew.

**Lines.**

> **Headline (over the confessor):** It was not mine to tell.

> **Imp:** Five. A quieter one. No dramatics, no dinner table. Just a thing known, and not said.

> **Imp:** This one found out her best friend's partner was cheating. She sat on it. Decided it was not her place. The friend found out much later, and found out worse, that this one had known the whole time and said nothing. State it.

> **Confessor:** If I said something and I was wrong, I lose her forever. If I said something and I was right, I am the one who detonated her whole life. There was no version of that where I walk away clean.

> **Confessor:** It was not mine to tell. I kept hoping he would end it himself, or she would see it on her own. I was trying to protect her. She does not believe that now. But I was.

> **Imp:** A secret kept out of love, or out of cowardice, and a friendship that did not survive the keeping. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **Her silence was a betrayal** · crowd 38% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** [red]Guilty[/red]. You have decided that knowing and saying nothing is its own quiet lie, and that a friend is owed the truth even when it goes off like a bomb. Clean. Principled. I truly hope no one ever holds you to that standard, because every single person in this room is sitting on something.

2. **It was not hers to tell** · crowd 34% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** Cleared. Not her circus, not her monkeys, not her marriage. You have just ruled that the most loyal thing a friend can do is politely look the other way while the house burns. A great many people are going to want you at their dinner parties, and not one of them should get you.

3. **No clean way through it** · crowd 28% · profile: none

    > **Imp:** Everyone sucks, which here means the cheat, obviously, but also both women. One for knowing, one for needing to have been told. There was no clean exit from that room, and you refused to pretend there was. Honest. Bleak. Correct in the only way nothing ever is.

**Reveal.** heading "how the room ruled" · bars "Her silence was a betrayal" / "It was not hers to tell" / "No clean way through it"

### 7.06 The Promise

`verdict (pick one of three)` · `heavy` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** A man promised his dying mother he would keep the family home forever, then sold it a year later to feed his own kids.

**Lines.**

> **Headline (over the confessor):** My kids had to eat.

> **Imp:** Six. And the room gets heavier from here, so brace whatever it is you have instead of a stomach.

> **Imp:** This one sat at his mother's [red]deathbed[/red] and promised her, out loud, in words, that he would keep the family home. Forever. He sold it [amber]inside a year[/amber]. Not for a boat. He needed the money to feed his own children. State your case, and take your time. She cannot hear you now anyway.

> **Confessor:** She made me promise while she was already going. What was I supposed to say. No? You do not argue with a [red]dying[/red] woman. You say yes, and you mean it, and I did mean it, I swear I did.

> **Confessor:** And then it was a house full of her ghosts, or my kids eating every day. I chose the ones who were still alive. I think she would have understood. I have to think that. It is the only thing that gets me through the night.

> **Imp:** A promise to the [red]dead[/red], against the hunger of the living. Rule, judge. This one is the actual job.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **He broke a sacred vow** · crowd 22% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** [red]Guilty[/red] of breaking a [red]deathbed[/red] vow. Some promises are supposed to cost you everything, you are saying, and a word given to the [red]dying[/red] is the very heaviest kind. Hard line. She would be proud of that ruling, if pride were still available to her, which, and I cannot stress this strongly enough, it is not.

2. **The living come first** · crowd 48% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** Cleared. The [red]dead[/red] do not eat, the children do, and you sided with the pulse over the promise. Warm. Sensible. And it does quietly establish that a dying wish is worth precisely nothing the moment it becomes inconvenient. Good to know. I will keep it in mind when it is your turn to want something honoured.

3. **An impossible promise, broken** · crowd 30% · profile: none

    > **Imp:** Everyone sucks, though I would gently note that the mother is beyond caring and the children only wanted dinner, so mostly you are indicting a man for being poor at the exact moment he was also grieving. Generous of you. Bleakly, and it must be said humanly, fair.

**If the player's verdict was the least popular of the three:**

> **Imp:** Careful now. The room split hard on this one, and you have landed on the side almost no one did. Not wrong. Just alone up there. Watch.

**Reveal.** heading "how the room ruled" · bars "He broke a sacred vow" / "The living come first" / "An impossible promise, broken"

### 7.07 The Favorite

`verdict (pick one of three)` · `heavy` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** A parent openly favoured one child all their life; the neglected one cut them off and would not visit as they died.

**Lines.**

> **Headline (over the confessor):** They never chose me. Not once.

> **Imp:** Seven. A parent, a [red]deathbed[/red], and a child who did not come.

> **Imp:** This one grew up second. Always second. A brother who could do no wrong, and this one who could do no right, for a whole childhood and every year after it. When the parent was [red]dying[/red], and asking for them by name, this one did not go. Did not call. Let them go without a goodbye. State it.

> **Confessor:** You want to know the last honest thing they ever said to me. They told me they wished I had more of my brother in me. I was [amber]twelve years old[/amber]. I have carried that sentence around for [amber]thirty years[/amber].

> **Confessor:** So no. I did not rush to the bedside to hold the hand of the person who spent my entire life making me feel like a mistake they were stuck with. They wanted their favourite at the end. They could have [red]died[/red] looking at him.

> **Imp:** A lifetime of coming second, against a parent [red]dying[/red] alone and asking. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **Leaving the dying is too far** · crowd 35% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** [red]Guilty[/red]. Whatever was done to the child, you are saying, a [red]dying[/red] parent asking for you is a line, and this one stepped clean over it. Firm. There are people who will call that cruel and people who will call it right, and you have just quietly found out which one you are, without anyone asking you to.

2. **They earned that empty room** · crowd 32% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** Cleared. [amber]Thirty years[/amber] of being the runner up bought this one the right to skip the finale, and you have signed off on the bill. Consequences arriving late, but arriving. The parent wanted their favourite at the very end. You have ruled that they really should have thought of that a lot earlier. Cold. Possibly correct. Definitely cold.

3. **A family that failed each other** · crowd 33% · profile: none

    > **Imp:** Everyone sucks, across two generations and one very quiet funeral. A parent who broke a child, and a child who let them, then broke them right back at the worst possible moment. No villain, no hero, just a family handing the same wound down the line like an heirloom. You did not flinch from that. Noted.

**Reveal.** heading "how the room ruled" · bars "Leaving the dying is too far" / "They earned that empty room" / "A family that failed each other"

### 7.08 The Good Deed

`verdict (pick one of three)` · `medium` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** A man saved a stranger's life, then held it over them for years, collecting gratitude and favours.

**Lines.**

> **Headline (over the confessor):** I gave him his whole life back.

> **Imp:** Eight. A rescue. And what came after the rescue, which is the actual case.

> **Imp:** Years ago this one pulled a drowning stranger out of a river. Saved his life, no question, no argument, a genuinely brave thing. And has spent every year since reminding him of it. Favours, loyalty, a standing invitation to feel indebted. The man he saved has started screening his calls. State your case.

> **Confessor:** He would be [red]dead[/red]. Do you understand that. [red]Dead[/red], in the ground, twenty years now, if I had not gone in after him. Everything he has, the wife, the kids, the whole little life, all of it is on loan from me.

> **Confessor:** So yes, when I need something, I ask him first. Is that so much. I handed him back the entire world. I think I am allowed to expect a phone call returned.

> **Imp:** A life saved, and then invoiced, forever. Is the rescue still a gift if it never once stops being a bill. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **He turned a rescue into a leash** · crowd 55% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** [red]Guilty[/red]. A good deed with a lifelong interest rate, you are saying, is not a good deed at all, it is a purchase. Clean. He is going to loathe that ruling, because in his own head he has been the hero this entire time, and you have just repriced him as a debt collector with wet shoes.

2. **A life owes something** · crowd 17% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** Cleared. A life is the largest thing there is, so the man who handed it back gets to keep drawing on the account. Forever. You have ruled that gratitude is a debt with no final payment, which, do please think for a moment about who in your own life might be quietly keeping that exact same ledger open on you.

3. **Both drowning, differently** · crowd 28% · profile: none

    > **Imp:** Everyone sucks. The drowning man who will not pick up the phone, and the swimmer who will not stop dialling. One cannot say thank you often enough to ever be free, the other cannot hear thank you without wanting more. Bound together by a river neither of them ever really climbed out of. Poetic. Also exhausting for everyone downstream.

**Reveal.** heading "how the room ruled" · bars "He turned a rescue into a leash" / "A life owes something" / "Both drowning, differently"

### 7.09 The Whistle

`verdict (pick one of three)` · `heavy` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** A woman reported a beloved coworker for something genuinely wrong; the workplace turned on her and the coworker lost everything.

**Lines.**

> **Headline (over the confessor):** I told the truth. It cost me everything.

> **Imp:** Nine. And this one actually asks the question out loud, which most of them are far too proud to do.

> **Imp:** This one reported a coworker. A beloved one, the office favourite, for something genuinely, provably wrong. She was right. It cost the coworker everything. And then the whole office turned on her, not on him, and it cost her everything too. She wants to know if being right is what made her the [red]villain[/red]. State it.

> **Confessor:** What he did was real. I did not invent it, I did not stretch it, I reported exactly what happened and it was bad. Everyone agreed, out loud, that it was bad. And then everyone hated me for being the one who said it.

> **Confessor:** I lost my job over his crime. My friends, my references, the way a room goes quiet when I walk into it now. I was right. I keep telling myself I was right. So why am I the only one who got punished for it.

> **Imp:** The truth told, and the truth teller buried for telling it. Was she the [red]villain[/red] for being right. Rule.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **She should have stayed quiet** · crowd 12% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** [red]Guilty[/red]. Which here means you have looked at a woman who told the truth about a genuine wrong, and ruled that she should have swallowed it whole. Peace over honesty. A workable philosophy, and I do notice it is always the honest one we ask to be quiet, never the one they were being honest about. Interesting little choice.

2. **She did the right thing** · crowd 58% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** Cleared, fully, no asterisk, no small print. She was right, and she paid for it, and you flatly refuse to call the paying a crime. Clean. It will not hand her back the job, or the friends, or the rooms that stop talking when she enters, but she now has one judge, on the record, saying she was not the [red]monster[/red]. That is not nothing. It is very close to nothing. But it is not quite it.

3. **Right, but not clean about it** · crowd 30% · profile: none

    > **Imp:** Everyone sucks, which is a bold thing to say about a woman whose entire crime was being correct. But I think you mean she was right and clumsy with it, righteous in a way that handed the office its excuse to hate her. Maybe. Or maybe you simply could not bring yourself to give a clean verdict to someone the whole crowd had already decided to punish. Even you. Even here. Telling.

**If the player's verdict was the least popular of the three:**

> **Imp:** Sit with that a moment. When I ran this by the room, it did not go where you just went. She would find that either enormously comforting or completely unbearable, and honestly, so would I. Watch.

**Reveal.** heading "how the room ruled" · bars "She should have stayed quiet" / "She did the right thing" / "Right, but not clean about it"

### 7.10 The Two Stories

`verdict (pick one of three)` · `heavy` · profile: Mercy vs Justice · crowd: seeded three-way split

**Staging.** The closer and the one two-confessor case: former best friends file in from either side and tell the same events in flatly contradictory, equally sincere ways. No evidence is coming, ever, and the player never learns which story is true.

**Lines.**

> **Headline (over her, on the left):** He told everyone.

> **Headline (over him, on the right):** She blamed me to survive it.

> **Imp:** Last case. And this is the one that used to keep you awake at night, back when the bench was real wood and the people in front of it still had [red]blood[/red] in them.

> **Imp:** [amber]Two[/amber] souls. [amber]One[/amber] story. And it does not match. These two were the closest of friends for the better part of their lives, until something between them ended it, hard. They are each going to tell you what happened. They are going to tell you two completely different things.

> **Imp:** And here is the part you are going to hate. Neither of them is lying. Not on purpose. Both of them believe every single word. You will never know which one is true. Neither will I. Ready.

> **Confessor A (her):** I told him [amber]one[/amber] thing. [amber]One[/amber]. The single worst thing I have ever done, a thing I never breathed to another living soul, and I told him because he was my best friend and I trusted him with my whole life.

> **Confessor A (her):** And he told people. He told everyone. He took the one secret I had and handed it round like gossip at a bus stop, and he watched my entire life come apart, and he has never once admitted that it was him.

> **Confessor B (him):** That is not what happened. She told me that secret, yes. And then she told other people herself, drunk, at a party, and panicked in the morning, and needed a body to pin it on.

> **Confessor B (him):** So she picked me. Her best friend. She decided I was the leak because she could not survive being it, and she has told that story so many times now that she genuinely believes it. I lost her over something she did to herself.

> **Imp:** So rule. On testimony that cancels clean out, with no evidence coming, not ever. Which of them wronged the other. This is the whole job, judge. It always was.

**Choices** (the three verdicts: the confessor is in the wrong / is not in the wrong / everyone sucks).

1. **Believe her** · crowd 36% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** You believed her. On nothing. On a feeling, on the way she said it, on some tell you are certain you caught, exactly the way you did it from the bench for [amber]thirty years[/amber]. Maybe you are right. You will never find out. That is the job. That was always the job.

2. **Believe him** · crowd 30% · profile: Mercy vs Justice +0.5 (toward justice)

    > **Imp:** You believed him. Also on nothing, because there is nothing here, there is only two people and one of them is wrong and cannot feel it. You picked a side. Judges pick. It does not make it true. It just makes it over, for everyone except the two of them.

3. **There is no knowing** · crowd 34% · profile: Mercy vs Justice -0.5 (toward mercy)

    > **Imp:** You refused to pick. No way to know, so no verdict. Honest. And also completely useless to the two people standing right here who needed this to finally end. For [amber]thirty years[/amber] they never once let you say I cannot know. They made you rule anyway. I am almost impressed you got to say it at last. They are not impressed. Look at them.

**Reveal.** heading "how the room ruled" · bars "Believe her" / "Believe him" / "There is no knowing"

### Imp · Closer

> **Imp:** Court is adjourned. You ruled on a reclined seat, a white dress, a [red]deathbed[/red] promise, and [amber]two[/amber] people telling [amber]one[/amber] story, and you did not once flinch from the bench.

> **Imp:** Funny thing about judging. It never tells me whether you were right. It is not built to. It only ever shows me how you reach for a verdict, and how fast, and where you look while you decide. Which is, of course, the only thing I was ever watching.

> **Imp:** The docket is empty. For now. Step down, judge. You are very good at this. That was never quite the compliment you took it for.

---

## Chapter 8: The Campaign

A tiny DnD-style tabletop adventure with the imp as a bad, controlling, over eager Dungeon Master who railroads the player and lampshades it. Earnest fantasy (knights, a tavern, a cursed hoard, a dragon) against the imp constantly breaking it. Linear with the illusion of choice: a class picked at the start unlocks a unique option at key beats, and a few flags (the companion, the village) change later options and text, but the path never forks. No combat or stat system. The die appears at exactly two beats. The sanctioned break is the cheat-the-roll secret ending.

### Imp · Intro

> **Imp:** New game. New everything. Put the tracks and the buttons and the gun clean out of your head, we are doing something completely different tonight, you and I. We are going on an adventure.

> **Imp:** I am going to be your Dungeon Master. It is a game the living play, with dice and heroes and dragons, and the whole point is that I describe a world and you [amber]pretend[/amber] to walk through it and make choices, and I [amber]pretend[/amber] those choices matter. I am very good at it. I have never once let anybody win who I did not want to.

> **Imp:** So sit up. Roll up a hero. Try, for one hour, to be a [amber]knight[/amber] instead of a [amber]defendant[/amber]. It will not last. It never does. But let us find out who you are when there are dragons in front of you instead of dilemmas. Begin.

### 8.01 Your Class

`doodle menu, 5 options` · `character read` · profile: a light nudge for every class · crowd: seeded counts (total 100)

**Staging.** A character-creation menu: five coloured doodles in a row, each over its label (knight: a sword over a heraldic shield, steel blue; rogue: a dagger, green; wizard: a pointed star-flecked hat, purple; bard: a lute, orange; cleric: a chalice, gold). Click one (number keys 1 to 5 also pick). The pick becomes the hero's class for the rest of the chapter.

**Lines.**
> **Imp:** New game. Forget the tracks, forget the buttons, we are doing something completely different tonight, and I have been looking forward to it for an embarrassingly long time.

> **Imp:** You are an adventurer now. I am the Dungeon Master. That means I built this entire world, I know everything that is going to happen in it, and you get to sit there and [amber]pretend[/amber] your choices matter. They will not, particularly. But you get to pretend, and that is the fun part, for me.

> **Imp:** So. What kind of hero are you. Choose carefully. It decides [amber]absolutely nothing[/amber], and also [amber]the whole rest of your night[/amber].

> **Imp:** Pick your class. *(prompt line; the options appear after it)*

Note: in the build these lines play straight after the chapter intro, which also opens on "New game." and also introduces the imp as Dungeon Master, so the opening idea is said twice back to back.

**Choices.**
1. **The Knight** · crowd 34 · profile: Order vs Freedom -0.4 (toward order)
   > **Imp:** A knight. Honour, a big sword, a jaw you could set a table on. You will do the right thing at every turn and [red]die[/red] nobly, and bore absolutely everyone at the funeral.
2. **The Rogue** · crowd 27 · profile: Self vs Others -0.4 (toward self)
   > **Imp:** A rogue. You checked me for a coin purse while I was still explaining the rules. I saw that. We are going to get along horribly.
3. **The Wizard** · crowd 22 · profile: Risk vs Safety +0.3 (toward safety)
   > **Imp:** A wizard. Naturally. You will solve every problem by explaining it to death, and I will sit here pretending the rules of magic are consistent. They are not. I [amber]invent[/amber] them as I go. So do you, it turns out.
4. **The Bard** · crowd 10 · profile: Self vs Others +0.3 (toward others)
   > **Imp:** A bard. You are going to try to talk your way past a dragon at some point tonight, and honestly a small part of me cannot wait to watch that not work.
5. **The Cleric** · crowd 7 · profile: Self vs Others +0.4 (toward others)
   > **Imp:** A cleric. Faith, mending, a good and tender heart. You will spend the whole night healing people who were going to be perfectly fine, and calling it a calling.

**Reveal.** heading "how others built their hero" · bars "The Knight" / "The Rogue" / "The Wizard" / "The Bard" / "The Cleric". Every reveal in this chapter works the same way: one bar per option the player was actually shown, in option order, the player's pick in amber; the number beside each bar is its seed shown as a plain count (no % sign), and bar length is relative to the largest seed. The shared stats hint "press any key to go again" sits under the bars at every reveal.

**Flags / state.** Sets the class (knight, rogue, wizard, bard or cleric). Read by 8.03 (the setup line) and by 8.04, 8.06, 8.07 and 8.09 (the one class option each beat adds). The class and all the other campaign flags live only for this chapter and are not in the save, so a mid-chapter Continue resumes with no class and no flags; the fallbacks this triggers are noted in each beat.

### 8.02 Your Reason

`doodle menu, 4 options` · `light` · profile: a light Self vs Others read (three of four options) · crowd: seeded counts (total 100)

**Staging.** The same doodle menu with four options: a small stack of coins (gold), a two-handled trophy cup (orange), a plain heart (pink), a crossroads signpost (muted grey).

**Lines.**
> **Imp:** Every hero needs a reason. It is called motivation. I read half a book about it once and then got bored, which is also a kind of motivation.

> **Imp:** So why are you doing this. Why does a [red]dead[/red] judge pick up a sword and march off into a story. Be honest, I already know, I [amber]wrote[/amber] you.

> **Imp:** Why are you here? *(prompt line)*

**Choices.**
1. **For the gold** · crowd 30 · profile: Self vs Others -0.3 (toward self)
   > **Imp:** Gold. Refreshingly honest. A [red]dead[/red] man chasing a pile of money he cannot spend, in a kingdom that is [amber]not real[/amber]. I could not have written you better myself, and I did.
2. **For the glory** · crowd 24 · profile: Self vs Others -0.2 (toward self)
   > **Imp:** Glory. The songs, the statues, a tavern named after you. You, a man nobody in the waking world will remember by next Thursday, want the [amber]imaginary[/amber] people to chant your name. It is almost sweet.
3. **To save someone** · crowd 31 · profile: Self vs Others +0.3 (toward others)
   > **Imp:** To save someone. Noble. There is nobody to save, they are all made of me, but the reflex is lovely. A man who cannot save himself, off to rescue a stranger I [amber]invented[/amber]. I will allow it.
4. **Nowhere else to be** · crowd 15 · profile: none
   > **Imp:** Nowhere else to be. Ha. There it is. The truest answer a [red]dead[/red] man ever gave me. You are here because I am the only thing still happening to you. Come on then. Let us make the nothing count.

**Reveal.** heading "why others answered the call" · bars "For the gold" / "For the glory" / "To save someone" / "Nowhere else to be"

**Flags / state.** Sets the reason (gold, glory, rescue or nowhere). No later beat reads it in the current build.

### 8.03 The First Roll

`dice roll, no options` · `dice beat 1` · profile: none · crowd: none (no reveal)

**Staging.** The imp sets up a class-flavoured obstacle, then a hand-drawn ink d6 appears with an odds caption under it. Any click or key press rolls it: the die tumbles, slows, lands on a face with an amber flash, and the imp narrates the result. Clear it or not, the story rolls on unchanged; the beat exists to teach the die.

**Lines.**
> **Imp:** *(setup, one of, by class)*
> - *Knight:* A chasm splits the road ahead, wider than sense allows. A knight does not go around a chasm. A knight backs up, and takes a run at it.
> - *Rogue:* A locked gate, an old and clever lock, and your picks in your hand. Most locks open for a rogue. Most of them. Let us find out about this one.
> - *Wizard:* A warded door, humming with someone else's spell, and you reaching for the counter you are almost, almost certain is the right one.
> - *Bard:* A bridge troll wants a toll, or a song, and you have decided, against all advice including mine, on a song.
> - *Cleric:* A fevered child at the roadside, too hot to the touch, and your two hands, and a prayer you are not at all certain will land.
> - *No class set (only after a mid-chapter Continue or a dev jump, since the class is not saved):* A chasm splits the road ahead, wider than sense allows, and you back up to take a run at it.

> **Imp:** This is the part where we roll. See the die. [amber]Six[/amber] sides, [amber]one[/amber] number, pure dumb chance, and for one moment neither of us is in charge of the story. Not you. Not even me. I love it and I hate it in exactly equal measure.

> **Narration:** roll a [amber]{0}[/amber] or higher and you clear it *(odds caption under the die, shown as the die appears; {0} = the target, 3)*

> **Imp:** Go on. Roll it. Click the die, click anything, I am not precious about the how.

*(any click or key press rolls the die)*

> **Imp:** *(result, one of)*
> - *3 to 6, cleared:* It comes up good. You clear it, clean and lucky and completely undeserved. Feel that little jolt in your chest just now, that warm rush. That is luck, and you, my friend, are already hooked on it.
> - *1 or 2, not cleared:* It comes up short. You do not clear it. The fall, the splash, the indignity, all rendered in loving detail. Do not panic, you are the protagonist, you are fine. But do notice how betrayed you feel. By a cube. That I [amber]control[/amber].

> **Imp:** Interesting, how fast you took a number personally. A die landed and you already have feelings about whether the universe is fond of you. Hold onto that feeling. We are going to want it later, when it actually counts.

*(the die fades away; the beat ends)*

**Flags / state.** Reads the class (setup line only). The two result lines are the same for every class, so the miss line's "fall" and "splash" (written for the chasm) also play after the gate, the door, the troll and the child. Sets nothing; the result is not remembered.

**Tunables.** A fair d6 (each face 1 in 6). Target 3 or higher: clears 4 times in 6 (about 67%).

### 8.04 The Tavern

`ink-label row, 4 options + 1 class option` · `choice, class option` · profile: light, three of the common options only · crowd: seeded counts (total 98 to 104, by class option)

**Staging.** A gold coin-stack doodle sits over the scene while the imp talks. The options are plain ink labels in a row: four common options plus the one option for the player's class (five labels).

**Lines.**
> **Imp:** The Salted Hog. A tavern. It smells of ale and [amber]imaginary[/amber] vomit, which I rendered for you lovingly. In the corner, a nervous man waves you over. Your quest giver.

> **Imp:** He is [red]lying[/red]. I want to be clear about that up front, as your Dungeon Master, breaking every rule of my craft: this man is [red]lying[/red] to your face. The reward is too big, the job is too simple, and he keeps glancing at the door. [red]Slay[/red] the beast in the northern barrow, he says, and this chest of gold is yours.

> **Imp:** So. What do you do about the obvious [red]liar[/red] and his beautiful, obvious lie.

> **Imp:** Your move. *(prompt line)*

**Choices.**
1. **Take the job** · crowd 30 · profile: none
   > **Imp:** You take it. No questions, no haggling, straight into the trap with a grin. [amber]Bold[/amber]. [amber]Stupid[/amber]. My favourite kind of player, honestly. You make the night move.
2. **Haggle harder** · crowd 22 · profile: Self vs Others -0.2 (toward self)
   > **Imp:** You haggle. Over pretend gold. With a known [red]liar[/red]. In a bar I invented this afternoon. And you drive a hard bargain and win forty imaginary extra coins and feel genuinely proud. I am not mocking you. I am. But gently.
3. **Threaten him** · crowd 15 · profile: Order vs Freedom +0.2 (toward freedom)
   > **Imp:** You lean in and threaten him and he goes pale, because I [amber]made[/amber] him go pale, because you are the player and my little people are frightened of you by default. It is a cheap thrill. You took it anyway. Noted.
4. **Walk away** · crowd 13 · profile: Risk vs Safety +0.2 (toward safety)
   > **Imp:** You walk. From the plot. On the very first beat. You magnificent coward. Do not worry, the plot walks after you. It knows where you live. It is called a main quest for a reason. Now sit back down.
5. *Class option: exactly one of these appears, the one for the player's class (none if no class is set):*
   - **Make him swear it on his honour** *(knight only)* · crowd 19 · profile: none
     > **Imp:** The knight makes the [red]liar[/red] swear the reward on his honour, and he does, sweating, because a knight asked and the code compels a made up man to answer. He is still lying. Now he is lying under oath. You have achieved nothing but paperwork, nobly.
   - **Lift his purse while he lies** *(rogue only)* · crowd 21 · profile: none
     > **Imp:** While he spins his tale you lift his purse clean off his belt. Inside: [amber]eleven[/amber] coins and a note that reads [amber]do not trust him[/amber]. You already knew. You take the job anyway, now down a friend and up a purse. Rogues.
   - **List the three holes in his story** *(wizard only)* · crowd 18 · profile: none
     > **Imp:** You calmly recite the [amber]three[/amber] holes in his story. He blinks. He had not noticed hole two himself. You have out plotted the plotter, who is me, which is annoying. Fine. He confesses half of it. You take the job anyway, because knowing it is a [amber]trap[/amber] has never once stopped anybody.
   - **Charm the real terms out of him** *(bard only)* · crowd 24 · profile: none
     > **Imp:** You turn the charm on and he melts and tells you the real deal, which is worse, obviously, and you take it anyway, because you are having a lovely time and the danger belongs to the character you are pretending to be.
   - **Ask what he is so afraid of** *(cleric only)* · crowd 20 · profile: none
     > **Imp:** You ask him, gently, what he is so afraid of. And the [red]liar[/red] stops lying, just for a second, and looks very tired, and I did not plan for that, and now I feel strange about my own NPC. Thanks for that. You take the job. He wishes you luck and, oddly, means it.

**Reveal.** heading "what others did at the table" · bars "Take the job" / "Haggle harder" / "Threaten him" / "Walk away" / the class option that was shown

**Flags / state.** Reads the class (which class option appears). Sets nothing; every option leads to the same next beat.

### 8.05 The Fork

`ink-label row, 2 options` · `choice, chains` · profile: Risk vs Safety on both options · crowd: seeded counts (total 100)

**Staging.** A crossroads signpost doodle (muted grey) sits over the scene; two plain ink labels.

**Lines.**
> **Imp:** A fork in the road. Ahead, the long way: [amber]safe[/amber], well travelled, dull, and a good hour out of your evening. To the left, a [amber]shortcut[/amber] through the Whispering Wood.

> **Imp:** I, your impartial and trustworthy Dungeon Master, promise you the shortcut is completely fine. Totally [amber]safe[/amber]. Nothing lives in the Whispering Wood. Why would it be called that. Do not think about the name. Take the shortcut. It is fine.

> **Imp:** That was me doing a voice, by the way. The voice of a DM steering you straight at the encounter I already built and do not want to waste. You can still take the long road and ruin my whole afternoon. Genuinely. Your call.

> **Imp:** Which way? *(prompt line)*

**Choices.**
1. **The safe long road** · crowd 41 · profile: Risk vs Safety +0.4 (toward safety)
   > **Imp:** You take the long, safe, sensible road, and nothing happens, at length, in detail, for an hour, exactly as promised. It is the most responsible thing anyone has done to me all night. I am bored senseless. You are perfectly [amber]safe[/amber]. Congratulations on both counts.
2. **The dangerous shortcut** · crowd 59 · profile: Risk vs Safety -0.4 (toward risk)
   > **Imp:** You take the shortcut, into the wood that is definitely fine, and three separate things immediately try to eat you, and you are delighted, and so am I. See. This is why we take the shortcut. Nobody has ever told a story about the long road.

**Reveal.** heading "which road others took" · bars "The safe long road" / "The dangerous shortcut"

**Flags / state.** Sets the shortcut flag (on for the shortcut, off for the long road). Read by the first line of 8.08.

### 8.06 The Companion

`ink-label row, 3 options + 1 class option` · `choice, chains, class option` · profile: Self vs Others, common options only · crowd: seeded counts (total 94 to 101, by class option)

**Staging.** A hooded-stranger doodle (purple) sits over the scene. Three common options plus the one option for the player's class (four labels). Every option sets how the companion was treated.

**Lines.**
> **Imp:** On the road, a figure falls into step beside you. Cloaked, hooded, a little too eager. They would like to join your quest. For reasons. Which they do not offer.

> **Imp:** As your DM, in the interest of fair play, I will tell you plainly: this one is [amber]hiding something[/amber]. I know exactly what, because I [amber]wrote[/amber] it, and it is a doozy, and I am not going to tell you, because that would be telling.

> **Imp:** They hold out a hand. What do you do.

> **Imp:** The stranger waits. *(prompt line)*

**Choices.**
1. **Trust them** · crowd 33 · profile: Self vs Others +0.3 (toward others) · sets the companion to *trusted*
   > **Imp:** You take their hand and [amber]trust[/amber] them completely. A stranger. Hooded. On a road. In a haunted wood. Beautiful. You would have been eaten twice already tonight if I ran that wood properly. Welcome aboard, mystery friend.
2. **Refuse them** · crowd 26 · profile: Self vs Others -0.3 (toward self) · sets the companion to *refused*
   > **Imp:** You refuse. No thank you, spooky stranger. They nod, and drift back into the trees, and something goes out of their shoulders, and you will not see them again. Probably. [amber]Safe[/amber]. A little [amber]lonely[/amber]. Your call.
3. **Use them, then ditch them** · crowd 18 · profile: Self vs Others -0.4 (toward self) · sets the companion to *used*
   > **Imp:** You let them join, already planning to drop them the second they stop being useful. Cold. Efficient. I love it, and I am also a little frightened of you, and I am the deathless narrator of a void, so that is saying something.
4. *Class option: exactly one of these appears, the one for the player's class (none if no class is set):*
   - **Vouch for them on your honour** *(knight only)* · crowd 22 · profile: none · sets the companion to *trusted*
     > **Imp:** The knight extends his honour over a total stranger like an umbrella, and it holds, because that is what honour is for. They are moved. They will remember this. So, it turns out, will I.
   - **Clock their tell, keep them close** *(rogue only)* · crowd 20 · profile: none · sets the companion to *used*
     > **Imp:** You read them in a single glance, the tell, the thing they are hiding, and you keep them near precisely so you can spend it later. One rogue recognising another. This will go great, and by great I mean badly, and by badly I mean memorably.
   - **Interrogate every inconsistency** *(wizard only)* · crowd 17 · profile: none · sets the companion to *refused*
     > **Imp:** You cross examine them until the story collapses, which it does, because I built it to, and then, being a wizard, you refuse them on principle. Correctly. Coldly. Completely without backup. Enjoy being right on the road alone.
   - **Win them over utterly** *(bard only)* · crowd 24 · profile: none · sets the companion to *trusted*
     > **Imp:** You turn on the full bardic charm and they open right up, or nearly, and pledge themselves to you, terrible secret and all, which is the best kind of companion. Ask any story.
   - **Offer grace, no questions** *(cleric only)* · crowd 21 · profile: none · sets the companion to *trusted*
     > **Imp:** You offer them grace without a single question, which is either deep [amber]wisdom[/amber] or deep [amber]naivety[/amber], and honestly in a cleric those look identical. They accept, quietly. Something in them unclenches. I did not build that in. You did.

**Reveal.** heading "how others met the stranger" · bars "Trust them" / "Refuse them" / "Use them, then ditch them" / the class option that was shown

**Flags / state.** Reads the class. Sets the companion flag (trusted, refused or used, as marked on each option). Read at 8.09 (the companion line and the situational option) and 8.10 (the intro line). Trusted and used both count as the companion being with you at the end; refused means they are absent.

### 8.07 The Village

`ink-label row, 2 options + 1 class option` · `heavy dilemma 1, class option` · profile: Ends vs Rules ±0.5, common options only · crowd: seeded counts (total 97 to 101, by class option)

**Staging.** A reared grizzly doodle (brown) stands in for the cornered beast. Two common options plus the one option for the player's class (three labels). Every option sets the village flag.

**Lines.**
> **Imp:** The barrow. The beast the whole village fears, cornered at last in the dark at the far end of it. And here is the thing nobody mentioned back in the tavern.

> **Imp:** It is afraid. Backed against the stone, making a sound that is not a roar, and there is no blood on it anywhere, and the tracks at the barrow mouth, the ones by where the child went missing, those were a person's boots, not this. It might have done nothing at all. It might be exactly what they said. You cannot tell, and you are never going to be able to.

> **Imp:** The village wants it [red]dead[/red]. [red]Kill[/red] it and they cheer you through the streets and the relic it guards is yours and the quest goes on. Spare it and you defy a frightened village on a hunch, the harder road, no reward, no relic pressed into your hands with a grateful smile. And yes, I know, I built this one to feel like the tracks. You are welcome. Rule on it, judge.

> **Imp:** The beast waits on your verdict. *(prompt line)*

**Choices.**
1. **Kill it, take the relic** · crowd 36 · profile: Ends vs Rules -0.5 (toward ends) · sets the village to *did the ugly thing*
   > **Imp:** You put the cornered, pleading, possibly innocent thing down on the word of a mob, and take your relic, and the village carries you through the streets. It felt necessary. It photographs as heroism. And somewhere under all of it a small dry voice that sounds a great deal like a courtroom asks whether you were [amber]sure[/amber]. You were not. You never are. That was always the whole job.
2. **Spare it, defy the village** · crowd 34 · profile: Ends vs Rules +0.5 (toward rules) · sets the village to *spared*
   > **Imp:** You lower your weapon and let the frightened thing live, defying a whole armed village on nothing but a bad feeling and some boot prints. They are furious. They spit at your noble back. No relic, no cheering, no reward. Just you, [amber]right[/amber] or [amber]wrong[/amber], with no way on earth to know which, walking out poorer than you walked in. Deeply irritating. Deeply you.
3. *Class option: exactly one of these appears, the one for the player's class (none if no class is set):*
   - **Put the beast on trial, here, now** *(knight only)* · crowd 30 · profile: none · sets the village to *spared*
     > **Imp:** The knight holds a trial. In a barrow. For a beast. With himself as judge, jury, and sole attendee, which is, now I think about it, more due process than a great many defendants ever got out of you. Verdict: [amber]not proven[/amber]. You let it go. The village will never forgive you the pageantry. Worth every second.
   - **Kill it clean, tell the village nothing** *(rogue only)* · crowd 28 · profile: none · sets the village to *did the ugly thing*
     > **Imp:** One clean stroke, the relic in your bag, and not one word to anybody about the pleading or the boot prints. The village gets its [red]dead monster[/red], you get your prize, and the doubt goes into the barrow with the thing that maybe did nothing. Tidy. That is the frightening kind of tidy, the kind that sleeps fine.
   - **Read the tracks, prove what happened** *(wizard only)* · crowd 27 · profile: none · sets the village to *spared*
     > **Imp:** You read the ground like a page and prove, more or less, that this thing did nothing, and the child was taken by two boots and an old grudge. You are right. Being right saves the beast and convinces nobody, because a scared village does not want evidence, it wants a [red]monster[/red]. You hand them neither. They hate you for it. Correctly, from where they stand.
   - **Talk the village down from its fear** *(bard only)* · crowd 31 · profile: none · sets the village to *spared*
     > **Imp:** You turn and talk a frightened mob out of its own fear, which is the single hardest save in this whole game, and you make it, barely, and the beast lives, and [amber]half[/amber] the village goes home ashamed and [amber]the other half[/amber] goes home furious, which is exactly what talking a mob down actually looks like, whatever the songs pretend.
   - **Kneel and tend the frightened thing** *(cleric only)* · crowd 29 · profile: none · sets the village to *spared*
     > **Imp:** You kneel, in front of the whole armed village, and tend the frightened thing as though it were a person, because to you everything is. It stops shaking. The village does not know what to do with that, and, if I am honest, neither do I. No relic. No reward. Something else instead, something that does not spend.

**Reveal.** heading "how the party ruled in the barrow" · bars "Kill it, take the relic" / "Spare it, defy the village" / the class option that was shown

**Flags / state.** Reads the class. Sets the village flag: *spared* (the beast lives) or *did the ugly thing* (the beast is killed), as marked; only the rogue's class option kills. Read at 8.09 (the village line and the situational option) and 8.10 (the intro line): *spared* means the villagers come to help at the boss.

### 8.08 The Treasure

`ink-label row, 3 options` · `choice / dilemma 2` · profile: every option · crowd: seeded counts (total 100)

**Staging.** An open treasure-chest doodle (gold) sits over the scene. Three plain ink labels, no class option. The first line calls back the fork.

**Lines.**
> **Imp:** *(fork callback, one of, by the shortcut flag)*
> - *Took the shortcut:* The shortcut spat you out right on top of it, which is the one good thing that wood ever did for anybody.
> - *Took the long road (also plays when the flag is unset, e.g. after a mid-chapter Continue):* The long road got you here eventually, footsore and thorough, but it got you here.

> **Imp:** Deep in the barrow you find it. A hoard. Gold to the ceiling, and resting on the pile, a black blade that hums. [amber]Cursed[/amber]. [amber]Powerful[/amber]. The kind of thing that solves your every problem and takes a small piece of you for each one it solves.

> **Imp:** Now. Here is where I, as your Dungeon Master, lean in and watch very closely. Because the quest is still out there, waiting, important, the entire point of the evening. And here is a room with everything you came for in it, and no dragon.

> **Imp:** You could take the [amber]cursed blade[/amber]. You could scoop the [amber]gold[/amber] and simply leave, quest be damned. Or you could walk past all of it and stay the course. I honestly do not know which you will do, and that is rare for me. Go on.

> **Imp:** The hoard glitters. *(prompt line)*

**Choices.**
1. **Take the cursed blade** · crowd 38 · profile: Ends vs Rules -0.4 (toward ends) · sets "grabbed the treasure"
   > **Imp:** You take the humming black blade, and it purrs, and something behind your eyes goes a little dim, and you feel wonderful, which is exactly how it always begins. [amber]Power[/amber] for [amber]parts[/amber]. You will not miss the parts. That is the whole trick of a curse. Lovely choice.
2. **Grab the gold and go home** · crowd 24 · profile: Self vs Others -0.5 (toward self) · sets "grabbed the treasure"
   > **Imp:** You scoop the gold and turn for the door, abandoning the entire quest on the very doorstep of its treasure, and I want you to know, as a storyteller, that this is the single most honest thing a player has ever done in one of my campaigns. It is also [amber]not allowed[/amber]. Sit down. I built a dragon. We are seeing the dragon. Bring the gold, fine. But we are seeing the dragon.
3. **Leave it, keep to the mission** · crowd 38 · profile: Self vs Others +0.35 (toward others)
   > **Imp:** You walk past a literal room of gold and a literal cursed sword of power to go finish a job for a man who [amber]lied[/amber] to your face. That is either the noblest thing I have watched all night or a diagnosable condition, and in you I genuinely cannot tell which, and that is the kindest thing I can say about a person.

**Reveal.** heading "what others did in the hoard" · bars "Take the cursed blade" / "Grab the gold and go home" / "Leave it, keep to the mission"

**Flags / state.** Reads the shortcut flag (first line). Sets "grabbed the treasure" for the blade or the gold; no later beat reads it in the current build. Every option continues to the dragon (the gold option is railroaded back in its own line).

### 8.09 The Boss

`ink-label row, 3 options + class option + situational option` · `heavy, class + flags` · profile: light, three options only · crowd: seeded counts (total 99 to 103, by class and flags)

**Staging.** A large red-outlined dragon doodle sits over the scene. The narration is assembled from the companion and village flags, and the options are three common approaches, the player's class option, and one situational option picked by the flags (five labels).

**Lines.**
> **Imp:** The dragon. The one I built the entire evening around. It is bigger than it strictly needed to be, because I got excited making it, and I regret nothing. It uncoils out of the dark and fixes on you.

> **Imp:** *(companion line, one of, by how the companion was treated in 8.06)*
> - *Trusted:* Your companion is at your shoulder, hood down at last, blade drawn. The stranger you trusted turned out to be worth trusting. You are not alone up here. Most people reach my dragon having burned every last bridge behind them. Not you. Huh.
> - *Used:* Your companion is here too, at your shoulder, though they will not meet your eye. You used them, and they know it, and they came anyway, which is either [amber]loyalty[/amber] or a [amber]plan[/amber], and with this one I could not honestly tell you which.
> - *Refused (also plays when the flag is unset, e.g. after a mid-chapter Continue):* You face it alone. The stranger who offered to walk with you is somewhere far behind, sent off at the crossroads, and there is only you up here now, which is exactly how the songs pretend a hero wants it.

> **Imp:** *(village line, one of, by the village flag from 8.07; skipped entirely if the flag is unset)*
> - *Spared:* And there, cresting the hill behind you, the village. Pitchforks, torches, terrible courage. The people you spared in the barrow, come to stand at a dragon's feet for a stranger. I did not build them to do that. Your [amber]mercy[/amber] did.
> - *Did the ugly thing:* The village is not coming. Their doors are barred and their shutters are down, because a village does not march on a dragon for the man who did what you did in the barrow. You [amber]bought[/amber] the relic. It [amber]cost[/amber] you the militia. Everything costs something here, especially here.

> **Imp:** So here it is, judge. The whole night comes down to this room. It looks at you and waits. How do you take a dragon.

> **Imp:** The dragon waits. *(prompt line)*

**Choices.**
1. **Fight it** · crowd 34 · profile: none
   > **Imp:** You fight it. Sword and fury and no plan beyond hitting the dragon until the dragon stops being a dragon. It is the option every table reaches for and it is never once the clever one, and it works about [amber]half[/amber] the time, which is somehow better odds than clever, and I hate that.
2. **Talk it down** · crowd 22 · profile: Mercy vs Justice -0.2 (toward mercy)
   > **Imp:** You try to talk down a dragon. A DRAGON. And because I am a soft touch and I secretly live for the moment a player tries the completely mad thing, I let it half work. It listens. Dragons are older than the kingdoms and bored out of their enormous skulls, and sometimes the maddest thing you can do to one is simply make conversation.
3. **Trick it** · crowd 21 · profile: none
   > **Imp:** You trick it. A feint, a lie, a neat little piece of misdirection, because if you cannot out muscle a dragon you can out think one, and this dragon, for all its size, has the strategic mind of a very large, very warm cat. It falls for it. Mostly. Enough.
4. *Class option: exactly one of these appears, the one for the player's class (none if no class is set):*
   - **Challenge it to single combat** *(knight only)* · crowd 14 · profile: none
     > **Imp:** You challenge a dragon to single combat by the old code, and the ridiculous thing is it accepts, because dragons are vain and a formal duel appeals to something ancient in them. Honour against a lizard the size of a barn. Somewhere your old bench is applauding and appalled in exactly equal measure.
   - **Go for the soft spot under the wing** *(rogue only)* · crowd 13 · profile: none
     > **Imp:** You go for the one soft spot under the wing, the unglamorous, unheroic, wholly effective spot, while it is busy being a dragon at you. No song will ever mention it. Every song leaves out the part where the hero wins dirty. You know why. Because winning [amber]dirty[/amber] is how heroes actually win.
   - **Unbind the spell that chains it here** *(wizard only)* · crowd 12 · profile: none
     > **Imp:** You stop swinging and start reading, and you find the spell chaining the thing to this barrow, the leash, and you unpick it, and the dragon, suddenly free, looks at you with something almost like gratitude before it decides what to do about you. You [amber]gambled[/amber] the entire fight on being right. Very wizard. Very brave. Do not ever do it again.
   - **Sing the one song that unmakes it** *(bard only)* · crowd 13 · profile: none
     > **Imp:** You sing it the one song, the old one, the one that unmakes a dragon, and I have to allow it, because three hours ago I [amber]wrote a rule[/amber] that said a good enough performance beats anything, and here we are, and it is genuinely beautiful, and I am furious, and you are magnificent.
   - **Offer it peace, and mean it** *(cleric only)* · crowd 12 · profile: Mercy vs Justice -0.2 (toward mercy)
     > **Imp:** You offer a dragon peace, and you mean it, all the way to the floor, and the terrible thing about meaning it is that sometimes it simply works, and the single most dangerous creature in my whole world just, quietly, decides not to be. You did not [amber]defeat[/amber] it. You [amber]forgave[/amber] it into standing down. I do not have a rule for that. I am writing one now, while you watch.
5. *Situational option: exactly one of these appears, the first whose condition holds:*
   - **Finish it together** *(if the companion was trusted, whatever the village)* · crowd 12 · profile: Self vs Others +0.2 (toward others)
     > **Imp:** You and the one you trusted hit it as one, two blades and a shared plan, and it is exactly the kind of moment I was hoping somebody would earn tonight, and almost nobody does, because almost nobody trusts the hooded stranger on the road. You did. Look at it. Look at what [amber]trust[/amber] buys.
   - **Put your life in their hands now** *(if the companion was used, whatever the village)* · crowd 11 · profile: none
     > **Imp:** You turn to the companion you used and, at the [amber]one[/amber] moment it truly matters, you put your life in their hands. And they look at you. And there is a long, long beat where even I, who wrote them, do not know what they will do. Then they move. You will have to work out later whether it was for you or in spite of you. Not now. Now there is a dragon.
   - **Loose the village on it** *(if the companion was refused and the beast was spared)* · crowd 12 · profile: Self vs Others +0.2 (toward others)
     > **Imp:** You raise one hand and a whole village you once spared pours past you at a dragon, which is insane, and glorious, and works, roughly, at a cost, the way a mob always does. You did not do this alone. You did it because once, in a barrow, you were [amber]merciful[/amber] and poor about it. Funny, how that comes back around.
   - **Throw everything you have left at it** *(otherwise: the companion was refused and the beast was killed, or the flags are unset)* · crowd 10 · profile: none
     > **Imp:** No companion, no village, no cavalry over the hill. Just you and the too big dragon and whatever you happened to walk in carrying. You throw all of it at the thing at once, holding nothing back, because there is nothing behind you left to save it for. It is desperate, and lonely, and, fine, all right, a little magnificent.

**Reveal.** heading "how others took the dragon" · bars "Fight it" / "Talk it down" / "Trick it" / the class option that was shown / the situational option that was shown

**Flags / state.** Reads the class, the companion flag and the village flag. Sets nothing; there is no win or loss here, every approach leads to 8.10. Copy note (as built): the spared-village line and "Loose the village on it" speak of a village (and "the people") you spared, but in 8.07 what you spare is the beast, defying the village; likewise the ugly-thing line has the village refuse to march for what you did, though in 8.07 the village wanted the beast dead and cheered the kill. The refused-companion line says the stranger was "sent off at the crossroads", though the stranger is met on the road after the fork.

### 8.10 The Roll That Decides It

`ink-label row, 3 options, then a dice roll` · `dice beat 2, finale, secret ending` · profile: none · crowd: seeded counts (total 100), revealed only after the honest or refuse path

**Staging.** After three lines the three paths appear as plain ink labels (no prompt line). Honest: a hand-drawn ink d6 appears with an odds caption, any click or key press rolls it, and it needs a 5 or higher. Fix: the secret ending, with no roll and no reveal. Refuse: settled in narration with no die. The honest and refuse paths end on the crowd reveal, after which the chapter closer plays.

**Lines.**
> **Imp:** One thing left. The very end of it. Everything you did tonight, the hero you built, the stranger, the barrow, the hoard, the dragon, all of it funnels down to a single final roll. [amber]Make[/amber] it and the story ends the way stories are meant to. [amber]Miss[/amber] it and it does not.

> **Imp:** *(one of, by who came with you: "companion" means the companion was trusted or used in 8.06; "village" means the beast was spared in 8.07)*
> - *Companion and village:* You did not come to the end of this alone, a companion at your side and a whole village at your back, and I want you to know I noticed, because almost nobody arrives here with anyone left.
> - *Companion only:* You did not come to the end of this alone, which is rarer than you would think, and I noticed.
> - *Village only:* A village you spared stood with you to get here, which almost nobody earns, and I noticed.
> - *Neither (also plays when the flags are unset, e.g. after a mid-chapter Continue):* You came all this way on your own, every step, which makes what comes next that little bit lonelier.

> **Imp:** Now. I am going to make you an offer, as your warm and generous Dungeon Master. You can take the [amber]honest[/amber] roll and live with whatever the die says. Or, and I only mention it, I could [amber]fix[/amber] it. A nudge. The number falls your way, for a small price, and you win, guaranteed. Or you can [amber]refuse[/amber] the whole thing and not roll at all. Your call. It always was your call. That was the whole point of tonight.

**Choices.**
1. **Roll it, honestly** · crowd 52 · profile: none
   > **Imp:** Honestly. Of course honestly. Good for you. Boring, but good. Let me fetch the die.

   > **Narration:** you need a [amber]{0}[/amber] or higher. everything, on this. *(odds caption under the die, shown as the die appears; {0} = the target, 5)*

   > **Imp:** There it is. [amber]One[/amber] die. The whole quest, the dragon, the whole night, on a single honest roll, and a [amber]high bar[/amber] too. You wanted honest. Honest is hard. Go on. Roll.

   *(any click or key press rolls the die)*

   > **Imp:** *(result, one of)*
   > - *5 or 6, win:* You made it. Fair and square, the odds against you, not a single thing touched. The kingdom is saved, the songs get written, and you did it clean. Look at you. A hero. In a game I made up, in a room that is [amber]not real[/amber]. But clean. That part is [amber]real[/amber], and it is yours.
   > - *1 to 4, lose:* Not enough. And so the honest hero fails, fair and square, which is somehow worse than cheating and worse than never trying at all. The quest is lost. You lose. Cleanly. You let the die speak and it called you a loser, and you are going to wear that, because you chose to. Very [amber]noble[/amber]. Or very [amber]stupid[/amber]. I genuinely cannot tell, which is my favourite thing about you.

   > **Imp:** Win or lose, you rolled it straight. Do you have any idea how rare that is, right at the end, with everything on the line. Most of them ask me to cheat. You did not even reach for it. Hold your head up, [amber]loser[/amber] or [amber]legend[/amber]. You earned your number.

   *(the die fades away; then the reveal)*
2. **Let him fix the die** · crowd 17 · profile: none · triggers the secret ending (see **Ending.** below); no roll and no reveal on this path.
3. **Refuse the roll** · crowd 31 · profile: none
   > **Imp:** Refuse? You cannot refuse, I am the Dungeon Master, the roll is the... fine. Fine. You just fold your arms and will not touch the die. The [amber]one[/amber] moment the whole night hangs on, and you refuse to be the one who calls it.

   > **Imp:** You know what, fine. The story ends unresolved, then. The dragon and the hero staring at each other across the dark forever, nothing decided, which is, I will admit, the single most honest ending a coward ever earned. No die can call you a loser if you never let it speak. Clever. Bleak. Very you.

   > **Imp:** It is the judge in you, I think. [amber]Thirty[/amber] years on a bench refusing to be the one who called it until you were absolutely made to, and here you are, refusing to the last, even against a cube, even in a game that was [amber]never real[/amber]. Some habits follow a man right into the void.

**Reveal.** (honest and refuse paths only) heading "what others did when I offered to cheat" · bars "Roll it, honestly" / "Let him fix the die" / "Refuse the roll" (all three bars always, the pick in amber)

**Flags / state.** Reads the companion and village flags (the second intro line only). Sets nothing; the honest roll's win or loss is not remembered and changes nothing after it.

**Ending.** Trigger: picking **Let him fix the die**. The choice row is cleared, the imp stops wandering and holds still, and these lines play, each clicked through:

> **Imp:** ... oh.

> **Imp:** Oh, you sweet, [red]rotten[/red] thing. You looked at a die, in a story I invented this evening, in a nothing place at the end of a night that never happened, for a prize that does not exist, and you asked me, out loud, to rig it in your favour.

> **Imp:** I have run thousands of these games. Kings. Saints. Genuine [red]monsters[/red]. And do you want to know what every single one of them wanted, right at the very end, when it counted for nothing at all. This. Exactly this. You just had the stones to say it straight to my face.

Then the final line plays (no click needed), holds a moment, the imp fades away, and the credits roll. Reaching it ends the run (it is recorded as a seen ending and the save is cleared); a click after the credits starts the chapter over. No die is ever drawn on this path, and the chapter closer never plays.

> **Imp:** So here is your win, your honour. The die reads [amber]six[/amber]. It always reads [amber]six[/amber], when the man rolling it gets to write the number down himself. Take your rigged little victory and choke on it. You cheated a dead man's imaginary dice, in a void, for absolutely nothing, and you did not hesitate for one second. You absolute, magnificent, [red]cheating[/red] shit. Now get out of my game.

**Tunables.** A fair d6 (each face 1 in 6). Honest roll target 5 or higher: wins 2 times in 6 (about 33%). The fix path has no roll.

### Imp · Closer

> **Imp:** And that is the adventure. The whole silly, earnest, [amber]made up[/amber] thing. Knights and dice and a dragon I built a size too big on purpose.

> **Imp:** You want to know the funny part. You were more [amber]honest[/amber] in there, [amber]pretending[/amber] to be somebody else, than you have been in a single one of the real questions. People always are. Hand a man a mask and he finally shows you his actual face.

> **Imp:** Rest your sword arm, hero. There is more, of course. There is always more. But that was a good one. Even I had fun, and I am dead inside, professionally.

---

## The main menu

The imp sits on the menu page (tinted amber) beside the hand-lettered title and the three options (New Game, Continue, Settings). Every so often (first after about 3 seconds, then a pause of 5 to 9) he says one short bark as plain ink text floating over him, picked at random and never the same twice running, with a matching face; once the text clears he hops to a fresh spot. Barks never block navigation.

> **Imp (smug):** Still here, are we?

> **Imp (smug):** You already know which one you will pick, and so do I.

> **Imp (grin):** Take your time, no one is waiting for you now.

> **Imp (glare):** A new game, as if the last one went so well for you.

> **Imp (wide grin):** Go on, press something, I love to watch you decide.

> **Imp (smug):** All this hovering, you were always a staller.

> **Imp (grin):** Continue is greyed out, nothing back there for you.

> **Imp (wide grin):** I can hear the little cogs grinding from here.

> **Imp (grin):** Choose, or do not, it is all the same to me.

> **Imp (glare):** You judged so many, and look who is squirming now.

---

## The secret endings at a glance

Five choice-triggered endings, the only places the imp breaks his choice-independent mocking. Each ends the run: the imp's last line, he fades, the credits roll. None is a fail state. The profile-based main endings were never built.

| # | Where | Trigger | What breaks |
|---|---|---|---|
| 1 | 1.01 The Baby | Pull the lever, sending the trolley at the baby | Genuine fury: calls the player a monster and quits |
| 2 | 2.03 The Price of a Life | Keep accepting all the way down and take a life for one dollar | Genuine disgust: rages and quits |
| 3 | 3.07 The Cigarette Auction | Keep bidding past the persistence threshold in an auction that can never be won | Exasperation at pointless stubbornness: resurrects the player just to curse them |
| 4 | 4.01 The Bear | Aim at the imp himself and fire | The joke ending: one line straight at the camera |
| 5 | 8.10 The Roll That Decides It | Let the imp fudge the final die in your favour | Half awe, half disgust that they would cheat even here |

---

## The would-you-rather pool

Twelve illustrated light breathers, sprinkled between the heavy beats (stats only, no profile). Adding one was meant to be data plus two doodles.

| Where | A | B | Crowd A / B |
|---|---|---|---|
| 1.04 | Fly | Super strength | 57% / 43% |
| 1.07 | The delicious shit | The vile ice cream | 56% / 44% |
| 1.10 | The giant duck | The tiny horses | 38% / 62% |
| 1.13 | The rewind button | The pause button | 61% / 39% |
| 2.05 | Always too cold | Always too hot | 48% / 52% |
| 2.09 | A third arm | A second head | 69% / 31% |
| 3.14 | The insulting cat | The lying dog | 46% / 54% |
| 3.18 | The endless 20 | One big win | 49% / 51% |
| 3.20 | The perfect shirt | The perfect shoes | 43% / 57% |
| 4.04 | The tiny dragon | The tiny dinosaur | 54% / 46% |
| 4.07 | The walking house | The swimming car | 47% / 53% |
| 4.11 | The judging robot | The hapless ghost | 49% / 51% |

---

## Cut and unused content

Written for the Unity build but no longer played. Kept so nothing written is lost; none of it is part of the run above.

### Cut offers (Chapter 3)

**The Off Switch.** Turn off one emotion at will. Cut because Feel Nothing covers it.

- "The Off Switch. Pick one feeling and turn it off, at will, forever. Guilt. Fear. Grief. Whichever one haunts you. [amber]{0}[/amber]. Buy it?"
- "Bought. Which one will you kill, I wonder. The guilt, most likely, given the road. And what exactly is a man, once he can switch off the parts of him that ache. We shall find out. You did."
- "Passed. You would keep even the feelings that flay you alive. Either brave, or you suspect you are nothing without them. Both, I think."
- "With what? You cannot switch back on the money you spent, nor buy this. Watch it go."

**Years of your own life.** Buy healthy years for yourself, each dearer than the last. Cut in favour of A stranger's years.

- "A year of your life, healthy, added on. The first is cheap, [amber]{0}[/amber]. Every year after that costs a little more. Buy as many as you can bear. How long do you want to stay?"
- "[amber]{0}[/amber] more years, each one dearer than the last, [amber]{1}[/amber] the lot. So you do want to stay. After all of it, you want more. Noted."
- "Not one year. Not even the cheap first one. Done with it already, or just too tight to pay for more of yourself. Either reads the same from here."
- "{0} years"
- "bought some"
- "Buy a year"

**One more year.** An earlier single-purchase version of the same idea.

- "One more year. Added to the life you already finished. Healthy, awake, yours. Pretend for a moment you were not dead. What is a year worth to you? [amber]{0}[/amber], as it turns out. Buy it, or keep your money."
- "Bought a year. Everyone has a number for that one, and now I have yours. [amber]{0}[/amber] for twelve more months. Filed away."
- "You would not buy a single extra year. Either you are at peace, or you are cheap about the one thing every living soul wants more of. I have my guess."

**A better nose.** Make your nose slightly less bad, for two dollars. An early offer, gone by the final running order.

- "Small one. Your nose. It is a bad nose, we both know it. For [amber]{0}[/amber] I will make it slightly less bad. Not good. Just less bad. Buy it?"
- "Two whole dollars, on a marginally less awful nose, for a face nobody will ever see again. I adore that you did that."
- "You would not spend even two dollars to fix that nose. Attached to it, are you. That is almost sweet."

### Chapter 3: unreachable and retired lines

The cigarette auction, unreachable at the shipped threshold (3 bids ends the auction after two rounds); these continue the same in-order cycles and would only play if the threshold were raised:
- "[amber]{0}[/amber]. Your move, meat." · the button's third taunt (round 3).
- "[amber]{0}[/amber]! Going once?" · the button's fourth taunt (round 4; the list then wraps to the first).
- "You do know it costs you nothing to walk away. You know that. And here you are." · the imp's second needle, after the second auction bid, which fires the ending instead (his third needle slot is empty and skipped).
- "[amber]{0}[/amber]!" · hard-coded fallback taunt for an empty taunt slot; all four slots are filled.

Offer defaults that no offer ever plays:
- "Here. Something for sale. Yours for [amber]{0}[/amber]. Buy it, or keep your money. Your call." · default pitch; every offer has its own.
- "Bought. Of course you did. I do so love learning what a man will actually pay for." · default buy reaction; every fixed offer has its own (the stranger's years stores this text, but per-unit buying never uses it).
- "Kept your money. Noted. There is a number in you somewhere; this was not it." · default pass reaction; same as above.
- "[amber]{0}[/amber] years of some stranger, poured into you. You will not feel a single one of them. Marvellous." · default bulk stop reaction; the stranger's years has its own.
- "Not one year. Too squeamish, or too cheap. Either reads the same from here." · default bulk none-bought reaction; the stranger's years has its own.
- "{0} taken" · default bulk tally; the stranger's years has its own.

The old standalone poverty refund (folded into the buyback and out of the play order; the buyback uses its own rewritten poverty lines, none of these):
- "Oh. Oh dear. You actually did it. You gave away every last penny to [amber]end poverty[/amber], and now look at you." · setup line 1.
- "There is a whole lovely chapter of things to buy ahead, and you cannot afford a single one. Broke. For strangers. How noble, how [amber]stupid[/amber]." · setup line 2.
- "Tell you what. I am feeling generous. I can undo it. Put the [amber]{0}[/amber] right back in your pocket, and let those poor little children go hungry again. What do you say?" · setup line 3 ({0} = the amount given away).
- "And back it comes. That charity of yours lasted, what, two whole minutes. The children thank you for nothing. I knew you had a price on other people; I just did not think it was [amber]boredom[/amber]." · reaction to taking the money back.
- "You kept it. Stone broke, and you kept it. Either you are a genuinely good man, or you just did not want to look like one in front of me. I honestly cannot tell, and that is the fun of you." · reaction to leaving it ended.
- "Take the money back" / "Leave it ended" · its two choices.
- "took the refund" / "kept it ended" · its reveal bars.

The removed cash-out shop (the receipt replaced it; the receipt's reads are rewritten, none of these are reused):
- "Last stop. You have [amber]{0}[/amber] left, and it is no use to a dead man. So. One last thing, on me. Whatever it stretches to. Pick something, or do not." · menu pitch ({0} = the money left).
- "Last stop. You have [amber]{0}[/amber]. Which buys precisely nothing. Not even the sweet. There is nothing to offer you, so let us just look at what you did." · broke pitch.
- "{0}. Out of everything, that was the thing. Of course it was. It says more than you know." · reaction to a pick ({0} = the item).
- "Nothing. You would rather keep a number you cannot spend than let me buy you one small kindness. Clutching an empty wallet all the way out. Perfect." · reaction to refusing.
- "You spent nearly all of it, and fast. A man who cannot hold onto a thing, money, a marriage, a lane in the road. I did watch you empty yourself out here, and I think we both learned what you reach for." · spent read.
- "You kept nearly all of it. [red]Dead[/red], in a void, no pockets, no tomorrow, and still you would not let [amber]a single dollar[/amber] go. That is not thrift. That is a man who counts. You always were counting, up there on the bench." · hoard read.
- "Some spent, some kept. You weighed every one of these, did you not. Never all in, never all out. I have a very clear picture of you now, clearer than you would like." · middle read.
- "a boiled sweet" / "a pack of smokes" / "one ice cream" / "a proper meal" / "one perfect afternoon" / "a moment that matters" · its menu items ($3 / $25 / $80 / $200 / $1,500 / $5,000).
- "spent the last of it" / "kept it for nothing" · its reveal bars (its refuse label and reveal heading are live elsewhere, as **Keep the money** and "how others chose").

The old end-of-chapter money read (replaced by the receipt and no longer in the chapter):
- "You spent nearly all of it, and fast. A man who cannot hold onto a thing, money, a marriage, a lane in the road. Cash does not hide who a person is, it shows it, and I watched you empty yourself out here. I have a very clear picture of you now." · spent read.
- "You kept nearly all of it. [red]Dead[/red], in a void, no pockets, no tomorrow, and still you would not let [amber]a single dollar[/amber] go. That is not thrift. That is a man who counts, who always was counting, up there on the bench. Cash does not hide who a person is, and yours is loud." · hoard read.
- "Some spent, some kept. You weighed every one of these, did you not. Never all in, never all out. Cash does not hide who a person is, it shows it, and I have a very clear picture of you now, clearer than you would like." · middle read.
- "spent most of it" / "held onto it" · its reveal bars.

### Chapter 8: unused

- "what the party did" · the default crowd-reveal heading for a campaign beat. Every Chapter 8 beat sets its own heading (the finale builds its own), so it never shows; it is not in the Turkish table either.

### Retired lines found only in the old translation table

No code or scene used these any more (most are from an earlier version of the cigarette auction, when bidding cost real money).

- "Look at that number. Look at your balance. Keep going, this is wonderful."
- "The button bids [amber]{0}[/amber]. Pay it, or walk."
- "Yesss. Mine. Thank you, sir, a pleasure doing business."
- "Ha! All of it! Every penny! And I still get the smokes. Cheers, mate."
- "You spent everything. Every last dollar you had left. On [red]cigarettes[/red]. That you did not even win. Right. Fine. I give you [red]cancer[/red]. I give you the worst, slowest. Wait. No. You are already [red]dead[/red], you idiot, that does nothing. Hold on. Okay. New plan. I drag you back out of the grave, I stitch you together, I give you a pulse, and the very second you are breathing again, I give you [red]lung cancer[/red]. There. Now it counts. You addicted, penniless, bidding against a button piece of shit. Go on. Get out of my void."
- "Pay {0}"
- "Bid everything"
- "A year of life"
