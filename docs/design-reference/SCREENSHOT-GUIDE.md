# Screenshot Guide — Your Call visual style reference

This folder is a **reference pack for Claude Design**: a polished style-guide PDF plus the
screenshots that illustrate it. This file is the **shot list** and the how-to for capturing the
remaining images.

- **PDF:** `your-call-style-guide.pdf` (generated from `build-style-guide.py`)
- **Screenshots live in:** `screenshots/` (one PNG per slot, exact file names below)
- **Regenerate the PDF:** from this folder, run

  ```
  python build-style-guide.py
  ```

  It embeds every PNG that is present in `screenshots/` and draws a clearly labelled
  **placeholder** for any that are missing, so the PDF is always complete and readable. Drop the
  missing PNGs in (using the exact names below) and re-run to get the finished PDF.

> The build needs Python 3 and Microsoft Edge or Chrome (for the HTML → PDF step). No pip packages.

---

## How to capture a shot

1. Open the project in Unity and press **Play** (the game boots into the Main Menu).
2. Make sure the language is **English** for a clean reference (Settings → Language, or it is already
   English). English reads best for Claude Design.
3. Use the **dev chapter/beat picker**: press **F1** to open it, click a chapter to load it, then
   click a **beat** in the list to jump straight to it (it reads the live beat list, names like
   `07_Lever`, `C2_BlueRed`). The magenta `DEV TOOLS [F1]` hint and the picker panel are dev-only
   overlays — close the picker (Esc) **before** you grab the frame so they are not in shot.
4. For a **live moment** (a stats reveal, a pressed button, a fired shot) you have to *play the beat*:
   advance the imp's lines with a click/key, then make the choice, then capture at the right instant.
   Keep the **Game view focused** so the frame is not frozen.
5. Capture the **Game view** (Windows: the Unity screenshot tool, or any screen grab of just the Game
   view). Save as a **PNG** into `screenshots/` with the **exact file name** from the list below.
6. Re-run `python build-style-guide.py`.

Aim for a clean 16:9-ish Game view (the pack was built at 1900×922). Framing the whole Game view is
fine; the guide scales each shot to fit.

---

## Shot list

### ✅ Already captured (in `screenshots/`, embedded in the PDF)

| File | Shows | Where it came from |
|---|---|---|
| `menu.png` | Title + ink flourish, amber imp, floating no-bubble bark, ink menu options | Main Menu |
| `trolley-lever.png` | The trolley / right-angle track / amber lever / 5-vs-1 figures / dialogue box, amber counts | Chapter 1 → `07_Lever` |
| `trolley-marked.png` | Red-branded (guilty) figures + red guilt words in the narration | Chapter 1 → `09_Marked` |
| `trolley-loved.png` | The partner drawn pink with a pulsing heart; "loved most" in pink | Chapter 1 → `20_Loved` |
| `trolley-fulltrack.png` | Three-track tableau: children (scaled rig), pregnant, three adults | Chapter 1 → `21_FullTrack` |
| `buttons-bluered.png` | The blue/red crayon-wash buttons, the crowd, the coordination gamble | Chapter 2 → `C2_BlueRed` |
| `buttons-crowned.png` | Gold = the best life: the golden crowned figure | Chapter 2 → `C2_Better` |
| `money-priceable.png` | Chapter 3: coloured item doodle (blue Rewind arrow) + amber price + amber balance + buy/pass | Chapter 3 → `C3_Rewind` |
| `gun-bear.png` | Chapter 4: the brown last bear vs one man, first person, no avatar | Chapter 4 → `04_Bear` |
| `matchup.png` | Chapter 5: the two-doodle matchup (blue crowd of men vs the grey gorilla) + the imp's banter | Chapter 5 → `02_MenGorilla` |
| `booth.png` | Chapter 7: the fixed ink confessional + a confessor in the doorway with a floating headline | Chapter 7 → `C7_01_Recliner` |
| `campaign.png` | Chapter 8: the imp launching the tabletop campaign (the DM register) | Chapter 8 → `C8_03_Class` (intro) |

Together these give **1 to 2 shots per chapter** (Chapter 6 is not yet built), plus the extra Chapter 1
trolleys, embedded in the PDF's "Chapters at a glance" gallery and its convention sections.

### ◻️ To capture (the PDF shows a labelled placeholder until these exist)

These four are the **live-timed / interactive** moments that need playing a beat to an exact instant,
so they were left for a focused editor (where hover and timing behave normally):

| File | Shows | How to reach it (F1 dev picker) |
|---|---|---|
| `nuke-map.png` | The hand-drawn ink **world map** with the small red **map pin** on a country, population in amber | **Chapter 2 → `C2_Nuke`**. Advance the imp's setup, then **press the red button**; capture once the pin has dropped and the name/population read out. |
| `dice.png` | The **DiceRoll** set piece: the hand-drawn ink **d6**, the odds caption, an **amber** flash on the landed value | **Chapter 8 → The First Roll** (`C8_05_FirstRoll`). Advance to the roll and capture just as the tumble lands. |
| `stats-reveal.png` | The **"how others chose"** crowd reveal: the reflective **bars**, the player's own pick picked out in amber | **Any dilemma** (e.g. Chapter 1 `07_Lever`): play it, **make a choice**, click through the consequence, and capture when the stat bars present on their own. |
| `imp-closeup.png` *(optional)* | A clean close-up of the **imp** — horns, tail, grin, the amber tint, an expression | Grab from the **Main Menu** or any dialogue beat and crop tight to the imp. |

If a live moment refuses to sit still for a clean grab, capture the nearest clean frame and note it;
the placeholder caption in the PDF already describes exactly what the shot should contain.

> **Note on this pass:** twelve shots were grabbed via the Unity screenshot tool while driving the
> beats from script (at least one per chapter). The four remaining are the genuinely live-timed
> moments (a pressed nuke button, a landed die, the stat-bar reveal), best grabbed in a focused editor. Everything else is in.

---

## Adding a brand-new shot to the guide

1. Capture the PNG into `screenshots/`.
2. In `build-style-guide.py`, add a `shot("your-file-name", "caption text")` call inside the relevant
   section of `build_body()`.
3. Re-run `python build-style-guide.py`.
