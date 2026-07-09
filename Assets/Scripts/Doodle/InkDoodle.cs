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
