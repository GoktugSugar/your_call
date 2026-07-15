# Design Docs — Source of Truth

These files are the authoritative design for the game. They exist so anyone (human or AI) working on the project can get full context **without asking or inventing details.** Claude Code should read the relevant file before working in that area and treat it as authoritative over its own assumptions.

## Files
- `vision.md` — logline, concept, pillars, scope, tone, positioning.
- `gameplay.md` — core loop, the verbs (incl. multiple-choice), no-fail design, escalation, the no-right-answer question rule & sourcing, the how-others-chose hook, structure & endings.
- `narrative.md` — setting, narrator (the imp), protagonist, endings, and the silent who-you-are profile.
- `art-and-ui.md` — visual style, colour rules, UI/HUD philosophy, audio.
- `tech.md` — engine, stats system & backend, data model, git workflow, build plan.
- `decisions.md` — dated log of design decisions and any changes to them.
- `open-questions.md` — things not yet decided.
- `design-reference/` — a **visual style reference pack for Claude Design** (a hand-off, not a spec): a polished PDF (`your-call-style-guide.pdf`) documenting how the game *looks* and the design rules (palette + exact hex values, the line and figures, the imp, typography, UI conventions, the doodle catalogue, dos and don'ts), assembled from the docs plus in-engine `screenshots/`. `build-style-guide.py` regenerates the PDF (embedding whatever screenshots are present, placeholders otherwise); `SCREENSHOT-GUIDE.md` is the shot list and capture how-to. It reflects the docs, which stay authoritative — when they change, regenerate it.

## Maintenance rules (keep this real)
1. **Docs before drift.** When a decision changes, update the relevant file **and** log it in `decisions.md` in the same commit. Never let the docs lag behind the actual game.
2. **Undecided → open-questions.md.** Don't guess in the design docs; park unknowns there and resolve them explicitly.
3. **High signal.** Keep each file focused and current; rewrite stale content rather than piling caveats on top.
4. These docs supersede the earlier single-file design brief.
