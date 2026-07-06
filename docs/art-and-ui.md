# Art, UI & Audio

## Visual style
Black-and-white, hand-drawn **stick figures** — a doodle aesthetic. Characters are built on **reposable 2D skeletal rigs** (Unity's 2D Animation, bones and sprite skinning): one rig reposed into hundreds of scenarios rather than bespoke art per scene. This is the core reason the game's scope is achievable, so treat "repose the rig" as the default and "draw new art" as the exception.

The setting is a cosmic void — mostly empty space — so backgrounds are minimal and the figures carry every scene.

## Minimal, not sterile (stylisation)
Minimal governs how many elements are on screen (few, uncluttered). Stylisation governs the character of the elements you keep. The hand-drawn ink aesthetic is the style, so the game should read as spare but never plain or sterile. Character comes from four levers, none of which add clutter:
- A living ink line. Variable-weight, slightly rough, hand-drawn strokes, not clean geometric vector. A subtle boil (cycling two or three near-identical line frames) makes everything feel drawn and alive for almost no cost.
- Paper, not blank white. A faint paper or newsprint texture on the white ground so it reads as a sketchbook page rather than an empty screen. Still monochrome, still minimal.
- Characterful type. The narrator's text uses a distinctive hand-lettered or characterful typeface and inks in rather than hard-cutting, so the words carry voice. Not a plain system font.
- Expressive, ink-like motion. Elements draw themselves on and wipe or dissolve like ink; transitions have easing personality; the amber reads like a marker stroke rather than a flat fill; figures keep a tiny idle life (a breath, or the boil).

What this does not mean: added UI chrome, decorative flourishes that compete for attention, extra colours, or busier screens. The minimal-UI rules below still hold. Stylisation lives in the line, the texture, the type, and the motion, never in more stuff on screen.

## Colour
- Strictly black-and-white, plus **one meaningful accent colour**.
- The accent is used **only for attention and consequence** — the doomed figure, the lever, the player's avatar — **never decoration.** The moment it's decorative, it stops meaning anything.
- **Accent chosen: amber.** The old worry that a red accent would collide with the blue/red gamble is moot: the accent is amber, and blue and red appear only as the documented exception below.
- **Documented exception (blue/red button dilemma only).** The one reframed viral dilemma uses actual hand-drawn blue and red, on its two buttons and its "how the room voted" stats bars, and nowhere else in the game. Rendered as a muted, inky crayon wash inside the black ink linework, never flat digital UI colour; hover and selection deepen the button's own colour rather than borrowing the amber. The colours live as `Palette.InkBlue` and `Palette.InkRed`. This is the single deliberate break from the one-accent rule. See `decisions.md` (2026-07-06).

## UI / HUD philosophy — clear and simple
The interface recedes so the void and the figures dominate. Concretely:
- **No large HUD.** No persistent on-screen meters, bars, or status clusters. In particular, the moral profile is **not** shown as a running gauge during play.
- **No big menus.** Menus are minimal and sparse — only what's essential.
- **No pop-ups / dialog boxes.** Prefer in-world, diegetic presentation over modal windows.
- **Minimal on-screen detail.** Every UI element must justify its presence; when in doubt, remove it.
- The choice presentation itself should feel like part of the scene, not a UI overlay stapled on top.

## Audio
- **Text-first.** Ship with text; full voice acting for the narrator is a later, high-impact upgrade (VO freezes the script, so keep writing fluid by staying text-only for now).
- Music and SFX carry mood in the meantime; keep them spare to match the visual minimalism.
