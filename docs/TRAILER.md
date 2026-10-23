# The first trailer

The treatment of the game's first trailer as it is cut now: about a minute, 16:9 at 1920x1080, for the game's itch.io page, through a video site the page embeds. It is made from the game itself and can be made again after every note (`docs/ARCHITECTURE.md`, "The trailer"; the command is in `CLAUDE.md`). The cut lives in `trailer/trailer_cut.json` and the imp's lines in `trailer/trailer_lines.json`; this page describes them and changes with them.

Every creative call here was made without the user, who asked for the trailer to be made with no questions. Each one is provisional and listed under "To review: the first trailer" in `OPEN_QUESTIONS.md`.

## The idea

Sell the imp first and the premise through him. A cold open puts his face, his voice and his timing on screen in the first seconds, lands the death as a gag (the crash, then "Mostly the wine."), and the game's own beats follow in a quick montage, each with one new line from him over the real stage: the lever and its crowd reveal, a button, the shop, the gun, who would win. He says the portrait without showing it ("I am reading you"), the music stops for "Your call.", and the title inks on with his last jab.

It works with the sound off, as people often watch a trailer on a game's page: every line is in the dialogue box, inking on in time with his voice.

## The minute

| At | Piece | What is seen | What is heard |
|---|---|---|---|
| 0:00.0 | wake | Black, then the eyes open in blotches on the imp, close up. | "You probably wonder why you ended up here." |
| 0:04.2 | crash | The game's opening crash: pale ink headlights bearing down a night road, then the white flash of the hit. | Silence, then the crash on the flash. |
| 0:05.6 | wine | The imp, closer, smug. | "Mostly the wine." |
| 0:07.7 | questions | The imp hops across the empty page to the middle as the camera eases in. | "You are dead, Your Honour. And I have questions." |
| 0:11.8 | lever | 1.02 The Lever: five strangers on the straight track, one on the branch. The choice row, the lever lit amber, pulled. | "Pull it, and you are a killer with a calculator. Leave it, and you are a killer with an alibi." The waltz begins. |
| 0:20.4 | lever | The trolley takes the branch and the one folds. | |
| 0:22.2 | crowd | How others chose: 87 pulled, 13 did nothing, brought in close. | "Then I show you how everyone else chose." |
| 0:25.5 | nuke | 2.10: the red button, and "Press it" chosen. | "Cure cancer, lose one country. Chosen at random." |
| 0:30.1 | nuke | The world map inks in, the pin goes round and drops on Monaco, the mushroom cloud. | |
| 0:33.2 | burritos | 3.02 in the money chapter: the balance at the top, the burrito and its price tag. Bought: circled, and the balance counts down. | "Eternal burritos. You do not even have a stomach." |
| 0:39.0 | gun | 4.06 The Last Bullet: the sight sweeps the five colours, the brackets lock on green, the shot, and green folds. | "Eventually, I give you a gun." The gunshot. |
| 0:44.9 | gorilla | 5.01: a hundred men or one gorilla. The pointer weighs them; the gorilla is circled. | "And the questions that really matter." |
| 0:49.9 | reading | The imp close up, the camera easing in. | "I am not judging you, Your Honour. I am reading you." The waltz swells and stops. |
| 0:54.0 | call | The imp closest of all, smug. | Silence, then "Your call." |
| 0:56.0 | title | "Your Call" inks on, an amber stroke under it, then "Coming to itch.io". The imp stands beside it. | A pen scratching the title on. "Play it, or do not. It all goes in the book." The sting's last note. |

It runs 63 seconds and fades out over its last half second.

## The imp's lines

Twelve lines, written for the trailer in his register and voiced in his voice with `eleven_v3` (513 characters). "You probably wonder why you ended up here." is the user's. "Mostly the wine." carries the direction `[dryly]` and "Your call." `[smugly]`.

1. You probably wonder why you ended up here.
2. Mostly the wine.
3. You are [red]dead[/red], Your Honour. And I have questions.
4. Pull it, and you are a [red]killer[/red] with a calculator. Leave it, and you are a [red]killer[/red] with an alibi.
5. Then I show you how everyone else chose.
6. Cure [red]cancer[/red], lose [amber]one country[/amber]. Chosen at random.
7. Eternal [amber]burritos[/amber]. You do not even have a stomach.
8. Eventually, I give you a gun.
9. And the questions that really matter.
10. I am not judging you, Your Honour. I am [amber]reading[/amber] you.
11. Your call.
12. Play it, or do not. It all goes in the book.

They follow the writing rules: no dashes, colour tags from the vocabulary only, and the imp mocks both ways (line 4 mocks pulling and leaving alike; line 12 playing it and not). No swearing, so the trailer can play anywhere the game's page does.

## What it shows

The ink look and its boil, the paper, the imp on the page and close up (his faces, his mouth moving with his voice, a hop across the page), the dialogue box inking on in time with his voice, the choice row lit and picked, the crowd reveal, the crash, and a taste of five stages: the lever and the tracks, a button (the nuke, with the world map and the pin), the shop and its balance, the gun's sight locking on, and who would win.

## What it holds back

- The five secret endings and the ways to them. None of their questions appear: 1.01 the baby, 2.03 the price of a life, 3.07 the cigarette auction and its curse, and 4.01 the bear, where the imp can be shot. The fifth is in a chapter not built yet.
- The walking button: it never appears, so 2.11, 3.07, 4.05 and 5.06 are out.
- The portrait the game builds: no receipt, no profile, no ending. The imp only says he is reading you.
- The cucumber, kept for the money chapter's finale.

## Sound

- **Voice:** the imp's lines as the game plays them, from the recordings.
- **Music:** made with Eleven Music on the Creator plan: a sly dark carnival waltz (oom pah tuba, pizzicato strings, accordion, celesta) under the montage from the lever to "I am reading you", cut dead for "Your call.", and a short sting whose last note lands after the imp's last line. The placeholder track is never used: the trailer mutes the game's music bus.
- **Sound effects:** the game's gunshot, a crash on the flash of the crash, and a pen scratching the title on.
- **Mix:** the music ducks under the voice; the whole is brought to -16 LUFS.

## The title card

"Your Call", the working title, in the game's hand-lettered face, with "Coming to itch.io" under it in amber and no date. Both are one line each in the cut (the `title` shot), so a final title or a date is a one line change and a re-render.

## The files

`python tools/trailer/render_trailer.py` writes to `trailer_renders/` in the project: `your_call_trailer_upload.mp4` to upload to a video site for the itch.io page (1920x1080, 30 fps, H.264 High, about 7 Mbit/s, AAC 192 kbit/s at 48 kHz), `your_call_trailer.mp4` to share (about 18 MB), `your_call_trailer_draft.mp4` (960x540) and a contact sheet of it.
