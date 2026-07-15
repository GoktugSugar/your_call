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

### ◻️ To capture (the PDF shows a labelled placeholder until these exist)

| File | Shows | How to reach it (F1 dev picker) |
|---|---|---|
| `nuke-map.png` | The hand-drawn ink **world map** with the small red **map pin** on a country, population in amber | **Chapter 2 → `C2_Nuke`**. Advance the imp's setup, then **press the red button**; capture once the pin has dropped and the name/population read out. |
| `gun-bear.png` | The **bear** (brown fill) framed by the first-person **ink crosshair** with its single **amber** corner-bracket lock | **Chapter 4 → the Bear opener** (beat `01`). Move the mouse so the amber lock sits on the bear, then capture (before firing). |
| `matchup.png` | The **two-doodle matchup** format: two coloured fighters side by side with counts and a muted "vs" (e.g. **100 men vs 1 gorilla**) | **Chapter 5 → the first matchup**. Capture once both fighters + labels are inked in. |
| `booth.png` | The fixed **confession booth**, a confessor in the doorway, and the **three verdict** labels in a row above the box | **Chapter 7 → any case** (e.g. `The Recliner`). Advance to where the three verdicts are presented. |
| `campaign-class.png` *(optional)* | The five **class doodles** (sword+shield, dagger, wizard hat, lute, chalice), each a coloured outline | **Chapter 8 → `Your Class`** (beat `01`). Capture the class-pick menu. |
| `dice.png` | The **DiceRoll** set piece: the hand-drawn ink **d6**, the odds caption, an **amber** flash on the landed value | **Chapter 8 → The First Roll** (or the finale roll). Capture during/just after the tumble lands. |
| `money-priceable.png` | A money-chapter **offer**: a coloured-outline item **doodle**, the amber **price tag**, the amber **balance** up top, plain buy/pass text | **Chapter 3 → any priceable beat** (e.g. `End Poverty`, or `Rewind` for the blue back-arrow). |
| `stats-reveal.png` | The **"how others chose"** crowd reveal: the reflective **bars**, the player's own pick picked out in amber | **Any dilemma** (e.g. Chapter 1 `07_Lever`): play it, **make a choice**, click through the consequence, and capture when the stat bars present on their own. |
| `imp-closeup.png` *(optional)* | A clean close-up of the **imp** — horns, tail, grin, the amber tint, an expression | Grab from the **Main Menu** or any dialogue beat and crop tight to the imp. |

If a live moment refuses to sit still for a clean grab, capture the nearest clean frame and note it;
the placeholder caption in the PDF already describes exactly what the shot should contain.

> **Note on this pass:** the seven captured shots were grabbed via the Unity screenshot tool while
> driving the beats from script. Live-timed moments (the pressed nuke button, the stat-bar reveal, an
> aimed crosshair, a landed die) are the ones left for a focused-editor pass, since they depend on
> playing the beat to an exact instant. Everything else is in.

---

## Adding a brand-new shot to the guide

1. Capture the PNG into `screenshots/`.
2. In `build-style-guide.py`, add a `shot("your-file-name", "caption text")` call inside the relevant
   section of `build_body()`.
3. Re-run `python build-style-guide.py`.
