# The trailers

Two trailers cut from the same shots, both about a minute and thirteen seconds: **wide** (16:9, 1920x1080) for the itch.io page, through a video site the page embeds, and **tall** (9:16, 1080x1920) for TikTok, Reels and Shorts. Both are made from the game itself and can be made again after every note (`docs/ARCHITECTURE.md`, "The trailers"; the command is in `CLAUDE.md`). The cut lives in `dev/trailer/trailer_cut.json` and the imp's lines in `dev/trailer/trailer_lines.json`; this page describes them and changes with them.

They were made from scratch, on 2026-10-23, without the first trailer (PR #9) as a reference, at the user's request. The calls the user made are logged in `DECISIONS.md`; the ones the developer made are listed under "To review: the new trailers" in `OPEN_QUESTIONS.md`.

## The idea

The imp hosts it like a game show, to the Show's own music, and you are the contestant. It opens tight on his face as your eyes open, with the user's line, "You are probably wondering how you ended up here." Then the camera pulls out of the close up onto The Show's studio as he introduces tonight's contestant: a judge, recently deceased, slightly over the limit.

Then the hook of the game, shown rather than explained: the lever, pulled ("Murderer."), the picture rewinding like a tape, the lever left alone ("Also murderer."), and how others chose ("Murderers, the lot of them."). He mocks both picks the same way, so it says no right answer without saying it twice. A fast list follows, one cut on every word (trolleys, buttons, money, guns, gorillas), then gorillas with knives, the studio audience, the confession booth (his old job back), and the campaign's dragon. He closes tight on his face again with the game's own refrain, "Your call.", and the title inks on.

The questions are on screen in the game's own words (the stage, its labels, the choice row), and he only comments on them. Every word he says inks on in the dialogue box as he says it, so both trailers work with the sound off.

## The minute

The wide trailer, as it is cut now; the tall one is the same cut, framed for a phone.

| At | Shot | What is seen | What is heard |
|---|---|---|---|
| 0:00 | open | Black, then the eyes open in blotches on the imp, so close his grin fills the frame. | "You are probably wondering how you ended up here." "You died. Anyway!" |
| 0:07 | welcome | The camera pulls out of the close up as the Show's studio draws itself on round him (the valance, the floor and its lights, the audience), the imp host sized in the middle. | The Show's music starts. "Welcome to Your Call! Tonight's contestant: a judge. Recently deceased. Slightly over the limit." |
| 0:16 | lever | 1.02 The Lever: five strangers on the straight track, one on the branch. The choice row, "Pull the lever" lit and picked; the trolley takes the branch and the one folds. | "I ask the questions. None of them has a right answer." "Murderer." |
| 0:26 | rewind | The same moments backwards, four times as fast. | The same sound backwards, wound on like a tape. |
| 0:28 | nothing | The lever again, "Do nothing" picked; the trolley runs straight on and the five fold. Then how others chose, 87 to 13. | "Also murderer." "Then you see what everyone else did. Murderers, the lot of them." |
| 0:39 | the list | A cut on every word: the three tracks (1.15) with the trolley on its way down the third, red and blue (2.01), buying Ten More IQ in the money chapter (3.05), the duel (4.10) and its shot, and 100 men against 1 gorilla (5.01), the gorilla circled. | "We have trolleys! Buttons! Money! Guns! Gorillas!" |
| 0:44 | knives | 5.08: 1 gorilla against 1 gorilla with a knife, the knife picked. | "Gorillas with fucking knives!" |
| 0:48 | audience | 6.01 Applause: a contestant walks on and goes flat on their face, the APPLAUSE sign lights, the audience claps. | Applause. "A live studio audience!" |
| 0:53 | booth | 7.01 The Recliner: the booth, the confessor filing in under his headline, then the verdict, "Everyone on that flight sucks", the gavel and his shrug. | The recliner in his own voice: "I paid for the whole seat." The gavel. "Your old job back!" |
| 0:59 | dragon | 8.09: the campaign's dragon inks itself on, too big. | "And a dragon, for some reason!" |
| 1:02 | call | The imp close up again. | The music stops dead. "Your call." |
| 1:04 | title | "Your Call" inks on with its stroke, then "Coming soon to itch.io" in amber, the imp beside it. | The scribble of the imp's pen. "Coming soon. Try not to die waiting." "Oh. Right." |

It runs 73.2 seconds and fades out over its last half second.

## The tall one

The same pieces, framed for a phone. The words are brought in by a third and kept above the bottom fifth of the screen, where a phone app puts its own captions and buttons, and the money chapter's balance is kept below its tabs. The close ups fill the frame. Each stage is framed by the camera for the narrower picture, and the imp floats above it as the host rather than in his wing, which a phone frame leaves out. Two choice rows too long for a phone frame show only the options that fit: the booth's shows the pick alone, and the dragon's leaves out its longest option. The Show's audience is seated across the bottom of the frame, where a wide studio has it either side.

## The imp's lines

Fifteen lines, new for the trailers, in his voice with `eleven_v3` (507 characters, voiced 2026-10-23). The first is the user's; the user approved them all, and chose the one swear uncensored.

1. You are probably wondering how you ended up here. *(slyly)*
2. You died. Anyway! *(cheerfully)*
3. Welcome to Your Call! Tonight's contestant: a judge. Recently deceased. Slightly over the limit. *(excited)*
4. I ask the questions. None of them has a right answer. *(smugly)*
5. [red]Murderer[/red]. *(deadpan)*
6. Also [red]murderer[/red]. *(deadpan)*
7. Then you see what everyone else did. [red]Murderers[/red], the lot of them. *(dryly)*
8. We have trolleys! Buttons! Money! Guns! Gorillas! *(excited)*
9. Gorillas with fucking knives! *(excited)*
10. A live studio audience! *(excited)*
11. Your old job back! *(cheerfully)*
12. And a dragon, for some reason! *(excited)*
13. Your call. *(smugly)*
14. Coming soon. Try not to die waiting. *(smugly)*
15. Oh. Right. *(dryly)*

They follow the writing rules: no dashes, colour tags from the vocabulary only (red on the guilty words), and the imp mocks both ways (5 and 6 mock pulling and leaving alike, 7 the crowd). The deliveries in brackets are the v3 directions sent with each line, never shown. Each line has its own clip, so any one can be voiced again on its own.

## What they hold back

- The five secret endings and every question that leads to one: 1.01 the baby, 2.03 the price of a life, 3.07 the cigarette auction, 4.01 the bear, where the imp can be shot, and 8.10 the last roll.
- The walking button, everywhere it comes back: 2.11, the auction, 4.05, 5.06, The Show's champion and the booth's confession.
- The cucumber, in the money chapter's finale and The Show's mystery box.
- The money chapter's receipt, and every closer that reads the player.
- All of Chapters 9 and 10: the guessing, the notebook, the portrait and the postings.

## Sound

- **Voice:** the imp's lines as the game plays them, from the recordings, and the recliner's own line in his own voice.
- **Music:** The Show's track (`assets/audio/music/show.ogg`, the Eleven Music take standing in for it), at the user's word, from its first bar at the pull out to "Your call.", where it stops dead. It dips under the voice.
- **Sound effects:** the game's own, as each shot plays them, the breath as the eyes open, the room's applause in 6.01, the gunshot and the gavel among them. The welcome's audience sits quiet, at the user's word. The rewind is its piece's own sound backwards. The title inks on to the imp's pen scribble, laid over the cut.
- **Mix:** the whole is brought to -14 LUFS, as YouTube and TikTok play things, with true peaks under -1.5 dB.

## The title card

"Your Call", the working title, in the game's hand-lettered face as the main menu inks it on, with its stroke drawn under it, then "Coming soon to itch.io" in amber and no date. The title comes from the menu's own words (`content/menu.json`), and the release line is one line in the cut (the `title` shot), so a final title or a date is a change of data and a render.

## The files

`python tools/trailer/render_trailer.py` writes to `trailer_renders/` (which git and Godot ignore): `your_call_trailer_wide.mp4` and `your_call_trailer_tall.mp4` to upload (H.264 High at 30 fps, AAC 192 kbit/s at 48 kHz, about 40 MB each), a half size draft of each for a quick look, and a contact sheet of each draft.
