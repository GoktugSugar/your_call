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
        private readonly List<Color> _strokeColors = new List<Color>();
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

                // Chapter 3 would-you-rather breathers.
                case DoodleKind.Cat: return Palette.InkPurple;        // the talking cat
                case DoodleKind.Dog: return Palette.InkBrown;         // the talking dog
                case DoodleKind.Shirt: return Palette.InkBlue;        // fabric
                case DoodleKind.Shoe: return Palette.InkOrange;       // a shoe
                case DoodleKind.Wallet: return Palette.InkGreen;      // cash
                case DoodleKind.MoneyBag: return Palette.InkGold;     // money

                // Chapter 4 would-you-rather breathers.
                case DoodleKind.Dragon: return Palette.InkPurple;     // a fantastical pet
                case DoodleKind.Dinosaur: return Palette.InkGreen;    // a big reptile
                case DoodleKind.House: return Palette.InkOrange;      // a warm home
                case DoodleKind.Car: return Palette.InkBlue;          // a car
                case DoodleKind.Robot: return Palette.InkSky;         // cool metal
                case DoodleKind.Ghost: return Palette.InkPurple;      // spectral

                // Chapter 5 (Who Would Win) fighters: each matchup passes an explicit per-side colour so the
                // two read apart (see MatchupBeat), so these are just sensible fallbacks.
                case DoodleKind.Brawler: return Palette.Ink;          // a person; the side data recolours it
                case DoodleKind.Gorilla: return Palette.Muted;        // a silverback, silver-grey
                case DoodleKind.GorillaKnife: return Palette.Muted;   // the same silverback (the knife is red)
                case DoodleKind.Chicken: return Palette.InkOrange;    // a hen
                case DoodleKind.Lion: return Palette.InkOrange;       // a warm mane
                case DoodleKind.HouseCat: return Palette.InkSky;      // a cat
                case DoodleKind.Toddler: return Palette.InkOrange;    // little ones
                case DoodleKind.Wasp: return Palette.InkOrange;       // yellow-black, warm
                case DoodleKind.Grizzly: return Palette.InkBrown;     // a brown bear
                case DoodleKind.Boxer: return Palette.InkRed;         // a fighter, aggressive

                // Chapter 8 (The Campaign): the class doodles, reasons, and props (each matchup / menu passes an
                // explicit colour, so these are sensible fallbacks).
                case DoodleKind.Knight: return Palette.InkBlue;       // steel
                case DoodleKind.Rogue: return Palette.InkGreen;       // leather / poison
                case DoodleKind.Wizard: return Palette.InkPurple;     // arcane
                case DoodleKind.Bard: return Palette.InkOrange;       // warm song
                case DoodleKind.Cleric: return Palette.InkGold;       // holy
                case DoodleKind.Coins: return Palette.InkGold;        // gold
                case DoodleKind.Trophy: return Palette.InkOrange;     // glory
                case DoodleKind.QuestHeart: return Palette.InkPink;   // love / rescue
                case DoodleKind.Signpost: return Palette.Muted;       // a plain post
                case DoodleKind.Companion: return Palette.InkPurple;  // the hooded stranger
                case DoodleKind.TreasureChest: return Palette.InkGold;// the hoard

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

                // Chapter 3 would-you-rather breather doodles.
                case DoodleKind.Cat: Cat(); break;
                case DoodleKind.Dog: Dog(); break;
                case DoodleKind.Shirt: Shirt(); break;
                case DoodleKind.Shoe: Shoe(); break;
                case DoodleKind.Wallet: Wallet(); break;
                case DoodleKind.MoneyBag: MoneyBag(); break;

                // Chapter 4 would-you-rather breather doodles.
                case DoodleKind.Dragon: Dragon(); break;
                case DoodleKind.Dinosaur: Dinosaur(); break;
                case DoodleKind.House: House(); break;
                case DoodleKind.Car: Car(); break;
                case DoodleKind.Robot: Robot(); break;
                case DoodleKind.Ghost: Ghost(); break;

                // Chapter 5 (Who Would Win) fighter doodles.
                case DoodleKind.Brawler: Brawler(); break;
                case DoodleKind.Gorilla: Gorilla(false); break;
                case DoodleKind.GorillaKnife: Gorilla(true); break;
                case DoodleKind.Chicken: Chicken(); break;
                case DoodleKind.Lion: Lion(); break;
                case DoodleKind.HouseCat: HouseCat(); break;
                case DoodleKind.Toddler: Toddler(); break;
                case DoodleKind.Wasp: Wasp(); break;
                case DoodleKind.Grizzly: Grizzly(); break;
                case DoodleKind.Boxer: Boxer(); break;

                // Chapter 8 (The Campaign) doodles.
                case DoodleKind.Knight: Knight(); break;
                case DoodleKind.Rogue: Rogue(); break;
                case DoodleKind.Wizard: Wizard(); break;
                case DoodleKind.Bard: Bard(); break;
                case DoodleKind.Cleric: Cleric(); break;
                case DoodleKind.Coins: Coins(); break;
                case DoodleKind.Trophy: Trophy(); break;
                case DoodleKind.QuestHeart: QuestHeart(); break;
                case DoodleKind.Signpost: Signpost(); break;
                case DoodleKind.Companion: Companion(); break;
                case DoodleKind.TreasureChest: TreasureChest(); break;
                default: break;
            }
        }

        // ---------- drawing helpers ----------

        private LineRenderer Stroke(string name, List<Vector3> pts, float width = 0f)
            => Stroke(name, pts, width, _color);

        // A stroke in a colour other than the doodle's own (so a single doodle can carry a second colour,
        // e.g. the red knife on the grey knife-gorilla). Its base colour is tracked so it fades correctly.
        private LineRenderer Stroke(string name, List<Vector3> pts, float width, Color color)
        {
            var lr = InkLine.Create(transform, name, _mat, width > 0f ? width : _width, color, _sorting);
            InkLine.SetPoints(lr, pts);
            if (_boil) lr.gameObject.AddComponent<LineBoil>().Capture();
            _strokes.Add(lr);
            _strokeColors.Add(color);
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

        // The cigarette auction: a tidy flip-top pack with a couple of cigarettes peeking out.
        private void CigarettePack()
        {
            float w = 0.36f, top = 0.46f, bot = -0.64f;
            // two cigarettes peeking above the opening, filters showing (thicker tips).
            Stroke("Cig1", Line(new Vector2(-0.12f, top - 0.04f), new Vector2(-0.12f, top + 0.24f)), _width * 0.9f);
            Stroke("Tip1", Line(new Vector2(-0.12f, top + 0.13f), new Vector2(-0.12f, top + 0.24f)), _width * 1.7f);
            Stroke("Cig2", Line(new Vector2(0.12f, top - 0.04f), new Vector2(0.12f, top + 0.16f)), _width * 0.9f);
            Stroke("Tip2", Line(new Vector2(0.12f, top + 0.07f), new Vector2(0.12f, top + 0.16f)), _width * 1.7f);
            // the pack body (a clean rounded rectangle).
            Stroke("Body", Line(new Vector2(-w, top), new Vector2(-w, bot), new Vector2(w, bot), new Vector2(w, top), new Vector2(-w, top)));
            // the flip-top seam near the top, and a brand band across the middle.
            Stroke("Seam", Line(new Vector2(-w, top - 0.18f), new Vector2(w, top - 0.18f)), _width * 0.7f);
            Stroke("Band", Line(new Vector2(-w, -0.16f), new Vector2(w, -0.16f)), _width * 0.75f);
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

        // Charisma: a pair of sunglasses (everyone likes the cool version of you). Nothing else.
        private void Charisma()
        {
            var lensL = new List<Vector3>();
            for (int i = 0; i <= 22; i++) { float a = i / 22f * Mathf.PI * 2f; lensL.Add(new Vector3(-0.34f + Mathf.Cos(a) * 0.28f, Mathf.Sin(a) * 0.22f, 0f)); }
            Stroke("LensL", lensL);
            var lensR = new List<Vector3>();
            for (int i = 0; i <= 22; i++) { float a = i / 22f * Mathf.PI * 2f; lensR.Add(new Vector3(0.34f + Mathf.Cos(a) * 0.28f, Mathf.Sin(a) * 0.22f, 0f)); }
            Stroke("LensR", lensR);
            Stroke("Bridge", Line(new Vector2(-0.08f, 0.14f), new Vector2(0f, 0.19f), new Vector2(0.08f, 0.14f)), _width * 0.85f);
            Stroke("ArmL", Line(new Vector2(-0.6f, 0.14f), new Vector2(-0.82f, 0.22f)), _width * 0.9f);
            Stroke("ArmR", Line(new Vector2(0.6f, 0.14f), new Vector2(0.82f, 0.22f)), _width * 0.9f);
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

        // Ten more IQ: a brain (a bumpy lobed outline with a centre divide and a few folds).
        private void IqUp()
        {
            var outline = new List<Vector3>();
            int seg = 64;
            for (int i = 0; i <= seg; i++)
            {
                float t = i / (float)seg * Mathf.PI * 2f;
                float r = 0.48f + 0.06f * Mathf.Sin(t * 7f);
                outline.Add(new Vector3(Mathf.Cos(t) * r * 1.05f, 0.06f + Mathf.Sin(t) * r * 0.84f, 0f));
            }
            Stroke("Brain", outline);
            Stroke("Divide", Line(new Vector2(0.01f, 0.5f), new Vector2(0.04f, 0.12f), new Vector2(-0.02f, -0.28f)), _width * 0.75f);
            Stroke("Fold1", Line(new Vector2(-0.32f, 0.28f), new Vector2(-0.17f, 0.33f), new Vector2(-0.27f, 0.13f), new Vector2(-0.11f, 0.1f)), _width * 0.6f);
            Stroke("Fold2", Line(new Vector2(0.32f, 0.28f), new Vector2(0.17f, 0.33f), new Vector2(0.27f, 0.13f), new Vector2(0.11f, 0.1f)), _width * 0.6f);
            Stroke("Fold3", Line(new Vector2(-0.28f, -0.14f), new Vector2(-0.13f, -0.1f), new Vector2(-0.22f, -0.28f)), _width * 0.6f);
            Stroke("Fold4", Line(new Vector2(0.28f, -0.14f), new Vector2(0.13f, -0.1f), new Vector2(0.22f, -0.28f)), _width * 0.6f);
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

        // ---------- Chapter 3 would-you-rather breather doodles ----------

        // The insulting cat: just a front-facing cat HEAD, pointy ears and wide whiskers. Head only,
        // enlarged to fill the doodle box so it reads at the would-you-rather option size.
        private void Cat()
        {
            Stroke("Head", Circle(new Vector2(0f, -0.02f), 0.5f));
            Stroke("EarL", Line(new Vector2(-0.36f, 0.28f), new Vector2(-0.5f, 0.78f), new Vector2(-0.08f, 0.42f)));
            Stroke("EarR", Line(new Vector2(0.36f, 0.28f), new Vector2(0.5f, 0.78f), new Vector2(0.08f, 0.42f)));
            Stroke("EyeL", Circle(new Vector2(-0.19f, 0.06f), 0.05f, 10), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.19f, 0.06f), 0.05f, 10), _width * 0.9f);
            Stroke("Nose", Line(new Vector2(-0.05f, -0.12f), new Vector2(0.05f, -0.12f), new Vector2(0f, -0.2f), new Vector2(-0.05f, -0.12f)), _width * 0.8f);
            Stroke("MouthL", Line(new Vector2(0f, -0.2f), new Vector2(0f, -0.28f), new Vector2(-0.11f, -0.22f)), _width * 0.7f);
            Stroke("MouthR", Line(new Vector2(0f, -0.28f), new Vector2(0.11f, -0.22f)), _width * 0.7f);
            Stroke("WhL1", Line(new Vector2(-0.2f, -0.08f), new Vector2(-0.72f, -0.02f)), _width * 0.5f);
            Stroke("WhL2", Line(new Vector2(-0.2f, -0.16f), new Vector2(-0.72f, -0.2f)), _width * 0.5f);
            Stroke("WhR1", Line(new Vector2(0.2f, -0.08f), new Vector2(0.72f, -0.02f)), _width * 0.5f);
            Stroke("WhR2", Line(new Vector2(0.2f, -0.16f), new Vector2(0.72f, -0.2f)), _width * 0.5f);
        }

        // The lying dog: just a front-facing dog HEAD, floppy ears down the sides, a muzzle and a
        // big nose. Head only, enlarged to fill the box; floppy ears and muzzle set it apart from the cat.
        private void Dog()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.12f), 0.42f));
            Stroke("EarL", Line(new Vector2(-0.34f, 0.4f), new Vector2(-0.66f, 0.16f), new Vector2(-0.6f, -0.28f), new Vector2(-0.34f, -0.04f)), _width * 0.9f);
            Stroke("EarR", Line(new Vector2(0.34f, 0.4f), new Vector2(0.66f, 0.16f), new Vector2(0.6f, -0.28f), new Vector2(0.34f, -0.04f)), _width * 0.9f);
            Stroke("EyeL", Circle(new Vector2(-0.16f, 0.2f), 0.05f, 10), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.16f, 0.2f), 0.05f, 10), _width * 0.9f);
            Stroke("Muzzle", Circle(new Vector2(0f, -0.26f), 0.24f));
            Stroke("Nose", Circle(new Vector2(0f, -0.14f), 0.07f, 12), _width * 1.3f);
            Stroke("MouthV", Line(new Vector2(0f, -0.21f), new Vector2(0f, -0.36f)), _width * 0.7f);
            Stroke("MouthL", Line(new Vector2(0f, -0.36f), new Vector2(-0.14f, -0.42f)), _width * 0.7f);
            Stroke("MouthR", Line(new Vector2(0f, -0.36f), new Vector2(0.14f, -0.42f)), _width * 0.7f);
        }

        // The never-staining shirt: a T-shirt outline with a collar.
        private void Shirt()
        {
            Stroke("Body", Line(
                new Vector2(-0.28f, 0.5f), new Vector2(-0.5f, 0.4f), new Vector2(-0.66f, 0.18f),
                new Vector2(-0.5f, 0.02f), new Vector2(-0.42f, 0.12f), new Vector2(-0.42f, -0.6f),
                new Vector2(0.42f, -0.6f), new Vector2(0.42f, 0.12f), new Vector2(0.5f, 0.02f),
                new Vector2(0.66f, 0.18f), new Vector2(0.5f, 0.4f), new Vector2(0.28f, 0.5f)));
            var collar = new List<Vector3>();
            InkLine.AddArc(collar, new Vector2(0f, 0.5f), 0.28f, 200f, 340f, 14);
            Stroke("Collar", collar, _width * 0.85f);
        }

        // The never-hurting shoes: a side-profile sneaker.
        private void Shoe()
        {
            Stroke("Sole", Line(new Vector2(-0.7f, -0.4f), new Vector2(0.6f, -0.4f), new Vector2(0.72f, -0.26f)));
            Stroke("Upper", Line(new Vector2(-0.7f, -0.4f), new Vector2(-0.68f, -0.02f), new Vector2(-0.3f, 0.14f), new Vector2(0.1f, 0.12f), new Vector2(0.4f, -0.04f), new Vector2(0.72f, -0.26f)));
            Stroke("Ankle", Line(new Vector2(-0.68f, -0.02f), new Vector2(-0.46f, 0.06f)), _width * 0.8f);
            Stroke("Lace1", Line(new Vector2(-0.28f, 0.12f), new Vector2(-0.14f, 0f)), _width * 0.7f);
            Stroke("Lace2", Line(new Vector2(-0.12f, 0.1f), new Vector2(0.02f, -0.02f)), _width * 0.7f);
            Stroke("Lace3", Line(new Vector2(0.04f, 0.08f), new Vector2(0.18f, -0.04f)), _width * 0.7f);
        }

        // The endless 20: a bifold wallet with a note poking out the top.
        private void Wallet()
        {
            Stroke("Note", Line(new Vector2(-0.2f, 0.32f), new Vector2(-0.2f, 0.5f), new Vector2(0.28f, 0.5f), new Vector2(0.28f, 0.32f)), _width * 0.8f);
            Stroke("NoteMark", Line(new Vector2(-0.06f, 0.44f), new Vector2(0.14f, 0.44f)), _width * 0.7f);
            Stroke("Body", Line(new Vector2(-0.5f, 0.34f), new Vector2(-0.5f, -0.36f), new Vector2(0.5f, -0.36f), new Vector2(0.5f, 0.34f), new Vector2(-0.5f, 0.34f)));
            Stroke("Fold", Line(new Vector2(-0.5f, 0f), new Vector2(0.5f, 0f)), _width * 0.7f);
            Stroke("Clasp", Line(new Vector2(0.36f, -0.06f), new Vector2(0.36f, 0.06f)), _width * 0.9f);
        }

        // One big win: a cinched money sack with a dollar sign.
        private void MoneyBag()
        {
            var sack = new List<Vector3>();
            for (int i = 0; i <= 34; i++) { float a = i / 34f * Mathf.PI * 2f; float r = 0.48f + 0.04f * Mathf.Sin(a * 3f); sack.Add(new Vector3(Mathf.Cos(a) * r, -0.12f + Mathf.Sin(a) * r * 0.9f, 0f)); }
            Stroke("Sack", sack);
            Stroke("NeckL", Line(new Vector2(-0.22f, 0.34f), new Vector2(-0.3f, 0.56f), new Vector2(-0.08f, 0.5f)), _width * 0.85f);
            Stroke("NeckR", Line(new Vector2(0.22f, 0.34f), new Vector2(0.3f, 0.56f), new Vector2(0.08f, 0.5f)), _width * 0.85f);
            Stroke("Tie", Line(new Vector2(-0.22f, 0.34f), new Vector2(0.22f, 0.34f)), _width * 0.8f);
            Stroke("S", Line(new Vector2(0.14f, 0.02f), new Vector2(-0.04f, 0.06f), new Vector2(-0.12f, -0.06f), new Vector2(0.08f, -0.14f), new Vector2(0.12f, -0.26f), new Vector2(-0.06f, -0.3f)), _width * 0.85f);
            Stroke("SBar", Line(new Vector2(0f, 0.1f), new Vector2(0f, -0.34f)), _width * 0.75f);
        }

        // ---------- Chapter 4 would-you-rather breather doodles ----------

        // A pet dragon the size of a cat: a rounded body, an up neck to a wedge head, a bat wing, a curling
        // arrow tail, two little legs. Facing right.
        private void Dragon()
        {
            var body = new List<Vector3>();
            for (int i = 0; i <= 24; i++) { float a = i / 24f * Mathf.PI * 2f; body.Add(new Vector3(-0.05f + Mathf.Cos(a) * 0.36f, -0.14f + Mathf.Sin(a) * 0.26f, 0f)); }
            Stroke("Body", body);
            Stroke("Neck", Line(new Vector2(0.26f, 0f), new Vector2(0.44f, 0.36f)));
            Stroke("Head", Line(new Vector2(0.44f, 0.36f), new Vector2(0.66f, 0.44f), new Vector2(0.6f, 0.3f), new Vector2(0.42f, 0.3f)), _width * 0.9f);
            Stroke("Wing", Line(new Vector2(0f, 0.1f), new Vector2(-0.06f, 0.62f), new Vector2(0.1f, 0.42f), new Vector2(0.16f, 0.64f), new Vector2(0.26f, 0.34f)), _width * 0.9f);
            Stroke("Tail", Line(new Vector2(-0.4f, -0.1f), new Vector2(-0.66f, 0.06f), new Vector2(-0.82f, -0.14f)), _width * 0.85f);
            Stroke("TailTip", Line(new Vector2(-0.82f, -0.14f), new Vector2(-0.94f, -0.02f), new Vector2(-0.88f, -0.24f), new Vector2(-0.82f, -0.14f)), _width * 0.8f);
            Stroke("LegF", Line(new Vector2(0.12f, -0.36f), new Vector2(0.14f, -0.56f)), _width * 0.85f);
            Stroke("LegB", Line(new Vector2(-0.16f, -0.36f), new Vector2(-0.18f, -0.56f)), _width * 0.85f);
        }

        // A pet dinosaur the size of a dog: a long-necked sauropod, a big body, four stumpy legs, a long tail.
        private void Dinosaur()
        {
            var body = new List<Vector3>();
            for (int i = 0; i <= 26; i++) { float a = i / 26f * Mathf.PI * 2f; body.Add(new Vector3(-0.05f + Mathf.Cos(a) * 0.42f, -0.16f + Mathf.Sin(a) * 0.26f, 0f)); }
            Stroke("Body", body);
            Stroke("Neck", Line(new Vector2(0.3f, 0.02f), new Vector2(0.46f, 0.4f), new Vector2(0.44f, 0.66f)));
            Stroke("Head", Circle(new Vector2(0.5f, 0.7f), 0.1f, 12), _width * 0.85f);
            Stroke("Tail", Line(new Vector2(-0.44f, -0.08f), new Vector2(-0.72f, -0.04f), new Vector2(-0.95f, -0.24f)), _width * 0.85f);
            Stroke("Leg1", Line(new Vector2(-0.28f, -0.38f), new Vector2(-0.3f, -0.6f)), _width * 0.9f);
            Stroke("Leg2", Line(new Vector2(-0.06f, -0.4f), new Vector2(-0.07f, -0.62f)), _width * 0.9f);
            Stroke("Leg3", Line(new Vector2(0.14f, -0.4f), new Vector2(0.15f, -0.62f)), _width * 0.9f);
            Stroke("Leg4", Line(new Vector2(0.3f, -0.36f), new Vector2(0.32f, -0.58f)), _width * 0.9f);
        }

        // A house that walks: walls, a peaked roof, a door, a window, a chimney, and two little legs.
        private void House()
        {
            Stroke("Walls", Line(new Vector2(-0.5f, -0.4f), new Vector2(-0.5f, 0.2f), new Vector2(0.5f, 0.2f), new Vector2(0.5f, -0.4f), new Vector2(-0.5f, -0.4f)));
            Stroke("Roof", Line(new Vector2(-0.6f, 0.2f), new Vector2(0f, 0.6f), new Vector2(0.6f, 0.2f)));
            Stroke("Door", Line(new Vector2(-0.14f, -0.4f), new Vector2(-0.14f, -0.04f), new Vector2(0.12f, -0.04f), new Vector2(0.12f, -0.4f)), _width * 0.85f);
            Stroke("Window", Line(new Vector2(0.22f, -0.02f), new Vector2(0.22f, 0.12f), new Vector2(0.4f, 0.12f), new Vector2(0.4f, -0.02f), new Vector2(0.22f, -0.02f)), _width * 0.7f);
            Stroke("Chimney", Line(new Vector2(0.28f, 0.4f), new Vector2(0.28f, 0.56f), new Vector2(0.42f, 0.56f), new Vector2(0.42f, 0.32f)), _width * 0.8f);
            Stroke("LegL", Line(new Vector2(-0.24f, -0.4f), new Vector2(-0.28f, -0.62f), new Vector2(-0.16f, -0.62f)), _width * 0.85f);
            Stroke("LegR", Line(new Vector2(0.24f, -0.4f), new Vector2(0.3f, -0.62f), new Vector2(0.42f, -0.62f)), _width * 0.85f);
        }

        // A car that swims: a side-profile car, a cabin bump, two wheels.
        private void Car()
        {
            Stroke("Body", Line(
                new Vector2(-0.66f, -0.18f), new Vector2(-0.66f, -0.02f), new Vector2(-0.4f, -0.02f),
                new Vector2(-0.26f, 0.24f), new Vector2(0.2f, 0.24f), new Vector2(0.34f, -0.02f),
                new Vector2(0.66f, -0.02f), new Vector2(0.66f, -0.18f)));
            Stroke("Pillar", Line(new Vector2(-0.02f, 0.24f), new Vector2(-0.02f, -0.02f)), _width * 0.7f);
            Stroke("WheelL", Circle(new Vector2(-0.38f, -0.28f), 0.16f, 16), _width * 0.9f);
            Stroke("WheelR", Circle(new Vector2(0.4f, -0.28f), 0.16f, 16), _width * 0.9f);
        }

        // A robot butler: a boxy head with an antenna and dot eyes, a body panel, blocky arms and feet.
        private void Robot()
        {
            Stroke("Head", Line(new Vector2(-0.24f, 0.28f), new Vector2(-0.24f, 0.6f), new Vector2(0.24f, 0.6f), new Vector2(0.24f, 0.28f), new Vector2(-0.24f, 0.28f)));
            Stroke("Antenna", Line(new Vector2(0f, 0.6f), new Vector2(0f, 0.76f)), _width * 0.8f);
            Stroke("AntTip", Circle(new Vector2(0f, 0.8f), 0.05f, 10), _width * 0.9f);
            Stroke("EyeL", Circle(new Vector2(-0.1f, 0.46f), 0.05f, 10), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.1f, 0.46f), 0.05f, 10), _width * 0.9f);
            Stroke("Mouth", Line(new Vector2(-0.12f, 0.34f), new Vector2(0.12f, 0.34f)), _width * 0.7f);
            Stroke("Body", Line(new Vector2(-0.3f, -0.34f), new Vector2(-0.3f, 0.24f), new Vector2(0.3f, 0.24f), new Vector2(0.3f, -0.34f), new Vector2(-0.3f, -0.34f)));
            Stroke("Panel", Line(new Vector2(-0.12f, -0.02f), new Vector2(0.12f, -0.02f)), _width * 0.6f);
            Stroke("ArmL", Line(new Vector2(-0.3f, 0.14f), new Vector2(-0.48f, 0.14f), new Vector2(-0.48f, -0.12f)), _width * 0.85f);
            Stroke("ArmR", Line(new Vector2(0.3f, 0.14f), new Vector2(0.48f, 0.14f), new Vector2(0.48f, -0.12f)), _width * 0.85f);
            Stroke("LegL", Line(new Vector2(-0.16f, -0.34f), new Vector2(-0.16f, -0.58f)), _width * 0.9f);
            Stroke("LegR", Line(new Vector2(0.16f, -0.34f), new Vector2(0.16f, -0.58f)), _width * 0.9f);
            Stroke("FootL", Line(new Vector2(-0.26f, -0.58f), new Vector2(-0.06f, -0.58f)), _width * 0.9f);
            Stroke("FootR", Line(new Vector2(0.06f, -0.58f), new Vector2(0.26f, -0.58f)), _width * 0.9f);
        }

        // A ghost flatmate: a domed sheet with a wavy hem, two eyes, a small o mouth.
        private void Ghost()
        {
            var g = new List<Vector3>();
            InkLine.AddArc(g, new Vector2(0f, 0.1f), 0.42f, 0f, 180f, 20);   // right -> top -> left
            g.Add(new Vector3(-0.42f, -0.34f, 0f));                          // down the left side
            g.Add(new Vector3(-0.28f, -0.22f, 0f));                          // wavy hem, left to right
            g.Add(new Vector3(-0.14f, -0.34f, 0f));
            g.Add(new Vector3(0f, -0.22f, 0f));
            g.Add(new Vector3(0.14f, -0.34f, 0f));
            g.Add(new Vector3(0.28f, -0.22f, 0f));
            g.Add(new Vector3(0.42f, -0.34f, 0f));
            g.Add(new Vector3(0.42f, 0.1f, 0f));                             // up the right side, closing
            Stroke("Sheet", g);
            Stroke("EyeL", Circle(new Vector2(-0.14f, 0.12f), 0.07f, 12), _width * 0.85f);
            Stroke("EyeR", Circle(new Vector2(0.14f, 0.12f), 0.07f, 12), _width * 0.85f);
            Stroke("Mouth", Circle(new Vector2(0f, -0.06f), 0.06f, 10), _width * 0.8f);
        }

        // ---------- Chapter 5 (Who Would Win) fighter doodles ----------
        // Polished, stylized, on-model coloured ink fighters, readable at a glance at the side-by-side matchup
        // size and (for the crowd units) still legible drawn small. Each matchup passes a per-side colour so
        // the two contrast (see MatchupBeat). The many-of-something sides are drawn as a cluster of small
        // copies of these units with the count labelled, never the literal count.

        // A person in a fists-up fighting stance: "a man", "you", and the unit for the "N men" crowds.
        private void Brawler()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.6f), 0.17f));
            Stroke("Body", Line(new Vector2(0f, 0.43f), new Vector2(0f, -0.14f)));
            Stroke("LegL", Line(new Vector2(0f, -0.14f), new Vector2(-0.24f, -0.64f)));
            Stroke("LegR", Line(new Vector2(0f, -0.14f), new Vector2(0.24f, -0.64f)));
            // Arms up in a boxing guard, fists by the face.
            Stroke("ArmL", Line(new Vector2(0f, 0.34f), new Vector2(-0.28f, 0.26f), new Vector2(-0.22f, 0.5f)));
            Stroke("ArmR", Line(new Vector2(0f, 0.34f), new Vector2(0.28f, 0.26f), new Vector2(0.22f, 0.5f)));
            Stroke("FistL", Circle(new Vector2(-0.22f, 0.53f), 0.075f, 12), _width * 0.9f);
            Stroke("FistR", Circle(new Vector2(0.22f, 0.53f), 0.075f, 12), _width * 0.9f);
        }

        // A silverback gorilla: a small head with a heavy brow, huge shoulders, long knuckle arms, a barrel
        // body, short legs. With a knife (the modifier gag) it holds a little RED ink knife in one hand.
        private void Gorilla(bool knife)
        {
            // Barrel torso (a big rounded body).
            var torso = new List<Vector3>
            {
                new Vector3(-0.46f, 0.24f, 0f), new Vector3(-0.44f, -0.18f, 0f), new Vector3(-0.34f, -0.52f, 0f),
                new Vector3(0f, -0.64f, 0f), new Vector3(0.34f, -0.52f, 0f), new Vector3(0.44f, -0.18f, 0f),
                new Vector3(0.46f, 0.24f, 0f)
            };
            Stroke("Torso", torso);
            // Shoulders humping up either side of the neck.
            var shoulders = new List<Vector3>();
            InkLine.AddArc(shoulders, new Vector2(0f, 0.2f), 0.5f, 20f, 160f, 22);
            Stroke("Shoulders", shoulders, _width * 0.95f);
            // Small head with a heavy brow and minimal face.
            Stroke("Head", Circle(new Vector2(0f, 0.46f), 0.19f));
            Stroke("Brow", Line(new Vector2(-0.14f, 0.52f), new Vector2(0.14f, 0.52f)), _width * 1.1f);
            Stroke("EyeL", Circle(new Vector2(-0.07f, 0.45f), 0.028f, 8), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.07f, 0.45f), 0.028f, 8), _width * 0.9f);
            Stroke("Muzzle", Line(new Vector2(-0.08f, 0.34f), new Vector2(0f, 0.3f), new Vector2(0.08f, 0.34f)), _width * 0.8f);
            // Long arms down the outside to big knuckle fists on the ground.
            Stroke("ArmL", Line(new Vector2(-0.44f, 0.22f), new Vector2(-0.6f, -0.16f), new Vector2(-0.54f, -0.5f)));
            Stroke("ArmR", Line(new Vector2(0.44f, 0.22f), new Vector2(0.6f, -0.16f), new Vector2(0.54f, -0.5f)));
            Stroke("KnuckL", Circle(new Vector2(-0.54f, -0.56f), 0.1f, 12), _width * 0.9f);
            Stroke("KnuckR", Circle(new Vector2(0.54f, -0.56f), 0.1f, 12), _width * 0.9f);
            // Short planted feet.
            Stroke("FootL", Line(new Vector2(-0.22f, -0.62f), new Vector2(-0.05f, -0.62f)), _width * 0.9f);
            Stroke("FootR", Line(new Vector2(0.05f, -0.62f), new Vector2(0.22f, -0.62f)), _width * 0.9f);
            if (knife)
            {
                // A little red ink knife in the right hand: a blade and a short handle. The whole joke of the
                // matchup is that the two apes are identical except for this.
                Stroke("KnifeBlade", Line(new Vector2(0.54f, -0.48f), new Vector2(0.9f, 0.02f), new Vector2(0.82f, -0.06f), new Vector2(0.86f, -0.16f)), _width * 0.95f, Palette.InkRed);
                Stroke("KnifeGuard", Line(new Vector2(0.47f, -0.52f), new Vector2(0.61f, -0.44f)), _width * 1.0f, Palette.InkRed);
                Stroke("KnifeGrip", Line(new Vector2(0.5f, -0.58f), new Vector2(0.58f, -0.46f)), _width * 1.3f, Palette.InkRed);
            }
        }

        // A plump hen: a round body, a small head with a comb, wattle and beak, a fan tail, two scaly legs.
        private void Chicken()
        {
            var body = new List<Vector3>();
            for (int i = 0; i <= 30; i++) { float a = i / 30f * Mathf.PI * 2f; body.Add(new Vector3(-0.04f + Mathf.Cos(a) * 0.42f, -0.08f + Mathf.Sin(a) * 0.4f, 0f)); }
            Stroke("Body", body);
            Stroke("Head", Circle(new Vector2(0.32f, 0.4f), 0.17f));
            Stroke("Comb", Line(new Vector2(0.2f, 0.54f), new Vector2(0.24f, 0.66f), new Vector2(0.32f, 0.56f), new Vector2(0.38f, 0.68f), new Vector2(0.44f, 0.56f)), _width * 0.8f);
            Stroke("Beak", Line(new Vector2(0.47f, 0.42f), new Vector2(0.64f, 0.37f), new Vector2(0.47f, 0.32f)), _width * 0.85f);
            Stroke("Wattle", Line(new Vector2(0.4f, 0.28f), new Vector2(0.4f, 0.16f)), _width * 0.8f);
            Stroke("Eye", Circle(new Vector2(0.36f, 0.42f), 0.03f, 8), _width * 0.9f);
            var wing = new List<Vector3>();
            InkLine.AddArc(wing, new Vector2(-0.05f, 0.0f), 0.3f, 190f, 350f, 16);
            Stroke("Wing", wing, _width * 0.8f);
            Stroke("Tail", Line(new Vector2(-0.42f, 0.08f), new Vector2(-0.66f, 0.42f)), _width * 0.9f);
            Stroke("Tail2", Line(new Vector2(-0.42f, -0.02f), new Vector2(-0.58f, 0.3f)), _width * 0.8f);
            Stroke("LegL", Line(new Vector2(-0.08f, -0.44f), new Vector2(-0.08f, -0.66f)), _width * 0.75f);
            Stroke("LegR", Line(new Vector2(0.12f, -0.44f), new Vector2(0.12f, -0.66f)), _width * 0.75f);
            Stroke("FootL", Line(new Vector2(-0.18f, -0.66f), new Vector2(-0.08f, -0.66f), new Vector2(0.0f, -0.66f)), _width * 0.6f);
            Stroke("FootR", Line(new Vector2(0.02f, -0.66f), new Vector2(0.12f, -0.66f), new Vector2(0.22f, -0.66f)), _width * 0.6f);
        }

        // A lion: a big spiky mane ring around a broad head, a minimal face, two front paws and a tufted tail.
        private void Lion()
        {
            Vector2 c = new Vector2(0f, 0.22f);
            var mane = new List<Vector3>();
            int pts = 24;
            for (int i = 0; i <= pts; i++)
            {
                float a = i / (float)pts * Mathf.PI * 2f;
                float r = (i % 2 == 0) ? 0.6f : 0.44f;
                mane.Add(new Vector3(c.x + Mathf.Cos(a) * r, c.y + Mathf.Sin(a) * r, 0f));
            }
            Stroke("Mane", mane);
            Stroke("Head", Circle(c, 0.34f));
            Stroke("EyeL", Circle(new Vector2(-0.12f, 0.28f), 0.035f, 8), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.12f, 0.28f), 0.035f, 8), _width * 0.9f);
            Stroke("Nose", Line(new Vector2(-0.06f, 0.14f), new Vector2(0.06f, 0.14f), new Vector2(0f, 0.06f), new Vector2(-0.06f, 0.14f)), _width * 0.8f);
            Stroke("Muzzle", Line(new Vector2(0f, 0.06f), new Vector2(0f, -0.02f)), _width * 0.7f);
            Stroke("MouthL", Line(new Vector2(0f, -0.02f), new Vector2(-0.1f, -0.08f)), _width * 0.7f);
            Stroke("MouthR", Line(new Vector2(0f, -0.02f), new Vector2(0.1f, -0.08f)), _width * 0.7f);
            // A hint of body below the mane: two front paws and a tufted tail.
            Stroke("PawL", Line(new Vector2(-0.2f, -0.5f), new Vector2(-0.2f, -0.66f)), _width * 0.9f);
            Stroke("PawR", Line(new Vector2(0.1f, -0.5f), new Vector2(0.1f, -0.66f)), _width * 0.9f);
            Stroke("PawBase", Line(new Vector2(-0.28f, -0.66f), new Vector2(0.18f, -0.66f)), _width * 0.8f);
            Stroke("Tail", Line(new Vector2(0.5f, -0.5f), new Vector2(0.7f, -0.32f), new Vector2(0.64f, -0.08f)), _width * 0.85f);
            Stroke("Tuft", Line(new Vector2(0.64f, -0.08f), new Vector2(0.56f, 0.04f), new Vector2(0.72f, 0.04f), new Vector2(0.64f, -0.08f)), _width * 0.8f);
        }

        // A sitting house cat: a rounded seated body, a head with pointy ears, a curled tail, front paws.
        private void HouseCat()
        {
            // Seated body: a teardrop widening to a base.
            var body = new List<Vector3>
            {
                new Vector3(-0.02f, 0.5f, 0f), new Vector3(-0.34f, 0.2f, 0f), new Vector3(-0.4f, -0.4f, 0f),
                new Vector3(-0.3f, -0.6f, 0f), new Vector3(0.3f, -0.6f, 0f), new Vector3(0.4f, -0.4f, 0f),
                new Vector3(0.34f, 0.2f, 0f), new Vector3(0.02f, 0.5f, 0f)
            };
            Stroke("Body", body);
            Stroke("Head", Circle(new Vector2(0f, 0.44f), 0.22f));
            Stroke("EarL", Line(new Vector2(-0.18f, 0.56f), new Vector2(-0.26f, 0.8f), new Vector2(-0.02f, 0.62f)), _width * 0.9f);
            Stroke("EarR", Line(new Vector2(0.18f, 0.56f), new Vector2(0.26f, 0.8f), new Vector2(0.02f, 0.62f)), _width * 0.9f);
            Stroke("EyeL", Circle(new Vector2(-0.09f, 0.46f), 0.03f, 8), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.09f, 0.46f), 0.03f, 8), _width * 0.9f);
            Stroke("Nose", Line(new Vector2(-0.03f, 0.37f), new Vector2(0.03f, 0.37f), new Vector2(0f, 0.32f), new Vector2(-0.03f, 0.37f)), _width * 0.7f);
            Stroke("WhL", Line(new Vector2(-0.12f, 0.38f), new Vector2(-0.4f, 0.4f)), _width * 0.5f);
            Stroke("WhR", Line(new Vector2(0.12f, 0.38f), new Vector2(0.4f, 0.4f)), _width * 0.5f);
            // A curled tail wrapping up the right side.
            Stroke("Tail", Line(new Vector2(0.3f, -0.56f), new Vector2(0.56f, -0.4f), new Vector2(0.56f, -0.02f), new Vector2(0.4f, 0.1f)), _width * 0.9f);
            // Two front paws at the base.
            Stroke("PawL", Circle(new Vector2(-0.14f, -0.58f), 0.07f, 10), _width * 0.7f);
            Stroke("PawR", Circle(new Vector2(0.14f, -0.58f), 0.07f, 10), _width * 0.7f);
        }

        // A toddler: an oversized head with a hair curl, a small body, stubby arms and legs.
        private void Toddler()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.36f), 0.32f));
            Stroke("Curl", Line(new Vector2(0.02f, 0.68f), new Vector2(0.1f, 0.8f), new Vector2(-0.04f, 0.82f)), _width * 0.75f);
            Stroke("EyeL", Circle(new Vector2(-0.1f, 0.38f), 0.035f, 8), _width * 0.9f);
            Stroke("EyeR", Circle(new Vector2(0.1f, 0.38f), 0.035f, 8), _width * 0.9f);
            var smile = new List<Vector3>(); InkLine.AddArc(smile, new Vector2(0f, 0.3f), 0.1f, 200f, 340f, 10); Stroke("Smile", smile, _width * 0.75f);
            Stroke("Body", Line(new Vector2(0f, 0.04f), new Vector2(0f, -0.22f)));
            Stroke("ArmL", Line(new Vector2(0f, -0.02f), new Vector2(-0.22f, 0.06f)), _width * 0.85f);
            Stroke("ArmR", Line(new Vector2(0f, -0.02f), new Vector2(0.22f, 0.06f)), _width * 0.85f);
            Stroke("LegL", Line(new Vector2(0f, -0.22f), new Vector2(-0.15f, -0.52f)), _width * 0.9f);
            Stroke("LegR", Line(new Vector2(0f, -0.22f), new Vector2(0.15f, -0.52f)), _width * 0.9f);
        }

        // A wasp: a striped pointed abdomen, a thorax and head with antennae, two wings, a stinger.
        private void Wasp()
        {
            var abdomen = new List<Vector3>
            {
                new Vector3(0f, 0.16f, 0f), new Vector3(0.2f, 0.06f, 0f), new Vector3(0.16f, -0.28f, 0f),
                new Vector3(0f, -0.52f, 0f), new Vector3(-0.16f, -0.28f, 0f), new Vector3(-0.2f, 0.06f, 0f),
                new Vector3(0f, 0.16f, 0f)
            };
            Stroke("Abdomen", abdomen);
            Stroke("Stripe1", Line(new Vector2(-0.17f, -0.04f), new Vector2(0.17f, -0.04f)), _width * 0.75f);
            Stroke("Stripe2", Line(new Vector2(-0.14f, -0.2f), new Vector2(0.14f, -0.2f)), _width * 0.75f);
            Stroke("Thorax", Circle(new Vector2(0f, 0.26f), 0.13f, 14));
            Stroke("Head", Circle(new Vector2(0f, 0.46f), 0.1f, 12));
            Stroke("AntL", Line(new Vector2(-0.05f, 0.54f), new Vector2(-0.14f, 0.68f)), _width * 0.6f);
            Stroke("AntR", Line(new Vector2(0.05f, 0.54f), new Vector2(0.14f, 0.68f)), _width * 0.6f);
            var wingL = new List<Vector3>(); InkLine.AddArc(wingL, new Vector2(-0.28f, 0.34f), 0.22f, 300f, 120f, 14); Stroke("WingL", wingL, _width * 0.7f);
            var wingR = new List<Vector3>(); InkLine.AddArc(wingR, new Vector2(0.28f, 0.34f), 0.22f, 60f, 240f, 14); Stroke("WingR", wingR, _width * 0.7f);
            Stroke("Stinger", Line(new Vector2(0f, -0.52f), new Vector2(0f, -0.66f)), _width * 0.8f);
        }

        // A reared grizzly bear: a shoulder hump, a big head with a snout, raised clawed arms, planted legs.
        private void Grizzly()
        {
            var torso = new List<Vector3>
            {
                new Vector3(-0.4f, 0.2f, 0f), new Vector3(-0.42f, -0.24f, 0f), new Vector3(-0.3f, -0.54f, 0f),
                new Vector3(0f, -0.64f, 0f), new Vector3(0.3f, -0.54f, 0f), new Vector3(0.42f, -0.24f, 0f),
                new Vector3(0.4f, 0.2f, 0f)
            };
            Stroke("Torso", torso);
            // A shoulder hump behind the neck (the grizzly cue), and the head.
            var hump = new List<Vector3>();
            InkLine.AddArc(hump, new Vector2(-0.18f, 0.24f), 0.28f, 30f, 160f, 16);
            Stroke("Hump", hump, _width * 0.9f);
            Stroke("Head", Circle(new Vector2(0.08f, 0.42f), 0.22f));
            Stroke("EarL", Circle(new Vector2(-0.06f, 0.6f), 0.07f, 10), _width * 0.85f);
            Stroke("EarR", Circle(new Vector2(0.22f, 0.6f), 0.07f, 10), _width * 0.85f);
            Stroke("Snout", Line(new Vector2(0.24f, 0.42f), new Vector2(0.42f, 0.38f), new Vector2(0.4f, 0.28f), new Vector2(0.24f, 0.3f)), _width * 0.85f);
            Stroke("Nose", Circle(new Vector2(0.4f, 0.36f), 0.035f, 8), _width * 1.1f);
            Stroke("Eye", Circle(new Vector2(0.14f, 0.46f), 0.03f, 8), _width * 0.9f);
            // Raised clawed arms, reared and menacing.
            Stroke("ArmL", Line(new Vector2(-0.36f, 0.14f), new Vector2(-0.56f, 0.34f), new Vector2(-0.52f, 0.52f)));
            Stroke("ArmR", Line(new Vector2(0.34f, 0.16f), new Vector2(0.5f, 0.36f), new Vector2(0.46f, 0.54f)));
            Stroke("ClawL", Line(new Vector2(-0.58f, 0.5f), new Vector2(-0.62f, 0.6f)), _width * 0.6f);
            Stroke("ClawL2", Line(new Vector2(-0.5f, 0.54f), new Vector2(-0.52f, 0.64f)), _width * 0.6f);
            Stroke("ClawR", Line(new Vector2(0.44f, 0.56f), new Vector2(0.46f, 0.66f)), _width * 0.6f);
            Stroke("ClawR2", Line(new Vector2(0.52f, 0.52f), new Vector2(0.56f, 0.62f)), _width * 0.6f);
            Stroke("FootL", Line(new Vector2(-0.28f, -0.62f), new Vector2(-0.06f, -0.62f)), _width * 0.9f);
            Stroke("FootR", Line(new Vector2(0.06f, -0.62f), new Vector2(0.28f, -0.62f)), _width * 0.9f);
        }

        // A professional fighter: a staggered stance with big round boxing gloves up in a guard, one jabbing.
        private void Boxer()
        {
            Stroke("Head", Circle(new Vector2(0f, 0.58f), 0.16f));
            Stroke("Body", Line(new Vector2(0f, 0.42f), new Vector2(0f, -0.12f)));
            Stroke("LegL", Line(new Vector2(0f, -0.12f), new Vector2(-0.28f, -0.62f)));
            Stroke("LegR", Line(new Vector2(0f, -0.12f), new Vector2(0.22f, -0.6f)));
            // Rear guard glove up by the chin; lead glove out in a jab.
            Stroke("ArmR", Line(new Vector2(0f, 0.32f), new Vector2(0.2f, 0.28f), new Vector2(0.28f, 0.42f)));
            Stroke("GloveR", Circle(new Vector2(0.3f, 0.46f), 0.13f, 16));
            Stroke("ArmL", Line(new Vector2(0f, 0.3f), new Vector2(-0.3f, 0.24f), new Vector2(-0.46f, 0.16f)));
            Stroke("GloveL", Circle(new Vector2(-0.52f, 0.12f), 0.14f, 16));
            Stroke("GloveLWrap", Line(new Vector2(-0.42f, 0.02f), new Vector2(-0.4f, 0.22f)), _width * 0.7f);
        }

        // ---------- Chapter 8 (The Campaign) doodles ----------

        // a small four-point sparkle (shared by the hat, the chalice, the trophy and the hoard)
        private void Star4(Vector2 c, float r)
        {
            Stroke("StarV", Line(c + new Vector2(0f, r), c + new Vector2(0f, -r)), _width * 0.7f);
            Stroke("StarH", Line(c + new Vector2(-r, 0f), c + new Vector2(r, 0f)), _width * 0.7f);
        }

        // The knight: an upright sword laid over a heraldic shield.
        private void Knight()
        {
            Stroke("Shield", Line(new Vector2(-0.36f, 0.46f), new Vector2(0.36f, 0.46f), new Vector2(0.38f, 0.06f),
                new Vector2(0.2f, -0.32f), new Vector2(0f, -0.54f), new Vector2(-0.2f, -0.32f),
                new Vector2(-0.38f, 0.06f), new Vector2(-0.36f, 0.46f)));
            Stroke("CrossV", Line(new Vector2(0f, 0.46f), new Vector2(0f, -0.5f)), _width * 0.55f);
            Stroke("CrossH", Line(new Vector2(-0.37f, 0.2f), new Vector2(0.37f, 0.2f)), _width * 0.55f);
            Stroke("Blade", Line(new Vector2(0f, 0.66f), new Vector2(0f, -0.16f)), _width * 1.3f);
            Stroke("Guard", Line(new Vector2(-0.18f, 0.5f), new Vector2(0.18f, 0.5f)), _width * 1.0f);
            Stroke("Pommel", Circle(new Vector2(0f, 0.7f), 0.05f, 10), _width);
        }

        // The rogue: a leaf-bladed dagger, tip up.
        private void Rogue()
        {
            Stroke("EdgeL", Line(new Vector2(0f, 0.62f), new Vector2(-0.11f, 0.06f)), _width * 0.9f);
            Stroke("EdgeR", Line(new Vector2(0f, 0.62f), new Vector2(0.11f, 0.06f)), _width * 0.9f);
            Stroke("Ricasso", Line(new Vector2(-0.11f, 0.06f), new Vector2(0.11f, 0.06f)), _width * 0.8f);
            Stroke("Guard", Line(new Vector2(-0.26f, 0.02f), new Vector2(0.26f, 0.02f)), _width * 1.0f);
            Stroke("Grip", Line(new Vector2(0f, 0.02f), new Vector2(0f, -0.34f)), _width * 1.2f);
            Stroke("Pommel", Circle(new Vector2(0f, -0.4f), 0.06f, 10), _width);
        }

        // The wizard: a wide-brimmed pointed hat, tip flopping, a couple of stars.
        private void Wizard()
        {
            var brim = new List<Vector3>();
            for (int i = 0; i <= 28; i++) { float a = i / 28f * Mathf.PI * 2f; brim.Add(new Vector3(Mathf.Cos(a) * 0.5f, -0.3f + Mathf.Sin(a) * 0.12f, 0f)); }
            Stroke("Brim", brim);
            Stroke("Cone", Line(new Vector2(-0.3f, -0.22f), new Vector2(0.02f, 0.58f), new Vector2(0.17f, 0.5f), new Vector2(0.3f, -0.22f)));
            Star4(new Vector2(-0.05f, 0.12f), 0.07f);
            Star4(new Vector2(0.1f, -0.04f), 0.05f);
        }

        // The bard: a rounded lute with a neck and strings.
        private void Bard()
        {
            var body = new List<Vector3>();
            for (int i = 0; i <= 30; i++) { float a = i / 30f * Mathf.PI * 2f; body.Add(new Vector3(-0.08f + Mathf.Cos(a) * 0.34f, -0.18f + Mathf.Sin(a) * 0.36f, 0f)); }
            Stroke("Body", body);
            Stroke("Hole", Circle(new Vector2(-0.08f, -0.12f), 0.08f, 14), _width * 0.8f);
            Stroke("Neck", Line(new Vector2(0.04f, 0.12f), new Vector2(0.44f, 0.56f)));
            Stroke("Neck2", Line(new Vector2(-0.14f, 0.15f), new Vector2(0.26f, 0.6f)));
            Stroke("Peg", Line(new Vector2(0.26f, 0.6f), new Vector2(0.5f, 0.62f), new Vector2(0.42f, 0.5f)));
            Stroke("String", Line(new Vector2(-0.06f, 0.14f), new Vector2(0.35f, 0.58f)), _width * 0.5f);
        }

        // The cleric: a chalice with a foot and a shine.
        private void Cleric()
        {
            Stroke("Bowl", Line(new Vector2(-0.28f, 0.34f), new Vector2(-0.2f, 0.02f), new Vector2(0.2f, 0.02f), new Vector2(0.28f, 0.34f)));
            Stroke("Rim", Line(new Vector2(-0.28f, 0.34f), new Vector2(0.28f, 0.34f)));
            Stroke("Stem", Line(new Vector2(0f, 0.02f), new Vector2(0f, -0.32f)), _width * 1.1f);
            Stroke("Foot", Line(new Vector2(-0.24f, -0.42f), new Vector2(-0.16f, -0.32f), new Vector2(0.16f, -0.32f), new Vector2(0.24f, -0.42f)));
            Stroke("FootBase", Line(new Vector2(-0.26f, -0.42f), new Vector2(0.26f, -0.42f)));
            Star4(new Vector2(0.02f, 0.56f), 0.09f);
        }

        // Reason (for the gold): a small stack of three flat coins with a dollar hint.
        private void Coins()
        {
            for (int k = 0; k < 3; k++)
            {
                float y = -0.24f + k * 0.2f;
                var e = new List<Vector3>();
                for (int i = 0; i <= 22; i++) { float a = i / 22f * Mathf.PI * 2f; e.Add(new Vector3(Mathf.Cos(a) * 0.38f, y + Mathf.Sin(a) * 0.13f, 0f)); }
                Stroke("Coin" + k, e);
            }
            Stroke("S", Line(new Vector2(0.08f, 0.24f), new Vector2(-0.06f, 0.26f), new Vector2(-0.1f, 0.17f), new Vector2(0.06f, 0.12f), new Vector2(0.05f, 0.04f), new Vector2(-0.1f, 0.05f)), _width * 0.7f);
        }

        // Reason (for the glory): a two-handled trophy cup with a star.
        private void Trophy()
        {
            Stroke("Bowl", Line(new Vector2(-0.3f, 0.46f), new Vector2(-0.2f, 0.06f), new Vector2(0.2f, 0.06f), new Vector2(0.3f, 0.46f)));
            Stroke("Rim", Line(new Vector2(-0.3f, 0.46f), new Vector2(0.3f, 0.46f)));
            var hl = new List<Vector3>(); InkLine.AddArc(hl, new Vector2(-0.34f, 0.32f), 0.15f, -90f, 130f, 12); Stroke("HandleL", hl, _width * 0.85f);
            var hr = new List<Vector3>(); InkLine.AddArc(hr, new Vector2(0.34f, 0.32f), 0.15f, 50f, 270f, 12); Stroke("HandleR", hr, _width * 0.85f);
            Stroke("Stem", Line(new Vector2(0f, 0.06f), new Vector2(0f, -0.22f)), _width * 1.1f);
            Stroke("Base", Line(new Vector2(-0.22f, -0.4f), new Vector2(-0.14f, -0.22f), new Vector2(0.14f, -0.22f), new Vector2(0.22f, -0.4f), new Vector2(-0.22f, -0.4f)));
            Star4(new Vector2(0f, 0.26f), 0.09f);
        }

        // Reason (to save someone): a plain heart.
        private void QuestHeart()
        {
            Stroke("Heart", Heart(new Vector2(0f, 0.02f), 0.62f), _width * 1.05f);
        }

        // Reason (nowhere else to be): a crossroads signpost, two boards pointing opposite ways.
        private void Signpost()
        {
            Stroke("Post", Line(new Vector2(0f, 0.5f), new Vector2(0f, -0.56f)), _width * 1.1f);
            Stroke("BoardL", Line(new Vector2(0.02f, 0.42f), new Vector2(-0.34f, 0.42f), new Vector2(-0.48f, 0.3f), new Vector2(-0.34f, 0.18f), new Vector2(0.02f, 0.18f)));
            Stroke("BoardR", Line(new Vector2(-0.02f, 0.12f), new Vector2(0.32f, 0.12f), new Vector2(0.46f, 0f), new Vector2(0.32f, -0.12f), new Vector2(-0.02f, -0.12f)));
            Stroke("Ground", Line(new Vector2(-0.16f, -0.56f), new Vector2(0.16f, -0.56f)), _width * 0.8f);
        }

        // The companion: a cloaked, hooded stranger with a hand held out.
        private void Companion()
        {
            Stroke("Cloak", Line(new Vector2(-0.34f, -0.56f), new Vector2(-0.26f, 0.12f), new Vector2(-0.08f, 0.44f), new Vector2(0.08f, 0.46f), new Vector2(0.26f, 0.14f), new Vector2(0.34f, -0.56f)));
            Stroke("Hem", Line(new Vector2(-0.34f, -0.56f), new Vector2(-0.1f, -0.5f), new Vector2(0.12f, -0.56f), new Vector2(0.34f, -0.5f)), _width * 0.85f);
            var hood = new List<Vector3>(); InkLine.AddArc(hood, new Vector2(0f, 0.22f), 0.16f, -40f, 220f, 14); Stroke("Hood", hood, _width * 0.85f);
            Stroke("EyeL", Circle(new Vector2(-0.06f, 0.22f), 0.02f, 6), _width);
            Stroke("EyeR", Circle(new Vector2(0.06f, 0.22f), 0.02f, 6), _width);
            Stroke("Arm", Line(new Vector2(0.2f, -0.02f), new Vector2(0.42f, -0.08f)), _width * 0.85f);
        }

        // The treasure: an open chest with a lock, spilling coins and a sparkle.
        private void TreasureChest()
        {
            Stroke("Base", Line(new Vector2(-0.42f, -0.42f), new Vector2(-0.42f, 0.06f), new Vector2(0.42f, 0.06f), new Vector2(0.42f, -0.42f), new Vector2(-0.42f, -0.42f)));
            Stroke("Band", Line(new Vector2(-0.42f, -0.2f), new Vector2(0.42f, -0.2f)), _width * 0.7f);
            Stroke("Lock", Line(new Vector2(-0.08f, -0.06f), new Vector2(0.08f, -0.06f), new Vector2(0.08f, -0.24f), new Vector2(-0.08f, -0.24f), new Vector2(-0.08f, -0.06f)), _width * 0.8f);
            Stroke("Lid", Line(new Vector2(-0.42f, 0.06f), new Vector2(-0.34f, 0.42f), new Vector2(0.06f, 0.5f), new Vector2(0.42f, 0.4f), new Vector2(0.42f, 0.06f)));
            Stroke("CoinA", Circle(new Vector2(-0.12f, 0.14f), 0.07f, 10), _width * 0.7f);
            Stroke("CoinB", Circle(new Vector2(0.12f, 0.12f), 0.06f, 10), _width * 0.7f);
            Star4(new Vector2(0.24f, 0.3f), 0.07f);
        }

        // ---------- fade ----------

        public void SetAlpha(float a)
        {
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null)
                    InkLine.SetAlpha(_strokes[i], i < _strokeColors.Count ? _strokeColors[i] : _color, Mathf.Clamp01(a));
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
