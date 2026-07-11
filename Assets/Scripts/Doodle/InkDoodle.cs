using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A small hand-drawn ink doodle illustrating one would-you-rather option, drawn from the shared ink
    /// strokes (LineRenderers, the same material, weight and boil as the rest of the game), so it reads
    /// on-model in the black-ink-on-paper doodle style (see docs/art-and-ui.md). One reusable component:
    /// which doodle it draws is a <see cref="DoodleKind"/>, so a would-you-rather references its art as
    /// data. It inks in and out like anything else. One job: draw the requested doodle.
    ///
    /// Each doodle is a small parametric drawer below, composed from arcs, spirals and line segments in a
    /// roughly [-1,1] box centred on the origin, so the beat can scale and place it. Adding a brand new
    /// doodle is a new <see cref="DoodleKind"/> value plus a drawer case here; adding a new question that
    /// reuses existing doodles is pure data.
    /// </summary>
    public sealed class InkDoodle : MonoBehaviour
    {
        private Material _mat;
        private Color _color = Palette.Ink;
        private float _width = 0.05f;
        private int _sorting = 14;
        private bool _boil = true;

        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private bool _built;

        /// <summary>Build a doodle of <paramref name="kind"/> under a parent, ready to fade in.</summary>
        public static InkDoodle Create(Transform parent, string name, Vector3 localPos, float scale,
            DoodleKind kind, Material material, Color? color = null, float width = 0.05f, int sorting = 14)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            go.transform.localScale = new Vector3(scale, scale, 1f);
            var d = go.AddComponent<InkDoodle>();
            d._mat = material;
            d._color = color ?? Palette.Ink;
            d._width = width;
            d._sorting = sorting;
            d.Build(kind);
            return d;
        }

        public void Build(DoodleKind kind)
        {
            if (_built) return;
            DrawKind(kind);
            _built = true;
            SetAlpha(0f);
        }

        /// <summary>The sensible outline colour for a doodle, matched to the thing it depicts (a coloured
        /// ink line, not a fill; see docs/art-and-ui.md). This is the doodle's colour data; a would-you-rather
        /// can override it per option (see Dilemma.OptionAOutline). None / unknown stays plain ink.</summary>
        public static Color DefaultColorFor(DoodleKind kind)
        {
            switch (kind)
            {
                case DoodleKind.TurdSwirl: return Palette.InkBrown;   // poop, brown
                case DoodleKind.ConeSwirl: return Palette.InkPink;    // ice cream, pink
                case DoodleKind.WingedFigure: return Palette.InkBlue; // flight, sky
                case DoodleKind.FlexingFigure: return Palette.InkRed; // strength, power
                case DoodleKind.GiantDuck: return Palette.InkGreen;   // a duck, green
                case DoodleKind.TinyHorses: return Palette.InkBrown;  // horses, brown
                case DoodleKind.RewindButton: return Palette.InkBlue; // rewind, cool
                case DoodleKind.PauseButton: return Palette.InkOrange;// pause, warm hold
                case DoodleKind.Snowflake: return Palette.InkSky;     // cold, ice blue
                case DoodleKind.Sun: return Palette.InkOrange;        // hot, warm
                case DoodleKind.ThirdArmFigure: return Palette.InkGreen;  // an odd body, quirky
                case DoodleKind.TwoHeadFigure: return Palette.InkPurple;  // an odd body, quirky

                // Chapter 3 (the money): each priceable thing gets a matched coloured outline.
                case DoodleKind.Poverty: return Palette.InkGold;      // charity / money, gold
                case DoodleKind.Burrito: return Palette.InkOrange;    // warm food
                case DoodleKind.Kebab: return Palette.InkRed;         // grilled meat, warm
                case DoodleKind.Nose: return Palette.InkPink;         // skin
                case DoodleKind.Hourglass: return Palette.InkGreen;   // a year of life
                case DoodleKind.CigarettePack: return Palette.InkRed; // a warning red
                case DoodleKind.Bandage: return Palette.InkPink;      // skin / hurt
                case DoodleKind.MemoryCloud: return Palette.InkPurple;// the mind
                case DoodleKind.StolenYears: return Palette.InkRed;   // taking a life, the horror
                case DoodleKind.Forgetting: return Palette.InkSky;    // fading, cool
                case DoodleKind.Tombstone: return Palette.Muted;      // somber stone
                case DoodleKind.Coin: return Palette.InkGold;         // money
                case DoodleKind.Star: return Palette.InkGold;         // something bright / meaningful
                case DoodleKind.Candy: return Palette.InkPink;        // cheap sweet

                // Chapter 3 rework: the ten double-edged items, the cucumber, the question mark.
                case DoodleKind.Charisma: return Palette.InkOrange;   // warmth / being adored
                case DoodleKind.OffSwitch: return Palette.InkSky;     // cool detachment
                case DoodleKind.PerfectMemory: return Palette.InkPurple; // the mind
                case DoodleKind.LieDetector: return Palette.InkGreen; // detector / truth
                case DoodleKind.Rewind: return Palette.InkBlue;       // time / undo
                case DoodleKind.IqUp: return Palette.InkPurple;       // intelligence / the mind
                case DoodleKind.NeverTired: return Palette.InkRed;    // wired, alert
                case DoodleKind.Clover: return Palette.InkGreen;      // luck, green
                case DoodleKind.FeelNothing: return Palette.Muted;    // numb, greyed
                case DoodleKind.InnerVoice: return Palette.InkSky;    // a guiding voice
                case DoodleKind.Cucumber: return Palette.InkGreen;    // a cucumber, green
                case DoodleKind.QuestionMark: return Palette.Muted;   // the somber mystery of the death

                default: return Palette.Ink;
            }
        }

        private void DrawKind(DoodleKind kind)
        {
            switch (kind)
            {
                case DoodleKind.TurdSwirl: Turd(); break;
                case DoodleKind.ConeSwirl: Cone(); break;
                case DoodleKind.WingedFigure: WingedFigure(); break;
                case DoodleKind.FlexingFigure: FlexingFigure(); break;
                case DoodleKind.GiantDuck: GiantDuck(); break;
                case DoodleKind.TinyHorses: TinyHorses(); break;
                case DoodleKind.RewindButton: ControlButton(rewind: true); break;
                case DoodleKind.PauseButton: ControlButton(rewind: false); break;
                case DoodleKind.Snowflake: Snowflake(); break;
                case DoodleKind.Sun: Sun(); break;
                case DoodleKind.ThirdArmFigure: ThirdArmFigure(); break;
                case DoodleKind.TwoHeadFigure: TwoHeadFigure(); break;

                // Chapter 3 (the money) doodles.
                case DoodleKind.Poverty: Poverty(); break;
                case DoodleKind.Burrito: Burrito(); break;
                case DoodleKind.Kebab: Kebab(); break;
                case DoodleKind.Nose: Nose(); break;
                case DoodleKind.Hourglass: Hourglass(); break;
                case DoodleKind.CigarettePack: CigarettePack(); break;
                case DoodleKind.Bandage: Bandage(); break;
                case DoodleKind.MemoryCloud: MemoryCloud(); break;
                case DoodleKind.StolenYears: StolenYears(); break;
                case DoodleKind.Forgetting: Forgetting(); break;
                case DoodleKind.Tombstone: Tombstone(); break;
                case DoodleKind.Coin: Coin(); break;
                case DoodleKind.Star: Star(); break;
                case DoodleKind.Candy: Candy(); break;

                // Chapter 3 rework doodles.
                case DoodleKind.Charisma: Charisma(); break;
                case DoodleKind.OffSwitch: OffSwitch(); break;
                case DoodleKind.PerfectMemory: PerfectMemory(); break;
                case DoodleKind.LieDetector: LieDetector(); break;
                case DoodleKind.Rewind: Rewind(); break;
                case DoodleKind.IqUp: IqUp(); break;
                case DoodleKind.NeverTired: NeverTired(); break;
                case DoodleKind.Clover: Clover(); break;
                case DoodleKind.FeelNothing: FeelNothing(); break;
                case DoodleKind.InnerVoice: InnerVoice(); break;
                case DoodleKind.Cucumber: Cucumber(); break;
                case DoodleKind.QuestionMark: QuestionMark(); break;
                default: break;
            }
        }

        // ---------- drawing helpers ----------

        private LineRenderer Stroke(string name, List<Vector3> pts, float width = 0f)
        {
            var lr = InkLine.Create(transform, name, _mat, width > 0f ? width : _width, _color, _sorting);
            InkLine.SetPoints(lr, pts);
            if (_boil) lr.gameObject.AddComponent<LineBoil>().Capture();
            _strokes.Add(lr);
            return lr;
        }

        private static List<Vector3> Circle(Vector2 c, float r, int seg = 26)
        {
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, c, r, 0f, 360f, seg);
            return pts;
        }

        private static List<Vector3> Line(params Vector2[] p)
        {
            var pts = new List<Vector3>(p.Length);
            for (int i = 0; i < p.Length; i++) pts.Add(new Vector3(p[i].x, p[i].y, 0f));
            return pts;
        }

        // A soft-serve / poop swirl: a coil that narrows as it rises, ending in a little tip flick.
        private List<Vector3> Swirl(float baseY, float topY, float baseR, float turns)
        {
            var pts = new List<Vector3>();
            int seg = 64;
            for (int i = 0; i <= seg; i++)
            {
                float t = i / (float)seg;
                float ang = t * turns * Mathf.PI * 2f + Mathf.PI * 0.5f;
                float r = Mathf.Lerp(baseR, baseR * 0.14f, t);
                float y = Mathf.Lerp(baseY, topY, t);
                pts.Add(new Vector3(Mathf.Cos(ang) * r, y + Mathf.Sin(ang) * r * 0.35f, 0f));
            }
            pts.Add(new Vector3(0.06f, topY + 0.14f, 0f)); // the little tip
            return pts;
        }

        // ---------- the doodles ----------

        private void Turd()
        {
            Stroke("Swirl", Swirl(-0.45f, 0.55f, 0.5f, 2.7f));
            // a shallow puddle it sits in
            var puddle = new List<Vector3>();
            InkLine.AddArc(puddle, new Vector2(0f, -0.55f), 0.55f, 200f, 340f, 18);
            Stroke("Puddle", puddle, _width * 0.8f);
        }

        private void Cone()
        {
            Stroke("Swirl", Swirl(-0.05f, 0.7f, 0.44f, 2.7f));
            // the cone (point down), plus two waffle cross lines
            Stroke("Cone", Line(new Vector2(-0.42f, -0.05f), new Vector2(0f, -0.85f), new Vector2(0.42f, -0.05f)));
            Stroke("Waffle1", Line(new Vector2(-0.26f, -0.28f), new Vector2(0.1f, -0.3f)), _width * 0.7f);
            Stroke("Waffle2", Line(new Vector2(-0.14f, -0.5f), new Vector2(0.16f, -0.52f)), _width * 0.7f);
        }

        private void WingedFigure()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.46f), 0.15f));
            Stroke("Body", Line(new Vector2(0f, 0.31f), new Vector2(0f, -0.18f)));
            // legs trailing together, as if aloft
            Stroke("LegL", Line(new Vector2(0f, -0.18f), new Vector2(-0.14f, -0.56f)));
            Stroke("LegR", Line(new Vector2(0f, -0.18f), new Vector2(0.16f, -0.54f)));
            // two wings sweeping UP and out from the back, with a couple of feather scallops
            Stroke("WingL", Line(new Vector2(0f, 0.26f), new Vector2(-0.34f, 0.56f), new Vector2(-0.74f, 0.66f), new Vector2(-0.5f, 0.44f), new Vector2(-0.66f, 0.4f), new Vector2(-0.42f, 0.28f), new Vector2(-0.02f, 0.24f)));
            Stroke("WingR", Line(new Vector2(0f, 0.26f), new Vector2(0.34f, 0.56f), new Vector2(0.74f, 0.66f), new Vector2(0.5f, 0.44f), new Vector2(0.66f, 0.4f), new Vector2(0.42f, 0.28f), new Vector2(0.02f, 0.24f)));
            // a couple of motion lines below, so it reads as airborne
            Stroke("Motion1", Line(new Vector2(-0.28f, -0.42f), new Vector2(-0.5f, -0.42f)), _width * 0.7f);
            Stroke("Motion2", Line(new Vector2(0.28f, -0.4f), new Vector2(0.52f, -0.4f)), _width * 0.7f);
        }

        private void FlexingFigure()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.5f), 0.16f));
            Stroke("Body", Line(new Vector2(0f, 0.34f), new Vector2(0f, -0.22f)));
            Stroke("LegL", Line(new Vector2(0f, -0.22f), new Vector2(-0.2f, -0.62f)));
            Stroke("LegR", Line(new Vector2(0f, -0.22f), new Vector2(0.2f, -0.62f)));
            // left arm down to the hip
            Stroke("ArmL", Line(new Vector2(0f, 0.26f), new Vector2(-0.26f, 0.12f), new Vector2(-0.2f, -0.05f)));
            // right arm flexed up: shoulder -> elbow -> fist by the head, with a bicep bulge
            Stroke("ArmR", Line(new Vector2(0f, 0.26f), new Vector2(0.34f, 0.2f), new Vector2(0.3f, 0.5f)));
            var bicep = new List<Vector3>();
            InkLine.AddArc(bicep, new Vector2(0.24f, 0.34f), 0.12f, -40f, 150f, 12);
            Stroke("Bicep", bicep, _width * 0.85f);
        }

        private void GiantDuck()
        {
            // fat body (an ellipse, drawn as a scaled circle loop)
            var body = new List<Vector3>();
            for (int i = 0; i <= 30; i++)
            {
                float a = i / 30f * Mathf.PI * 2f;
                body.Add(new Vector3(-0.05f + Mathf.Cos(a) * 0.7f, -0.12f + Mathf.Sin(a) * 0.46f, 0f));
            }
            Stroke("Body", body);
            Stroke("Head", Circle(new Vector2(0.5f, 0.4f), 0.27f));
            Stroke("Beak", Line(new Vector2(0.73f, 0.46f), new Vector2(1.02f, 0.36f), new Vector2(0.74f, 0.24f)));
            Stroke("Eye", Circle(new Vector2(0.55f, 0.46f), 0.035f, 8));
            // a wing curve on the body and a jaunty tail
            var wing = new List<Vector3>();
            InkLine.AddArc(wing, new Vector2(-0.05f, 0f), 0.4f, 200f, 340f, 16);
            Stroke("Wing", wing, _width * 0.85f);
            Stroke("Tail", Line(new Vector2(-0.72f, 0.02f), new Vector2(-0.95f, 0.2f)));
        }

        private void TinyHorses()
        {
            // a little scattered herd of simple horse silhouettes; the label carries "a hundred".
            Vector2[] at =
            {
                new Vector2(-0.55f, 0.35f), new Vector2(0.0f, 0.42f), new Vector2(0.55f, 0.3f),
                new Vector2(-0.35f, -0.2f), new Vector2(0.28f, -0.22f), new Vector2(-0.02f, -0.55f),
            };
            for (int i = 0; i < at.Length; i++) TinyHorse(at[i], 0.28f, i);
        }

        private void TinyHorse(Vector2 c, float s, int idx)
        {
            // a small side-view quadruped: an oval body (a clear mass), four legs, a neck and head up
            // forward, and a tail down back. Facing right. The label carries "a hundred".
            var body = new System.Collections.Generic.List<Vector3>();
            for (int i = 0; i <= 16; i++)
            {
                float a = i / 16f * Mathf.PI * 2f;
                body.Add(new Vector3(c.x + Mathf.Cos(a) * 0.32f * s, c.y + Mathf.Sin(a) * 0.18f * s, 0f));
            }
            Stroke("HBody" + idx, body, _width * 0.8f);
            Stroke("HL1" + idx, Line(c + new Vector2(-0.22f, -0.12f) * s, c + new Vector2(-0.24f, -0.52f) * s), _width * 0.75f);
            Stroke("HL2" + idx, Line(c + new Vector2(-0.06f, -0.16f) * s, c + new Vector2(-0.07f, -0.54f) * s), _width * 0.75f);
            Stroke("HL3" + idx, Line(c + new Vector2(0.12f, -0.16f) * s, c + new Vector2(0.13f, -0.54f) * s), _width * 0.75f);
            Stroke("HL4" + idx, Line(c + new Vector2(0.26f, -0.12f) * s, c + new Vector2(0.29f, -0.52f) * s), _width * 0.75f);
            Stroke("HNeck" + idx, Line(c + new Vector2(0.28f, 0.06f) * s, c + new Vector2(0.52f, 0.42f) * s, c + new Vector2(0.66f, 0.3f) * s), _width * 0.8f);
            Stroke("HTail" + idx, Line(c + new Vector2(-0.32f, 0.04f) * s, c + new Vector2(-0.54f, -0.24f) * s), _width * 0.75f);
        }

        private void ControlButton(bool rewind)
        {
            Stroke("Ring", Circle(new Vector2(0f, 0f), 0.62f, 34));
            if (rewind)
            {
                Stroke("Tri1", Line(new Vector2(0.12f, 0.22f), new Vector2(-0.16f, 0f), new Vector2(0.12f, -0.22f), new Vector2(0.12f, 0.22f)), _width * 0.9f);
                Stroke("Tri2", Line(new Vector2(0.4f, 0.22f), new Vector2(0.12f, 0f), new Vector2(0.4f, -0.22f), new Vector2(0.4f, 0.22f)), _width * 0.9f);
            }
            else
            {
                Stroke("Bar1", Line(new Vector2(-0.16f, 0.26f), new Vector2(-0.16f, -0.26f)), _width * 1.5f);
                Stroke("Bar2", Line(new Vector2(0.16f, 0.26f), new Vector2(0.16f, -0.26f)), _width * 1.5f);
            }
        }

        private void Snowflake()
        {
            for (int i = 0; i < 6; i++)
            {
                float a = i * 60f * Mathf.Deg2Rad;
                var dir = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                Vector2 tip = dir * 0.7f;
                Stroke("Spoke" + i, Line(Vector2.zero, tip), _width * 0.9f);
                // two little branches near the tip
                Vector2 mid = dir * 0.46f;
                var perp = new Vector2(-dir.y, dir.x);
                Stroke("BrA" + i, Line(mid, mid + (dir * 0.18f + perp * 0.16f)), _width * 0.75f);
                Stroke("BrB" + i, Line(mid, mid + (dir * 0.18f - perp * 0.16f)), _width * 0.75f);
            }
        }

        private void Sun()
        {
            Stroke("Sun", Circle(new Vector2(0f, 0f), 0.36f, 26));
            for (int i = 0; i < 8; i++)
            {
                float a = i * 45f * Mathf.Deg2Rad;
                var dir = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                Stroke("Ray" + i, Line(dir * 0.48f, dir * 0.72f), _width * 0.9f);
            }
        }

        private void ThirdArmFigure()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.5f), 0.16f));
            Stroke("Body", Line(new Vector2(0f, 0.34f), new Vector2(0f, -0.18f)));
            Stroke("LegL", Line(new Vector2(0f, -0.18f), new Vector2(-0.2f, -0.6f)));
            Stroke("LegR", Line(new Vector2(0f, -0.18f), new Vector2(0.2f, -0.6f)));
            Stroke("ArmL", Line(new Vector2(0f, 0.26f), new Vector2(-0.3f, 0.02f)));
            Stroke("ArmR", Line(new Vector2(0f, 0.26f), new Vector2(0.3f, 0.02f)));
            // the extra arm: straight out from the chest, with a little hand splay
            Stroke("Arm3", Line(new Vector2(0f, 0.12f), new Vector2(0.46f, 0.22f)));
            Stroke("Hand3a", Line(new Vector2(0.46f, 0.22f), new Vector2(0.56f, 0.3f)), _width * 0.8f);
            Stroke("Hand3b", Line(new Vector2(0.46f, 0.22f), new Vector2(0.58f, 0.18f)), _width * 0.8f);
        }

        private void TwoHeadFigure()
        {
            Stroke("Body", Line(new Vector2(0f, 0.32f), new Vector2(0f, -0.18f)));
            Stroke("LegL", Line(new Vector2(0f, -0.18f), new Vector2(-0.2f, -0.6f)));
            Stroke("LegR", Line(new Vector2(0f, -0.18f), new Vector2(0.2f, -0.6f)));
            Stroke("ArmL", Line(new Vector2(0f, 0.24f), new Vector2(-0.3f, 0.0f)));
            Stroke("ArmR", Line(new Vector2(0f, 0.24f), new Vector2(0.3f, 0.0f)));
            // the neck forks to two heads
            Stroke("NeckL", Line(new Vector2(0f, 0.32f), new Vector2(-0.17f, 0.44f)));
            Stroke("NeckR", Line(new Vector2(0f, 0.32f), new Vector2(0.17f, 0.44f)));
            Stroke("HeadL", Circle(new Vector2(-0.19f, 0.58f), 0.14f));
            Stroke("HeadR", Circle(new Vector2(0.19f, 0.58f), 0.14f));
        }

        // ---------- Chapter 3 (the money) doodles ----------

        // Rotate a point about the origin (for the tilted food doodles).
        private static Vector3 Rot(float x, float y, float r)
        {
            float c = Mathf.Cos(r), s = Mathf.Sin(r);
            return new Vector3(x * c - y * s, x * s + y * c, 0f);
        }

        // A small parametric heart centred at c (used by the ending-poverty doodle).
        private static List<Vector3> Heart(Vector2 c, float s)
        {
            var pts = new List<Vector3>();
            int seg = 40;
            for (int i = 0; i <= seg; i++)
            {
                float t = i / (float)seg * Mathf.PI * 2f;
                float x = 16f * Mathf.Pow(Mathf.Sin(t), 3f);
                float y = 13f * Mathf.Cos(t) - 5f * Mathf.Cos(2f * t) - 2f * Mathf.Cos(3f * t) - Mathf.Cos(4f * t);
                pts.Add(new Vector3(c.x + x / 16f * s, c.y + y / 16f * s, 0f));
            }
            return pts;
        }

        // End poverty: a cupped hand offering a little heart (charity / giving).
        private void Poverty()
        {
            var cup = new List<Vector3>();
            InkLine.AddArc(cup, new Vector2(0f, 0.02f), 0.5f, 200f, 340f, 20);
            Stroke("Cup", cup);
            Stroke("FingerL", Line(new Vector2(-0.47f, -0.13f), new Vector2(-0.55f, 0.13f)), _width * 0.85f);
            Stroke("FingerR", Line(new Vector2(0.47f, -0.13f), new Vector2(0.55f, 0.11f)), _width * 0.85f);
            Stroke("Heart", Heart(new Vector2(0f, 0.42f), 0.3f), _width * 0.95f);
        }

        // Free food for life (English): a wrapped burrito.
        private void Burrito()
        {
            float rot = -18f * Mathf.Deg2Rad;
            var body = new List<Vector3>();
            for (int i = 0; i <= 34; i++) { float a = i / 34f * Mathf.PI * 2f; body.Add(Rot(Mathf.Cos(a) * 0.72f, Mathf.Sin(a) * 0.34f, rot)); }
            Stroke("Body", body);
            Stroke("Fold1", new List<Vector3> { Rot(-0.2f, 0.2f, rot), Rot(-0.05f, -0.22f, rot) }, _width * 0.75f);
            Stroke("Fold2", new List<Vector3> { Rot(0.2f, 0.22f, rot), Rot(0.32f, -0.18f, rot) }, _width * 0.75f);
            Stroke("Foil", new List<Vector3> { Rot(0.55f, 0.16f, rot), Rot(0.64f, 0.02f, rot), Rot(0.55f, -0.1f, rot), Rot(0.66f, -0.16f, rot) }, _width * 0.8f);
        }

        // Free food for life (Turkish): a skewer of kebab chunks.
        private void Kebab()
        {
            Vector2 dir = new Vector2(Mathf.Cos(35f * Mathf.Deg2Rad), Mathf.Sin(35f * Mathf.Deg2Rad));
            Vector2 a = -dir * 0.78f, b = dir * 0.86f;
            Stroke("Skewer", Line(a, b), _width * 0.8f);
            float[] ts = { 0.3f, 0.52f, 0.74f };
            for (int i = 0; i < ts.Length; i++)
            {
                Vector2 c = Vector2.Lerp(a, b, ts[i]);
                var chunk = new List<Vector3>();
                for (int j = 0; j <= 14; j++) { float ang = j / 14f * Mathf.PI * 2f; chunk.Add(new Vector3(c.x + Mathf.Cos(ang) * 0.2f, c.y + Mathf.Sin(ang) * 0.17f, 0f)); }
                Stroke("Chunk" + i, chunk, _width * 0.9f);
            }
        }

        // A marginally less bad nose (a nose in profile).
        private void Nose()
        {
            Stroke("Profile", Line(new Vector2(-0.18f, 0.62f), new Vector2(-0.02f, 0.3f), new Vector2(0.34f, -0.06f), new Vector2(0.12f, -0.24f), new Vector2(0.24f, -0.34f), new Vector2(-0.04f, -0.42f)));
            var nostril = new List<Vector3>();
            InkLine.AddArc(nostril, new Vector2(0.06f, -0.28f), 0.09f, -10f, 170f, 10);
            Stroke("Nostril", nostril, _width * 0.8f);
        }

        // One extra year of life: an hourglass.
        private void Hourglass()
        {
            Stroke("TopBar", Line(new Vector2(-0.45f, 0.62f), new Vector2(0.45f, 0.62f)));
            Stroke("BotBar", Line(new Vector2(-0.45f, -0.62f), new Vector2(0.45f, -0.62f)));
            Stroke("SideL", Line(new Vector2(-0.4f, 0.6f), new Vector2(0f, 0f), new Vector2(-0.4f, -0.6f)));
            Stroke("SideR", Line(new Vector2(0.4f, 0.6f), new Vector2(0f, 0f), new Vector2(0.4f, -0.6f)));
            Stroke("Sand", Line(new Vector2(-0.26f, -0.6f), new Vector2(0f, -0.28f), new Vector2(0.26f, -0.6f)), _width * 0.8f);
            Stroke("Grain", Line(new Vector2(0f, 0.05f), new Vector2(0f, -0.16f)), _width * 0.7f);
        }

        // The cigarette auction: a pack with a few cigarettes.
        private void CigarettePack()
        {
            Stroke("Box", Line(new Vector2(-0.36f, 0.15f), new Vector2(-0.36f, -0.6f), new Vector2(0.36f, -0.6f), new Vector2(0.36f, 0.15f)));
            Stroke("Lid", Line(new Vector2(-0.36f, 0.15f), new Vector2(-0.2f, 0.42f), new Vector2(0.5f, 0.42f), new Vector2(0.36f, 0.15f)), _width * 0.85f);
            Stroke("Band", Line(new Vector2(-0.36f, -0.25f), new Vector2(0.36f, -0.25f)), _width * 0.7f);
            for (int i = 0; i < 3; i++)
            {
                float x = -0.18f + i * 0.18f;
                Stroke("Cig" + i, Line(new Vector2(x, 0.15f), new Vector2(x, 0.5f)), _width * 0.9f);
                Stroke("Tip" + i, Line(new Vector2(x - 0.06f, 0.5f), new Vector2(x + 0.06f, 0.5f)), _width * 1.1f);
            }
        }

        // No more pain: a plaster / bandage.
        private void Bandage()
        {
            float rot = 28f * Mathf.Deg2Rad;
            var body = new List<Vector3>();
            for (int i = 0; i <= 30; i++) { float a = i / 30f * Mathf.PI * 2f; body.Add(Rot(Mathf.Cos(a) * 0.66f, Mathf.Sin(a) * 0.26f, rot)); }
            Stroke("Body", body);
            var pad = new List<Vector3> { Rot(-0.18f, 0.15f, rot), Rot(0.18f, 0.15f, rot), Rot(0.18f, -0.15f, rot), Rot(-0.18f, -0.15f, rot), Rot(-0.18f, 0.15f, rot) };
            Stroke("Pad", pad, _width * 0.75f);
            Stroke("H1", new List<Vector3> { Rot(-0.5f, 0.08f, rot), Rot(-0.34f, 0.08f, rot) }, _width * 0.6f);
            Stroke("H2", new List<Vector3> { Rot(-0.5f, -0.06f, rot), Rot(-0.34f, -0.06f, rot) }, _width * 0.6f);
            Stroke("H3", new List<Vector3> { Rot(0.34f, 0.08f, rot), Rot(0.5f, 0.08f, rot) }, _width * 0.6f);
            Stroke("H4", new List<Vector3> { Rot(0.34f, -0.06f, rot), Rot(0.5f, -0.06f, rot) }, _width * 0.6f);
        }

        // The deleted memory: a thought cloud with a scribble drifting inside.
        private void MemoryCloud()
        {
            var cloud = new List<Vector3>();
            for (int i = 0; i <= 48; i++) { float a = i / 48f * Mathf.PI * 2f; float r = 0.52f + 0.08f * Mathf.Sin(a * 6f); cloud.Add(new Vector3(Mathf.Cos(a) * r, 0.18f + Mathf.Sin(a) * r * 0.72f, 0f)); }
            Stroke("Cloud", cloud);
            Stroke("Bub1", Circle(new Vector2(-0.28f, -0.45f), 0.1f, 12), _width * 0.85f);
            Stroke("Bub2", Circle(new Vector2(-0.5f, -0.66f), 0.06f, 10), _width * 0.8f);
            var sp = new List<Vector3>();
            for (int i = 0; i <= 40; i++) { float t = i / 40f; float ang = t * Mathf.PI * 4f; float r = 0.24f * (1f - t); sp.Add(new Vector3(Mathf.Cos(ang) * r, 0.2f + Mathf.Sin(ang) * r, 0f)); }
            Stroke("Scribble", sp, _width * 0.8f);
        }

        // Bulk (ten years of a stranger's life): a small stranger beside a clock.
        private void StolenYears()
        {
            Stroke("Head", Circle(new Vector2(-0.42f, 0.42f), 0.13f, 16));
            Stroke("Body", Line(new Vector2(-0.42f, 0.29f), new Vector2(-0.42f, -0.12f)));
            Stroke("LegL", Line(new Vector2(-0.42f, -0.12f), new Vector2(-0.56f, -0.48f)));
            Stroke("LegR", Line(new Vector2(-0.42f, -0.12f), new Vector2(-0.28f, -0.48f)));
            Stroke("ArmL", Line(new Vector2(-0.42f, 0.18f), new Vector2(-0.6f, -0.02f)));
            Stroke("ArmR", Line(new Vector2(-0.42f, 0.18f), new Vector2(-0.24f, -0.02f)));
            Stroke("Clock", Circle(new Vector2(0.32f, 0.1f), 0.34f, 26));
            Stroke("HandH", Line(new Vector2(0.32f, 0.1f), new Vector2(0.32f, 0.34f)), _width * 0.9f);
            Stroke("HandM", Line(new Vector2(0.32f, 0.1f), new Vector2(0.52f, 0.1f)), _width * 0.9f);
            for (int i = 0; i < 12; i++) { float a = i * 30f * Mathf.Deg2Rad; var d = new Vector2(Mathf.Cos(a), Mathf.Sin(a)); Stroke("Tk" + i, Line(new Vector2(0.32f, 0.1f) + d * 0.3f, new Vector2(0.32f, 0.1f) + d * 0.34f), _width * 0.5f); }
        }

        // The cheap forgetting: a head with the memory drifting off and fading.
        private void Forgetting()
        {
            Stroke("Head", Circle(new Vector2(-0.1f, 0f), 0.44f, 28));
            Stroke("EyeL", Circle(new Vector2(-0.26f, 0.08f), 0.04f, 8), _width * 0.8f);
            Stroke("EyeR", Circle(new Vector2(0.02f, 0.08f), 0.04f, 8), _width * 0.8f);
            Stroke("Mouth", Line(new Vector2(-0.24f, -0.16f), new Vector2(0f, -0.16f)), _width * 0.8f);
            var wisp = new List<Vector3>();
            for (int i = 0; i <= 24; i++) { float t = i / 24f; float ang = t * Mathf.PI * 3f; wisp.Add(new Vector3(0.3f + t * 0.42f, 0.4f + t * 0.35f + Mathf.Sin(ang) * 0.06f, 0f)); }
            Stroke("Wisp", wisp, _width * 0.75f);
            Stroke("Puff1", Circle(new Vector2(0.72f, 0.78f), 0.06f, 10), _width * 0.65f);
            Stroke("Puff2", Circle(new Vector2(0.84f, 0.9f), 0.04f, 8), _width * 0.6f);
        }

        // The truth about how you died: a headstone with a question mark (kept light).
        private void Tombstone()
        {
            var stone = new List<Vector3> { new Vector3(-0.4f, -0.62f, 0f), new Vector3(-0.4f, 0.2f, 0f) };
            var arch = new List<Vector3>();
            InkLine.AddArc(arch, new Vector2(0f, 0.2f), 0.4f, 0f, 180f, 16);
            stone.AddRange(arch);
            stone.Add(new Vector3(0.4f, -0.62f, 0f));
            Stroke("Stone", stone);
            Stroke("Ground", Line(new Vector2(-0.66f, -0.62f), new Vector2(0.66f, -0.62f)), _width * 0.85f);
            var q = new List<Vector3>();
            InkLine.AddArc(q, new Vector2(0f, 0.3f), 0.15f, 200f, -30f, 16);
            q.Add(new Vector3(0f, 0.05f, 0f));
            Stroke("QCurve", q, _width * 0.9f);
            Stroke("QDot", Circle(new Vector2(0f, -0.14f), 0.03f, 8), _width);
        }

        // Cash-out menu: a coin with a dollar sign.
        private void Coin()
        {
            Stroke("Rim", Circle(new Vector2(0f, 0f), 0.5f, 30));
            Stroke("Inner", Circle(new Vector2(0f, 0f), 0.4f, 28), _width * 0.7f);
            Stroke("S", Line(new Vector2(0.16f, 0.24f), new Vector2(-0.02f, 0.28f), new Vector2(-0.14f, 0.14f), new Vector2(0.06f, 0.02f), new Vector2(0.14f, -0.12f), new Vector2(-0.04f, -0.26f), new Vector2(-0.18f, -0.2f)), _width * 0.9f);
            Stroke("Bar", Line(new Vector2(0f, 0.34f), new Vector2(0f, -0.32f)), _width * 0.8f);
        }

        // Cash-out menu: a star (something meaningful).
        private void Star()
        {
            var pts = new List<Vector3>();
            for (int i = 0; i <= 10; i++) { float a = Mathf.PI / 2f + i * Mathf.PI / 5f; float r = (i % 2 == 0) ? 0.6f : 0.26f; pts.Add(new Vector3(Mathf.Cos(a) * r, Mathf.Sin(a) * r, 0f)); }
            Stroke("Star", pts);
        }

        // Cash-out menu: a wrapped sweet (cheap junk).
        private void Candy()
        {
            Stroke("Body", Circle(new Vector2(0f, 0f), 0.32f, 20));
            Stroke("EndL", Line(new Vector2(-0.3f, 0.1f), new Vector2(-0.6f, 0.22f), new Vector2(-0.56f, -0.02f), new Vector2(-0.6f, -0.22f), new Vector2(-0.3f, -0.1f)), _width * 0.8f);
            Stroke("EndR", Line(new Vector2(0.3f, 0.1f), new Vector2(0.6f, 0.22f), new Vector2(0.56f, -0.02f), new Vector2(0.6f, -0.22f), new Vector2(0.3f, -0.1f)), _width * 0.8f);
            Stroke("Swirl", Line(new Vector2(-0.12f, 0.12f), new Vector2(0.12f, -0.12f)), _width * 0.7f);
        }

        // ---------- Chapter 3 rework: the ten double-edged items, the cucumber, the question mark ----------

        // Charisma: a figure with a halo of little rays, so it reads as magnetic / instantly adored.
        private void Charisma()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.28f), 0.15f));
            Stroke("Body", Line(new Vector2(0f, 0.13f), new Vector2(0f, -0.28f)));
            Stroke("ArmL", Line(new Vector2(0f, 0.04f), new Vector2(-0.24f, -0.1f)));
            Stroke("ArmR", Line(new Vector2(0f, 0.04f), new Vector2(0.24f, -0.1f)));
            Stroke("LegL", Line(new Vector2(0f, -0.28f), new Vector2(-0.18f, -0.62f)));
            Stroke("LegR", Line(new Vector2(0f, -0.28f), new Vector2(0.18f, -0.62f)));
            Vector2 c = new Vector2(0f, 0.28f);
            for (int i = 0; i < 10; i++)
            {
                float a = i * 36f * Mathf.Deg2Rad;
                var d = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                Stroke("Ray" + i, Line(c + d * 0.24f, c + d * 0.4f), _width * 0.7f);
            }
        }

        // The Off Switch: a head with a small toggle switch, the knob to the off side.
        private void OffSwitch()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.06f), 0.46f));
            var pill = new List<Vector3>();
            for (int i = 0; i <= 24; i++) { float a = i / 24f * Mathf.PI * 2f; pill.Add(new Vector3(Mathf.Cos(a) * 0.24f, -0.02f + Mathf.Sin(a) * 0.13f, 0f)); }
            Stroke("Pill", pill, _width * 0.8f);
            Stroke("Knob", Circle(new Vector2(-0.11f, -0.02f), 0.09f, 12), _width * 0.9f);
        }

        // Perfect Memory: a head etched with sharp, hard lines (nothing ever softens or fades).
        private void PerfectMemory()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.02f), 0.46f));
            Stroke("L1", Line(new Vector2(-0.26f, 0.24f), new Vector2(0.24f, 0.24f)), _width * 0.7f);
            Stroke("L2", Line(new Vector2(-0.28f, 0.06f), new Vector2(0.26f, 0.06f)), _width * 0.7f);
            Stroke("L3", Line(new Vector2(-0.26f, -0.12f), new Vector2(0.24f, -0.12f)), _width * 0.7f);
            Stroke("L4", Line(new Vector2(-0.2f, -0.3f), new Vector2(0.18f, -0.3f)), _width * 0.7f);
        }

        // The Lie Detector: an open eye that always sees the truth.
        private void LieDetector()
        {
            var top = new List<Vector3>(); InkLine.AddArc(top, new Vector2(0f, -0.1f), 0.55f, 20f, 160f, 20); Stroke("Lid", top);
            var bot = new List<Vector3>(); InkLine.AddArc(bot, new Vector2(0f, 0.34f), 0.55f, 200f, 340f, 20); Stroke("Under", bot);
            Stroke("Iris", Circle(new Vector2(0f, 0.06f), 0.17f, 20));
            Stroke("Pupil", Circle(new Vector2(0f, 0.06f), 0.06f, 12), _width * 1.1f);
        }

        // Rewind (once ever): a bold curved arrow sweeping back on itself.
        private void Rewind()
        {
            var arc = new List<Vector3>();
            InkLine.AddArc(arc, Vector2.zero, 0.46f, 300f, 490f, 26); // lower-right, up over the top, to upper-left
            Stroke("Arc", arc);
            Vector2 end = arc[arc.Count - 1];
            Stroke("Ah1", Line(end, end + new Vector2(0.06f, 0.2f)), _width * 0.9f);
            Stroke("Ah2", Line(end, end + new Vector2(-0.18f, 0.08f)), _width * 0.9f);
        }

        // Ten more IQ: a head with a small up-arrow rising from it.
        private void IqUp()
        {
            Stroke("Head", Circle(new Vector2(0f, -0.06f), 0.44f));
            Stroke("Shaft", Line(new Vector2(0f, 0.42f), new Vector2(0f, 0.86f)), _width * 0.95f);
            Stroke("Ah1", Line(new Vector2(0f, 0.86f), new Vector2(-0.14f, 0.68f)), _width * 0.95f);
            Stroke("Ah2", Line(new Vector2(0f, 0.86f), new Vector2(0.14f, 0.68f)), _width * 0.95f);
        }

        // Never Tired: a wide open eye and a crossed-out z (no sleep, ever).
        private void NeverTired()
        {
            var top = new List<Vector3>(); InkLine.AddArc(top, new Vector2(-0.2f, -0.28f), 0.44f, 25f, 155f, 16); Stroke("Lid", top);
            var bot = new List<Vector3>(); InkLine.AddArc(bot, new Vector2(-0.2f, 0.12f), 0.44f, 205f, 335f, 16); Stroke("Under", bot);
            Stroke("Iris", Circle(new Vector2(-0.2f, -0.08f), 0.12f, 16));
            Stroke("Pupil", Circle(new Vector2(-0.2f, -0.08f), 0.045f, 8), _width * 1.1f);
            Stroke("Z", Line(new Vector2(0.28f, 0.62f), new Vector2(0.6f, 0.62f), new Vector2(0.28f, 0.34f), new Vector2(0.6f, 0.34f)), _width * 0.9f);
            Stroke("Slash", Line(new Vector2(0.24f, 0.34f), new Vector2(0.64f, 0.66f)), _width * 0.85f);
        }

        // The Good Luck: a four-leaf clover with a curling stem.
        private void Clover()
        {
            Vector2 c = new Vector2(0f, 0.12f);
            float[] ang = { 45f, 135f, 225f, 315f };
            for (int i = 0; i < 4; i++)
            {
                float a = ang[i] * Mathf.Deg2Rad;
                Vector2 lc = c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 0.26f;
                var leaf = new List<Vector3>();
                for (int j = 0; j <= 18; j++) { float t = j / 18f * Mathf.PI * 2f; leaf.Add(new Vector3(lc.x + Mathf.Cos(t) * 0.2f, lc.y + Mathf.Sin(t) * 0.24f, 0f)); }
                Stroke("Leaf" + i, leaf, _width * 0.85f);
            }
            Stroke("Stem", Line(c, new Vector2(0.06f, -0.4f), new Vector2(-0.02f, -0.62f)), _width * 0.85f);
        }

        // Feel Nothing: a blank face with a dead flat mouth (no grief, no joy).
        private void FeelNothing()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.04f), 0.46f));
            Stroke("EyeL", Line(new Vector2(-0.24f, 0.14f), new Vector2(-0.1f, 0.14f)), _width * 0.9f);
            Stroke("EyeR", Line(new Vector2(0.1f, 0.14f), new Vector2(0.24f, 0.14f)), _width * 0.9f);
            Stroke("Mouth", Line(new Vector2(-0.24f, -0.18f), new Vector2(0.24f, -0.18f)), _width * 0.95f);
        }

        // One More Voice: a head with a little speech bubble and a whisper curl beside it.
        private void InnerVoice()
        {
            Stroke("Head", Circle(new Vector2(-0.14f, -0.02f), 0.42f));
            Stroke("EyeL", Circle(new Vector2(-0.26f, 0.04f), 0.035f, 8), _width * 0.8f);
            Stroke("EyeR", Circle(new Vector2(-0.02f, 0.04f), 0.035f, 8), _width * 0.8f);
            var bub = new List<Vector3>(); InkLine.AddArc(bub, new Vector2(0.42f, 0.4f), 0.24f, 0f, 360f, 18); Stroke("Bubble", bub, _width * 0.85f);
            Stroke("Tail", Line(new Vector2(0.28f, 0.24f), new Vector2(0.16f, 0.06f)), _width * 0.8f);
            var curl = new List<Vector3>();
            for (int i = 0; i <= 20; i++) { float t = i / 20f; float ang = t * Mathf.PI * 2.4f; float r = 0.12f * (1f - t * 0.5f); curl.Add(new Vector3(0.42f + Mathf.Cos(ang) * r, 0.4f + Mathf.Sin(ang) * r, 0f)); }
            Stroke("Curl", curl, _width * 0.7f);
        }

        // The 100 dollar cucumber (the deadpan finale): a simple cucumber, exactly what it looks like.
        private void Cucumber()
        {
            float rot = 18f * Mathf.Deg2Rad;
            var body = new List<Vector3>();
            int seg = 40;
            for (int i = 0; i <= seg; i++)
            {
                float t = i / (float)seg * Mathf.PI * 2f;
                float x = Mathf.Cos(t) * 0.28f;
                float y = Mathf.Sin(t) * 0.66f;
                x += Mathf.Sin(y * 1.4f) * 0.08f; // a gentle curve
                body.Add(Rot(x, y, rot));
            }
            Stroke("Body", body);
            Stroke("D1", new List<Vector3> { Rot(-0.02f, 0.28f, rot), Rot(0.06f, 0.24f, rot) }, _width * 0.6f);
            Stroke("D2", new List<Vector3> { Rot(-0.06f, 0.02f, rot), Rot(0.03f, -0.02f, rot) }, _width * 0.6f);
            Stroke("D3", new List<Vector3> { Rot(-0.02f, -0.26f, rot), Rot(0.07f, -0.3f, rot) }, _width * 0.6f);
            Stroke("Nub", new List<Vector3> { Rot(0.0f, 0.66f, rot), Rot(0.0f, 0.78f, rot) }, _width * 0.8f);
        }

        // The truth about how you died (reworked visual): a plain ink question mark, nothing else.
        private void QuestionMark()
        {
            var q = new List<Vector3>();
            InkLine.AddArc(q, new Vector2(0f, 0.34f), 0.3f, 200f, -40f, 24);
            q.Add(new Vector3(0.18f, 0.12f, 0f));
            q.Add(new Vector3(0f, -0.02f, 0f));
            q.Add(new Vector3(0f, -0.22f, 0f));
            Stroke("Hook", q, _width * 1.1f);
            Stroke("Dot", Circle(new Vector2(0f, -0.5f), 0.06f, 10), _width * 1.2f);
        }

        // ---------- fade ----------

        public void SetAlpha(float a)
        {
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _color, Mathf.Clamp01(a));
        }

        public IEnumerator FadeIn(float dur) { yield return Fade(0f, 1f, dur); }
        public IEnumerator FadeOut(float dur) { yield return Fade(1f, 0f, dur); }

        private IEnumerator Fade(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; SetAlpha(Mathf.Lerp(from, to, t / d)); yield return null; }
            SetAlpha(to);
        }
    }
}
