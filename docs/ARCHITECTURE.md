# Architecture

How the remake is built. It describes what exists in the build, and grows as systems land. Design intent lives in `PREMISE.md`; the reasons behind each choice are in `DECISIONS.md`.

## Engine

Godot 4.7, Forward+ renderer, GDScript with static typing. The base canvas is 1920x1080 (`canvas_items` stretch, `keep` aspect, paper coloured clear colour), so every position and size in the project is in those units.

## Layout

| Folder | What lives there |
|---|---|
| `ink/` | The ink look: the brush that turns strokes into hand-drawn lines, the boil clock, the shared style, the paper ground. |
| `figures/` | The reusable rigs drawn in ink: the stick figure, its poses and variants, and the imp. |
| `doodles/` | Ink drawings of things (props, controls) that more than one stage uses. |
| `stages/` | Question presentations, one folder each (the trolley, two doodles, buttons and so on). A stage stages any question that uses it, from that question's data. |
| `ui/` | The dialogue box, the choice row, the crowd reveal, menus, and the theme. |
| `game/` | The run: the main scene, the beat and question flow, the content model and loader, the profile, the save. |
| `content/` | The game's content as data. |
| `assets/` | Imported files: fonts, and later audio. |
| `dev/` | Development-only helpers (autoplay, capture, overlay). They do nothing in release builds. |
| `tests/` | Automated tests. |
| `docs/` | Design docs, decision log, open questions. Hidden from Godot. |
| `tools/` | Offline tooling such as the voice pipeline. Hidden from Godot. |

A feature keeps its scene, script and resources together in its folder. Files and folders are `snake_case`.
