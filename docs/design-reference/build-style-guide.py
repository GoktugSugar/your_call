#!/usr/bin/env python3
"""
Build the "Your Call" visual style reference PDF for Claude Design.

What it does
------------
Assembles docs/design-reference/your-call-style-guide.pdf from:
  * the design rules described in docs/ (baked into this script as the copy), and
  * the screenshots sitting in docs/design-reference/screenshots/.

For every screenshot slot the guide expects, if the PNG is present it is embedded;
if it is missing a clearly labelled placeholder with the intended caption is drawn
instead, so a first run (before the shots are captured) still produces a complete,
readable guide. Drop the missing PNGs into screenshots/ (using the documented file
names, see SCREENSHOT-GUIDE.md) and re-run this script to regenerate the finished PDF.

Requirements
------------
  * Python 3
  * Microsoft Edge (Chromium) OR Google Chrome, for the HTML -> PDF step.
    (No third-party Python packages are needed.)

Usage
-----
    python build-style-guide.py

Outputs (next to this script):
    your-call-style-guide.html   (self-contained, all assets inlined)
    your-call-style-guide.pdf
"""

import base64
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SHOTS = os.path.join(HERE, "screenshots")
FONT = os.path.join(REPO, "Assets", "Fonts", "Caveat", "Caveat-SemiBold.ttf")

HTML_OUT = os.path.join(HERE, "your-call-style-guide.html")
PDF_OUT = os.path.join(HERE, "your-call-style-guide.pdf")

# ---------------------------------------------------------------- palette
# Exact values from Assets/Scripts/Common/Palette.cs (the single source of truth).
PAPER = "#F5F2E9"
INK = "#1B1A17"
AMBER = "#E8951E"
MUTED = "#9A968C"
INK_BLUE = "#3C6496"
INK_RED = "#AA483A"
INK_BROWN = "#805C3D"
INK_PINK = "#D97392"
INK_GOLD = "#DBB447"
INK_GREEN = "#4E8C55"
INK_ORANGE = "#CC7A33"
INK_SKY = "#5E9BC4"
INK_PURPLE = "#8A5FA6"


def data_uri(path, mime):
    with open(path, "rb") as f:
        return "data:%s;base64,%s" % (mime, base64.b64encode(f.read()).decode("ascii"))


def font_face():
    if not os.path.exists(FONT):
        return ""
    uri = data_uri(FONT, "font/ttf")
    return ("@font-face{font-family:'Caveat';font-style:normal;font-weight:600;"
            "src:url(%s) format('truetype');}" % uri)


def shot(slot, caption, wide=False):
    """An embedded screenshot card, or a labelled placeholder if the PNG is absent."""
    png = os.path.join(SHOTS, slot + ".png")
    cls = "shot wide" if wide else "shot"
    if os.path.exists(png):
        uri = data_uri(png, "image/png")
        inner = '<img src="%s" alt="%s"/>' % (uri, caption)
        tag = ""
    else:
        inner = ('<div class="placeholder"><div class="ph-mark">screenshot</div>'
                 '<div class="ph-name">screenshots/%s.png</div></div>' % slot)
        tag = '<span class="pending">to capture</span>'
    return ('<figure class="%s"><div class="frame">%s</div>'
            '<figcaption><span class="cap-file">%s.png</span> %s %s</figcaption></figure>'
            % (cls, inner, slot, caption, tag))


def chapter_card(slot, tag, title, desc):
    """A gallery card for one chapter: the shot, a chapter tag, a title, and a one-liner."""
    png = os.path.join(SHOTS, slot + ".png")
    if os.path.exists(png):
        inner = '<img src="%s" alt="%s"/>' % (data_uri(png, "image/png"), title)
    else:
        inner = ('<div class="placeholder"><div class="ph-mark">screenshot</div>'
                 '<div class="ph-name">screenshots/%s.png</div></div>' % slot)
    return ('<figure class="chapcard"><div class="frame">%s</div>'
            '<div class="ct"><span class="ctag">%s</span><span class="ctitle">%s</span>'
            '<div class="cdesc">%s</div></div></figure>' % (inner, tag, title, desc))


def swatch(hexv, name, meaning):
    return ('<div class="sw"><span class="chip" style="background:%s"></span>'
            '<div class="sw-t"><b>%s</b><code>%s</code><span>%s</span></div></div>'
            % (hexv, name, hexv.upper(), meaning))


# ---------------------------------------------------------------- CSS
CSS = """
*{box-sizing:border-box;margin:0;padding:0}
:root{color-scheme:light}
html{-webkit-print-color-adjust:exact;print-color-adjust:exact}
body{font-family:'Segoe UI',-apple-system,Helvetica,Arial,sans-serif;
     color:__INK__;background:__PAPER__;font-size:10.4pt;line-height:1.5;
     background-image:radial-gradient(__PAPERDOT__ 0.6px,transparent 0.6px);
     background-size:5px 5px}
.hand{font-family:'Caveat','Segoe UI',cursive}
h1,h2,h3{font-family:'Caveat','Segoe UI',cursive;font-weight:600;line-height:1.05}
code{font-family:'Consolas','SFMono-Regular',monospace;font-size:0.82em;
     background:rgba(0,0,0,0.05);padding:1px 5px;border-radius:4px}
a{color:__AMBER__}
b,strong{font-weight:600}
em{font-style:italic;color:__INK__}

/* page geometry */
@page{size:A4;margin:15mm 14mm 16mm 14mm}
.wrap{max-width:186mm;margin:0 auto}
section{page-break-inside:auto}
.sec{padding-top:8mm}
.avoid{page-break-inside:avoid}
.pb{page-break-before:always}

/* cover */
.cover{min-height:250mm;display:flex;flex-direction:column;justify-content:center;text-align:center}
.cover .kicker{letter-spacing:0.32em;text-transform:uppercase;font-size:8.5pt;color:__MUTED__;margin-bottom:6mm}
.cover h1{font-size:58pt;letter-spacing:0.01em}
.cover .rule{width:120px;height:0;border-top:2.5px solid __INK__;margin:5mm auto 4mm;
     border-radius:40%;transform:rotate(-0.5deg)}
.cover .sub{font-size:17pt;color:__INK__}
.cover .imp{width:78px;margin:9mm auto 0;opacity:0.92}
.principle{margin:11mm auto 0;max-width:150mm;border:1.4px solid __INK__;border-radius:14px 12px 15px 11px;
     background:rgba(255,255,255,0.35);padding:6mm 8mm;text-align:left}
.principle .lab{font-size:8pt;letter-spacing:0.22em;text-transform:uppercase;color:__AMBER__;font-weight:700;margin-bottom:2mm}
.principle p{font-size:11.5pt}
.foot-note{margin-top:8mm;font-size:8.5pt;color:__MUTED__;text-align:center}

/* section headers */
.sec h2{font-size:26pt;display:flex;align-items:baseline;gap:10px}
.sec h2 .n{font-family:'Segoe UI';font-size:11pt;font-weight:700;color:__PAPER__;background:__AMBER__;
     border-radius:50%;width:24px;height:24px;display:inline-flex;align-items:center;justify-content:center;flex:0 0 auto;
     transform:translateY(-3px)}
.sec .lead{font-size:11pt;color:__INK__;margin:2mm 0 4mm;max-width:170mm}
.sec h3{font-size:15pt;margin:5mm 0 1.5mm}
p{margin:0 0 2.4mm}
ul{margin:0 0 3mm 0;padding-left:5mm}
li{margin:0 0 1.4mm}
.hr{height:0;border-top:1px solid rgba(0,0,0,0.14);margin:6mm 0}

/* palette */
.sws{display:grid;grid-template-columns:1fr 1fr;gap:2.5mm 7mm;margin:3mm 0 4mm}
.sw{display:flex;gap:3mm;align-items:flex-start}
.chip{flex:0 0 auto;width:26px;height:26px;border-radius:6px;border:1px solid rgba(0,0,0,0.25);margin-top:1px}
.sw-t{display:flex;flex-direction:column;line-height:1.32}
.sw-t b{font-size:10pt}
.sw-t code{align-self:flex-start;margin:1px 0}
.sw-t span{font-size:9pt;color:__MUTED__}

/* meaning table */
table{border-collapse:collapse;width:100%;margin:2mm 0 3mm;font-size:9.6pt}
th,td{text-align:left;padding:2mm 3mm;border-bottom:1px solid rgba(0,0,0,0.12);vertical-align:top}
th{font-size:8pt;letter-spacing:0.12em;text-transform:uppercase;color:__MUTED__;font-weight:700}
td .dot{display:inline-block;width:11px;height:11px;border-radius:50%;margin-right:6px;vertical-align:middle;border:1px solid rgba(0,0,0,0.2)}
td b{font-weight:600}

/* screenshots */
.shots{display:grid;grid-template-columns:1fr 1fr;gap:5mm;margin:3mm 0}
.shot{page-break-inside:avoid;margin:0}
.shot.wide{grid-column:1 / -1}
.frame{border:1.3px solid __INK__;border-radius:9px;overflow:hidden;background:__PAPER__;
     box-shadow:2px 3px 0 rgba(0,0,0,0.06)}
.frame img{width:100%;display:block}
figcaption{font-size:8.6pt;color:__INK__;margin-top:1.6mm;line-height:1.34}
.cap-file{font-family:'Consolas',monospace;font-size:7.6pt;color:__MUTED__}
.pending{display:inline-block;font-size:7pt;letter-spacing:0.08em;text-transform:uppercase;
     color:__AMBER__;border:1px solid __AMBER__;border-radius:4px;padding:0 4px;margin-left:3px;font-weight:700}
.placeholder{aspect-ratio:1900/922;display:flex;flex-direction:column;align-items:center;justify-content:center;
     background:repeating-linear-gradient(45deg,rgba(0,0,0,0.03),rgba(0,0,0,0.03) 10px,transparent 10px,transparent 20px);
     color:__MUTED__}
.ph-mark{font-family:'Caveat',cursive;font-size:20pt;color:__MUTED__}
.ph-name{font-family:'Consolas',monospace;font-size:8pt;margin-top:1mm;color:__MUTED__}

/* callouts */
.note{border-left:3px solid __AMBER__;background:rgba(232,149,30,0.07);padding:3mm 4mm;border-radius:0 8px 8px 0;margin:3mm 0;font-size:9.6pt}
.note b{color:__INK__}

/* dos and don'ts */
.dd{display:grid;grid-template-columns:1fr 1fr;gap:6mm;margin-top:3mm}
.dd .col{border:1.2px solid;border-radius:10px;padding:4mm 4mm 2mm}
.dd .do{border-color:__GREEN__;background:rgba(78,140,85,0.05)}
.dd .dont{border-color:__RED__;background:rgba(170,72,58,0.05)}
.dd h3{margin:0 0 2mm;font-size:15pt}
.dd .do h3{color:__GREEN__}
.dd .dont h3{color:__RED__}
.dd ul{list-style:none;padding:0;margin:0}
.dd li{position:relative;padding-left:6mm;font-size:9.5pt;margin-bottom:2mm}
.dd .do li:before{content:"\\2713";position:absolute;left:0;color:__GREEN__;font-weight:700}
.dd .dont li:before{content:"\\2715";position:absolute;left:0;color:__RED__;font-weight:700}

.tag{display:inline-block;font-size:8.5pt;font-family:'Consolas',monospace;background:rgba(0,0,0,0.05);
     border-radius:4px;padding:0 5px;color:__INK__}
.mini{font-size:8.6pt;color:__MUTED__;margin-top:1mm}

/* chapters gallery */
.gallery{display:grid;grid-template-columns:1fr 1fr;gap:5mm;margin:3mm 0}
.chapcard{page-break-inside:avoid;margin:0}
.chapcard .frame{border:1.3px solid __INK__;border-radius:9px;overflow:hidden;background:__PAPER__;box-shadow:2px 3px 0 rgba(0,0,0,0.06)}
.chapcard .frame img{width:100%;display:block}
.chapcard .ct{margin-top:1.8mm}
.chapcard .ctag{display:inline-block;font-size:7pt;letter-spacing:0.1em;text-transform:uppercase;color:__PAPER__;background:__AMBER__;border-radius:4px;padding:1px 6px;font-weight:700;vertical-align:middle}
.chapcard .ctitle{font-family:'Caveat','Segoe UI',cursive;font-size:15pt;margin-left:6px;vertical-align:middle}
.chapcard .cdesc{font-size:8.7pt;color:__INK__;margin-top:1mm;line-height:1.34}
"""

CSS = (CSS.replace("__INK__", INK).replace("__PAPER__", PAPER).replace("__AMBER__", AMBER)
       .replace("__MUTED__", MUTED).replace("__GREEN__", INK_GREEN).replace("__RED__", INK_RED)
       .replace("__PAPERDOT__", "rgba(0,0,0,0.035)"))


def colorword(word, hexv):
    return '<b style="color:%s">%s</b>' % (hexv, word)


# ---------------------------------------------------------------- body
def build_body():
    imp_uri = ""
    menu_png = os.path.join(SHOTS, "menu.png")
    parts = []

    # ---- COVER
    parts.append('<section class="cover avoid"><div class="wrap">')
    parts.append('<div class="kicker">Visual Style Reference &middot; for Claude Design</div>')
    parts.append('<h1>Your Call</h1><div class="rule"></div>')
    parts.append('<div class="sub hand">A hand-drawn ink-on-paper doodle world</div>')
    parts.append('<div class="principle"><div class="lab">The guiding principle</div>'
                 '<p><b>Black hand-drawn ink on a white paper ground.</b> The world must always read as '
                 'ink on a sketchbook page, never a full-colour scene. Colour is a deliberate accent used '
                 'for <b>meaning</b>, never decoration; the moment it turns decorative it stops meaning '
                 'anything. UI recedes: no HUD, no chrome, no pop-ups. The void and the figures carry every '
                 'screen, kept alive by a living, slightly wobbling line.</p></div>')
    parts.append('<div class="foot-note">This pack documents how the game <em>looks</em> and the rules that '
                 'govern it, so its visuals can be tidied and extended while matching the existing style '
                 'exactly. It is not about the plot. Source of truth: the project\'s <code>docs/</code> folder.</div>')
    parts.append('</div></section>')

    # ---- 1 OVERVIEW
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">1</span>Overview</h2>')
    parts.append('<p class="lead">A single-player narrative game of dark comedy, set in a cosmic void. '
                 'Everything is drawn as <b>black-and-white hand-drawn stick figures</b> in a doodle '
                 'aesthetic on a white paper ground: an animated sketchbook. Characters are built on '
                 '<b>reposable 2D skeletal rigs</b> (one rig posed into hundreds of scenes, never bespoke '
                 'art per scene), so the discipline everywhere is <em>repose the rig</em>, not <em>draw new '
                 'art</em>. Backgrounds are near-empty; the figures and their sparing marks of colour carry '
                 'the screen. Every question, silly or grave, resolves into a small animated ink '
                 'consequence.</p>')
    parts.append(shot("menu", "The main menu: the whole visual language in one frame — the Caveat title with its ink flourish, "
                              "the amber imp, a floating no-bubble bark, ink options on paper.", wide=True))
    parts.append('<div class="note"><b>Minimal, not sterile.</b> Minimal governs <em>how many</em> elements '
                 'are on screen (few, uncluttered). Character comes from four levers that add no clutter: a '
                 '<b>living ink line</b> (variable weight, slightly rough, a subtle boil that cycles two or '
                 'three near-identical frames so everything feels drawn and alive), <b>paper not blank '
                 'white</b>, <b>characterful hand-lettered type</b>, and <b>ink-like motion</b> (elements '
                 'draw themselves on and dissolve like ink). Never add UI chrome, decorative flourishes, or '
                 'busier screens to achieve character.</div>')
    parts.append('</div></section>')

    # ---- 2 CHAPTERS AT A GLANCE
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">2</span>The chapters at a glance</h2>')
    parts.append('<p class="lead">One representative frame per chapter. The game is a single ordered run; '
                 'the same conventions (ink on paper, deliberate colour, the imp, the dialogue box) carry '
                 'every chapter, while each chapter changes the <em>verb</em> and the imp\'s register.</p>')
    parts.append('<div class="gallery">')
    parts.append(chapter_card("trolley-lever", "Chapter 1", "The Tracks",
        "Trolley problems: the amber lever, the right-angle track, five against one. The clean teacher."))
    parts.append(chapter_card("buttons-bluered", "Chapter 2", "The Buttons",
        "Temptation by button. The blue/red coordination gamble, and the room whose vote decides a life."))
    parts.append(chapter_card("money-priceable", "Chapter 3", "The Money",
        "A finite balance (amber, top) spent on coloured item doodles at an amber price. What you value in cash."))
    parts.append(chapter_card("gun-bear", "Chapter 4", "The Gun",
        "First person, no avatar. The killing in your hands: the last bear against one ordinary man."))
    parts.append(chapter_card("matchup", "Chapter 5", "Who Would Win",
        "A change of pace. Barroom matchups of two coloured fighters; the crowd split is the whole payoff."))
    parts.append(chapter_card("booth", "Chapter 7", "The Confession Booth",
        "The dead judge does his job. A fixed ink confessional; souls file in for a three-verdict ruling."))
    parts.append(chapter_card("campaign", "Chapter 8", "The Campaign",
        "The imp runs a tabletop adventure as a bad, fantasy-breaking Dungeon Master. Class, dice, woven dilemmas."))
    parts.append('</div>')
    parts.append('<p class="mini">Chapter 6 is not yet built; Chapters 7 and 8 are reachable via the dev '
                 'picker and slot into the run once it lands. The menu, the endings, and the illustrated '
                 'would-you-rather breathers recur across chapters.</p>')
    parts.append('</div></section>')

    # ---- 3 PALETTE
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">3</span>The palette</h2>')
    parts.append('<p class="lead">The base identity is <b>black ink on a paper-white ground</b>. On top of '
                 'that base, colour is used deliberately as an accent for emphasis and meaning. There is '
                 '<b>no hard limit</b> on which colours or how many; the discipline is that every use of '
                 'colour carries meaning. All values below are the single source of truth from '
                 '<code>Palette.cs</code>.</p>')
    parts.append('<h3>Base + the accent</h3>')
    parts.append('<div class="sws">')
    parts.append(swatch(PAPER, "Paper", "The ground. A faint paper tint, never blank white."))
    parts.append(swatch(INK, "Ink", "Every line, figure, and word. A warm near-black."))
    parts.append(swatch(AMBER, "Amber", "THE accent. Attention & consequence only — the lever, the aim lock, a stressed word, hovers, flourishes."))
    parts.append(swatch(MUTED, "Muted ink", "Receded / secondary marks, captions, aftermath."))
    parts.append('</div>')
    parts.append('<h3>Meaningful colour (the fixed mapping)</h3>')
    parts.append('<table><thead><tr><th>Colour</th><th>Hex</th><th>Means</th></tr></thead><tbody>')
    for hexv, name, meaning in [
        (INK_RED, "Red", "Death & the guilty. Killing/dying, and the wretched, villain, murderer (kill, dies, folds, rotten, liars, cheats, monster). Also the red-outlined branded figures and the red button."),
        (AMBER, "Amber", "Stakes & emphasis. The counts (five, one, two), the weight of a choice, the balance readout. The one accent."),
        (INK_PINK, "Pink", "Love. The player's partner, drawn pink with a small pulsing heart."),
        (INK_GOLD, "Gold", "The best life (the golden crowned figure), and the money buttons (a gold $)."),
        (INK_BLUE, "Blue / Red", "The blue/red button dilemma only — its two crayon-wash buttons and its “how the room voted” bars."),
        (INK_BROWN, "Brown", "The last bear's muted fill wash, contained to her."),
    ]:
        parts.append('<tr><td><span class="dot" style="background:%s"></span><b>%s</b></td><td><code>%s</code></td><td>%s</td></tr>'
                     % (hexv, name, hexv.upper(), meaning))
    parts.append('</tbody></table>')
    parts.append('<h3>Doodle-outline colours</h3>')
    parts.append('<p>Coloured doodles (would-you-rathers, the money items, the fighters, the class props) draw '
                 'their <b>ink outline in a colour matched to what they depict</b> — a coloured line, '
                 '<em>never</em> a filled or painted fill. Muted, hand-drawn, so they read as coloured ink, '
                 'not flat digital colour.</p>')
    parts.append('<div class="sws">')
    parts.append(swatch(INK_GREEN, "Green", "Growth, luck, an hourglass, a cucumber, a dinosaur."))
    parts.append(swatch(INK_ORANGE, "Orange", "Warmth, the sun, a burrito, charisma."))
    parts.append(swatch(INK_SKY, "Sky", "Cold, a snowflake, a robot, the cheap forgetting."))
    parts.append(swatch(INK_PURPLE, "Purple", "Odd/mind, a brain, a wizard hat, a memory."))
    parts.append('</div>')
    parts.append('<div class="shots">')
    parts.append(shot("trolley-marked", "Red does double duty: the five branded wretches are drawn in red outline, and the guilt words "
                                        "(“rotten”, “Liars, cheaters”) render red in the narration. “five” is amber."))
    parts.append(shot("buttons-bluered", "The blue/red buttons: a muted crayon-wash inside the black ink linework, never flat digital colour. "
                                         "The buttons ARE their colours."))
    parts.append('</div>')
    parts.append('</div></section>')

    # ---- 3 LINE & FIGURES
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">4</span>The line &amp; the figures</h2>')
    parts.append('<p class="lead">Everything is drawn from a handful of hand-drawn ink strokes with a '
                 '<b>living line</b>: variable weight, slightly rough, with a subtle <b>boil</b> (cycling two '
                 'or three near-identical frames) so it always feels drawn, never clean geometric vector. '
                 'Figures keep a tiny idle life — a breath, a bob.</p>')
    parts.append('<h3>On-model figures, minimal faces</h3>')
    parts.append('<p>The people are androgynous stick figures on the shared rig. Faces stay <b>deliberately '
                 'minimal</b> — dot eyes, the smallest features — because a sparse face reads '
                 'friendly and a detailed one reads creepy. This is a hard rule: <b>no detailed or creepy '
                 'faces anywhere</b>. The player character is <b>never drawn</b> (the game is his first-person '
                 'point of view); the figures are always the <em>other</em> souls.</p>')
    parts.append('<h3>How special figures read</h3>')
    parts.append('<ul>'
                 '<li><b style="color:%s">Red outline</b> — anyone the imp brands a wretch/villain/guilty. The whole ink line is red; it is the imp\'s branding made visible, not proof.</li>' % INK_RED +
                 '<li><b style="color:%s">Pink + a heart</b> — the player\'s partner, with a small pulsing ink heart bobbing over the head.</li>' % INK_PINK +
                 '<li><b>Smaller</b> — children are the normal figure scaled down (feet on the same line), and the imp names them children.</li>' +
                 '<li><b>Elderly</b> — slightly stooped, leaning on a cane, a few sparse hair wisps; the imp also names them old (the stick style can only carry so much).</li>' +
                 '<li><b style="color:%s">Gold + a crown</b> — the best life any human has lived; on the swap the gold drains to plain ink.</li>' % INK_GOLD +
                 '<li><b style="color:%s">Brown fill</b> — the last bear: a muted brown wash inside her black outline, front-facing, minimal friendly face, ears as open bumps on the head outline (never full circles).</li>' % INK_BROWN +
                 '<li><b>Sleeping</b> — a few drifting “z” marks rising from the head; they stop the instant the figure is struck.</li>' +
                 '<li><b>The future baby</b> — a clean baby doodle with two deliberately abstract, one-step-removed cues (a small square mustache, a paintbrush); never a real likeness.</li>'
                 '</ul>')
    parts.append('<div class="note"><b>Death is the fall, not a mark.</b> When a figure is struck it only '
                 'folds, topples and fades as one stroke — no strike lines, no impact puff drawn over '
                 'it.</div>')
    parts.append('<div class="shots">')
    parts.append(shot("trolley-loved", "The partner: a pink figure with a pulsing ink heart on the divert track. “the one you loved most” renders pink."))
    parts.append(shot("trolley-fulltrack", "The shared rig reposed: two small children, a pregnant figure, three adults across three rails — all one rig, scaled and posed."))
    parts.append('</div>')
    parts.append('</div></section>')

    # ---- 4 THE IMP
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">5</span>The imp</h2>')
    parts.append('<p class="lead">The narrator, embodied: a small hand-drawn devil in ink — little '
                 '<b>horns</b>, a curling <b>tail</b> with a spade tip, a mischievous <b>grin</b>, tiny '
                 'arms and legs. It scribbles into being (a scale-and-wobble pop-in) and delivers all of the '
                 'narration; it stirs and leans while its words ink on, so each line reads as coming from it. '
                 'It keeps a restless idle life (bob, sway, a subtle breath).</p>')
    parts.append('<h3>Colour &amp; expressions</h3>')
    parts.append('<p>The imp is currently tinted the <b style="color:%s">amber</b> accent (an in-progress '
                 'choice, kept revertible to plain ink). It can carry one of a few on-model faces — a '
                 'default <b>grin</b>, a <b>wide grin</b>, a <b>smug</b> side-eye, a <b>glare</b>, a '
                 '<b>surprised</b> round-eyed look — each just a different eyes-and-mouth configuration '
                 'in its own line, behind a single master toggle. It keeps to the wings and margins, never '
                 'the centre where the action belongs.</p>' % AMBER)
    parts.append('<p>On the menu it speaks as <b>plain ink text floating directly over it</b> — no '
                 'bubble, box, tail, or background, just the words on the paper. It is the on-screen voice; '
                 'it never blocks input.</p>')
    parts.append(shot("imp-closeup", "A clean close-up of the imp — horns, tail, grin, the amber tint, an expression."))
    parts.append('</div></section>')

    # ---- 5 TYPOGRAPHY
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">6</span>Typography</h2>')
    parts.append('<p class="lead">All narration and menu text is set in <b class="hand" style="font-size:1.25em">Caveat</b>, '
                 'a handwriting font (SemiBold, scoped to the narration), so the words carry voice rather '
                 'than reading as system UI. It is a dynamic TMP atlas; the full <b>Turkish</b> character set '
                 'is baked in, so every shipped language renders in the same handwritten hand with no missing '
                 'glyphs. The whole line is laid out before it types and the glyphs are then revealed in '
                 'place by vertex alpha, so centred text <b>never shifts a pixel</b> while it inks on.</p>')
    parts.append('<h3>Inline colour-emphasis markup</h3>')
    parts.append('<p>A few meaningful words per line are coloured by the fixed mapping, authored inline in '
                 'the copy as simple tags the writer applies (<code>[amber]</code>, <code>[red]</code>, '
                 '<code>[blue]</code>, <code>[pink]</code>, <code>[gold]</code>) and routed through the same '
                 '<code>Palette</code>. Used with restraint (a few words, not everything), so it reads as a '
                 'system, not decoration. No word ever gets an invented colour. The markup <b>travels per '
                 'language</b> — each translation marks its own equivalent words.</p>')
    parts.append('<div class="note"><b>The no-dashes rule (hard constraint, every language).</b> There are '
                 '<b>no dashes</b> in any player-facing text. Use commas, full stops, or restructure the '
                 'sentence; Turkish uses Turkish-appropriate punctuation. This holds in menus, dilemmas, '
                 'barks, credits, and number readouts alike.</div>')
    parts.append(shot("trolley-lever", "The dialogue box in Caveat, centred; the counts “Five” and “One” picked out in amber as the stakes.", wide=True))
    parts.append('</div></section>')

    # ---- 6 UI CONVENTIONS
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">7</span>UI conventions</h2>')
    parts.append('<p class="lead">The interface recedes so the void and the figures dominate. <b>No large '
                 'HUD</b> (the silent profile is never shown as a gauge), <b>no big menus</b>, <b>no '
                 'pop-ups or modal chrome</b>, minimal on-screen detail. Every UI element must justify its '
                 'presence.</p>')
    parts.append('<h3>The sanctioned exceptions</h3>')
    parts.append('<ul>'
                 '<li><b>The dialogue box.</b> A rounded hand-drawn ink box near the bottom that floats clear '
                 'of the edge, with a faint paper fill and an ink border kept alive by a slight controlled '
                 'wobble (not a rough scribble, not a sterile vector rectangle). Text is centred Caveat; long '
                 'narration <b>pages by whole sentences</b> (a sentence is never split). No portraits, no '
                 'buttons.</li>'
                 '<li><b>The main menu &amp; settings.</b> The one place a real menu belongs — kept '
                 'hand-drawn and spare in the ink hand, amber only on the current selection and an '
                 'on-toggle. The in-game Esc pause overlay is part of the same exception.</li>'
                 '</ul>')
    parts.append('<div class="note">A stylised ink frame for the narrator\'s words, and the menu, are '
                 'allowed. Heavy chrome and modal pop-ups are <b>not</b>.</div>')
    parts.append('<h3>In-scene affordances</h3>')
    parts.append('<ul>'
                 '<li><b>Choice options</b> sit in a row in the choice-affordance area just above the '
                 'dialogue box, clear of the scene: ink text, brighter on hover, <b>no amber</b> (amber '
                 'stays for the scene\'s own accents like the lever). They read as part of the scene, not '
                 'chrome.</li>'
                 '<li><b>The balance readout</b> (money chapter) rides along at the top, the amount in '
                 '<b style="color:%s">amber</b> under a muted caption.</li>' % AMBER +
                 '<li><b>Floating pleas</b> sit as plain ink over a figure\'s head, no bubble, a comfortable '
                 'clearance above the head at any figure size.</li>'
                 '<li><b>The crowd-stat reveal</b> (“how others chose”) presents on its own after '
                 'the choice lands: reflective bars in the ink style with the player\'s own pick emphasised '
                 'in amber. It is the beat every question ends on.</li>'
                 '<li><b>The credits</b> are the one full-screen text page: a clean white ground, each role '
                 'label in amber over its name in ink, in the Caveat hand.</li>'
                 '</ul>')
    parts.append('<div class="shots">')
    parts.append(shot("stats-reveal", "“How others chose” — the reflective crowd bars, the player's own pick picked out in amber."))
    parts.append(shot("money-priceable", "A money-chapter offer: a coloured-outline item doodle, the amber price tag, the amber balance up top, plain buy/pass text."))
    parts.append('</div>')
    parts.append('</div></section>')

    # ---- 7 DOODLE CATALOGUE
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">8</span>Doodle catalogue</h2>')
    parts.append('<p class="lead">Recurring on-model props, each built from the same ink strokes with the '
                 'living-line boil. Coloured props draw a coloured <b>outline</b> matched to what they depict, '
                 'never a fill. A “many of something” crowd is drawn as a stylised cluster of small '
                 'copies with the real count carried by a label, never the literal count.</p>')
    parts.append('<ul>'
                 '<li><b>The trolley set</b> — the ink cart with its antenna, the tracks (a schematic '
                 'right-angle switch, never a curve), the amber lever, the ties.</li>'
                 '<li><b>The blue/red buttons</b>, the gold <b>$ money button</b>, and the plain ink '
                 'push-buttons (amber only on hover, a quick press squash).</li>'
                 '<li><b>The walking button</b> — a plain button that sprouts stick limbs and a put-out '
                 'face and strides off; a recurring gag figure reused across chapters.</li>'
                 '<li><b>The nuke map</b> — a simplified hand-drawn ink world map with a small classic '
                 'red map pin that drops onto a country; the population reads out in amber. No cartoon '
                 'blast.</li>'
                 '<li><b>Coloured item doodles</b> — the would-you-rather pairs and the money items (a '
                 'clover, sunglasses, a brain, an hourglass, a pack of cigarettes, a cucumber...), each a '
                 'coloured line matched to the thing.</li>'
                 '<li><b>The fighters</b> (Who Would Win) — polished coloured doodles: a gorilla, a '
                 'lion, a grizzly, a wasp, a boxer, and crowds of small brawlers.</li>'
                 '<li><b>The class props &amp; the die</b> (the Campaign) — a sword-and-shield, a '
                 'dagger, a wizard hat, a lute, a chalice; and a hand-drawn ink <b>d6</b> that tumbles onto '
                 'a face with an amber flash.</li>'
                 '<li><b>The confession booth</b> — one fixed set piece: an ink confessional with a '
                 'latticed grille, drawn once and held for the whole docket.</li>'
                 '</ul>')
    parts.append('<div class="shots">')
    parts.append(shot("buttons-crowned", "Gold = the best life: a golden stick figure in a small hand-drawn crown, inked in as the imp sells the life."))
    parts.append(shot("nuke-map", "The ink world map with a small red map pin on the chosen country; the population reads out in amber."))
    parts.append(shot("matchup", "The two-doodle matchup format (Who Would Win): two coloured fighters side by side with counts, a muted “vs”."))
    parts.append(shot("dice", "The DiceRoll set piece: a hand-drawn ink d6, the odds caption, an amber flash on the landed value."))
    parts.append(shot("booth", "The confession booth: the fixed ink confessional (drawn once, held for the whole docket), a confessor filing into the doorway with a floating headline over them."))
    parts.append(shot("gun-bear", "The last bear, her muted brown fill inside a black ink line, faced first-person (no avatar) against one ordinary man; the extinction stakes carried in amber."))
    parts.append('</div>')
    parts.append('</div></section>')

    # ---- 8 DOS & DON'TS
    parts.append('<section class="sec pb"><div class="wrap">')
    parts.append('<h2><span class="n">9</span>Design do’s &amp; don’ts</h2>')
    parts.append('<p class="lead">For anyone extending or tidying the visuals.</p>')
    parts.append('<div class="dd">')
    parts.append('<div class="col do"><h3>Do</h3><ul>'
                 '<li>Keep everything <b>ink on paper</b> — a hand-drawn line with a subtle boil, on a faintly-textured paper ground.</li>'
                 '<li>Make every use of colour <b>carry meaning</b> from the fixed mapping.</li>'
                 '<li>Reserve <b>amber</b> for attention, consequence, hovers and flourishes only.</li>'
                 '<li>Keep faces <b>minimal</b> (dot eyes, tiny features).</li>'
                 '<li><b>Repose the shared rig</b> for new characters; scale it for children.</li>'
                 '<li>Colour doodles with a matched <b>outline</b>, never a fill.</li>'
                 '<li>Draw crowds as a <b>stylised cluster</b>, the count in a label.</li>'
                 '<li>Let elements <b>draw on and dissolve like ink</b>; keep a tiny idle life.</li>'
                 '<li>Keep new copy <b>dash-free</b>, in the Caveat hand, in every language.</li>'
                 '</ul></div>')
    parts.append('<div class="col dont"><h3>Don’t</h3><ul>'
                 '<li>Add a <b>HUD</b>, status meters, or a visible profile/score gauge.</li>'
                 '<li>Add <b>chrome UI</b>, cluttered menus, or modal pop-ups (the dialogue box and menu are the only exceptions).</li>'
                 '<li>Spend colour on <b>decoration</b> — if it means nothing, it stops meaning anything.</li>'
                 '<li>Draw <b>detailed or creepy faces</b>, or full-circle bear ears laid over the head.</li>'
                 '<li>Create <b>bespoke per-scene character art</b> instead of reposing the rig.</li>'
                 '<li>Fill a doodle with colour (use a coloured <b>line</b>).</li>'
                 '<li>Use clean geometric <b>vector</b> lines, or a blank pure-white background.</li>'
                 '<li>Draw strike lines or an impact puff over a struck figure (it just <b>folds and fades</b>).</li>'
                 '<li>Put a <b>dash</b> in any player-facing text.</li>'
                 '</ul></div>')
    parts.append('</div>')
    parts.append('<div class="hr"></div>')
    parts.append('<p class="mini">Values and rules in this pack are drawn from <code>docs/art-and-ui.md</code>, '
                 '<code>docs/vision.md</code>, <code>docs/gameplay.md</code>, <code>docs/narrative.md</code> '
                 'and <code>Assets/Scripts/Common/Palette.cs</code>. When a rule here and the docs ever '
                 'disagree, the docs win — regenerate this pack.</p>')
    parts.append('</div></section>')

    return "\n".join(parts)


def build_html():
    body = build_body()
    html = ("<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'>"
            "<title>Your Call — Visual Style Reference</title>"
            "<style>" + font_face() + CSS + "</style></head><body>" + body + "</body></html>")
    with open(HTML_OUT, "w", encoding="utf-8") as f:
        f.write(html)
    return html


def find_browser():
    candidates = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return None


def to_pdf():
    browser = find_browser()
    if not browser:
        print("[warn] No Edge/Chrome found; wrote HTML only. Open the HTML and Print > Save as PDF.")
        return False
    url = "file:///" + HTML_OUT.replace("\\", "/")
    for headless in ("--headless=new", "--headless"):
        cmd = [browser, headless, "--disable-gpu", "--no-pdf-header-footer",
               "--print-to-pdf=" + PDF_OUT, url]
        try:
            subprocess.run(cmd, check=True, timeout=120,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print("[info] %s failed (%s), trying next..." % (headless, e))
            continue
        if os.path.exists(PDF_OUT) and os.path.getsize(PDF_OUT) > 2000:
            return True
    return os.path.exists(PDF_OUT)


def main():
    n_present = sum(1 for s in os.listdir(SHOTS) if s.lower().endswith(".png")) if os.path.isdir(SHOTS) else 0
    build_html()
    print("[ok] HTML  -> %s" % HTML_OUT)
    print("[ok] Screenshots embedded from %s (%d PNG present)" % (SHOTS, n_present))
    if to_pdf():
        print("[ok] PDF   -> %s (%d KB)" % (PDF_OUT, os.path.getsize(PDF_OUT) // 1024))
    else:
        print("[warn] PDF not produced; the HTML is complete and printable.")


if __name__ == "__main__":
    main()
