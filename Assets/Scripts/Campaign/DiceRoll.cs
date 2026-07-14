using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The small reusable dice presentation for Chapter 8 (The Campaign), used at exactly the two roll beats
    /// (the first roll that teaches the die, and the finale roll that decides it). Dice are rare and special
    /// here, so this is deliberately its own set piece rather than a per-beat mechanic: a hand-drawn ink d6
    /// with pips, an odds caption, an animated tumble that decelerates onto a face, and an amber flash on the
    /// landed value. Built from the shared ink strokes like the <see cref="ConfessionBooth"/>, so it reads
    /// on-model in the black-ink-on-paper doodle style. The beat owns the odds logic and the imp's reaction to
    /// the result; this owns only the die and its roll. One job: draw and roll the die.
    /// </summary>
    public sealed class DiceRoll : MonoBehaviour
    {
        private Material _mat;
        private TMP_FontAsset _font;
        private Color _color = Palette.Ink;
        private Color _land = Palette.Amber;
        private float _width = 0.055f;
        private int _sorting = 20;
        private float _half = 0.5f;       // half the die's side, in local units (before the transform scale)
        private float _corner = 0.14f;    // corner rounding
        private float _pipR = 0.058f;     // pip radius
        private float _pipInset = 0.26f;  // pip offset from centre for the corner/edge pips

        private readonly List<LineRenderer> _frame = new List<LineRenderer>();
        private Transform _pipRoot;
        private readonly List<LineRenderer> _pips = new List<LineRenderer>();
        private TextMeshPro _odds;
        private Vector3 _baseScale = Vector3.one;
        private bool _built;
        private int _face = 1;

        public int Face => _face;

        /// <summary>Build a die under a parent at a local position and scale, ready to <see cref="Show"/>.</summary>
        public static DiceRoll Create(Transform parent, string name, Vector3 localPos, float scale,
            Material material, TMP_FontAsset font, Color? color = null)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            go.transform.localScale = new Vector3(scale, scale, 1f);
            var d = go.AddComponent<DiceRoll>();
            d._mat = material;
            d._font = font;
            if (color.HasValue) d._color = color.Value;
            d.Build();
            return d;
        }

        private void Build()
        {
            if (_built) return;
            _baseScale = transform.localScale;

            var square = RoundedSquare(_half, _corner);
            var lr = InkLine.Create(transform, "Die", _mat, _width, _color, _sorting);
            InkLine.SetPoints(lr, square);
            lr.gameObject.AddComponent<LineBoil>().Capture();
            _frame.Add(lr);

            _pipRoot = new GameObject("Pips").transform;
            _pipRoot.SetParent(transform, false);

            for (int i = 0; i < _frame.Count; i++) InkLine.SetAlpha(_frame[i], _color, 0f);
            SetFace(_face);
            SetPipAlpha(0f);
            _built = true;
        }

        // ---------- the odds caption ----------

        /// <summary>Set the visible-odds caption under the die (markup aware, so [amber] renders as colour).
        /// Pass null or empty to hide it.</summary>
        public void SetOdds(string richLine)
        {
            if (string.IsNullOrEmpty(richLine)) { if (_odds != null) _odds.gameObject.SetActive(false); return; }
            if (_odds == null)
            {
                _odds = InkText.Create(transform, "Odds", 2.1f, Palette.Ink, TextAlignmentOptions.Center, _sorting + 1);
                if (_font != null) _odds.font = _font;
                _odds.rectTransform.sizeDelta = new Vector2(6.0f, 1.2f);
                _odds.transform.localPosition = new Vector3(0f, -_half - 0.5f, 0f);
            }
            _odds.gameObject.SetActive(true);
            _odds.text = InkMarkup.ToRichText(Localization.Localize(richLine));
        }

        // ---------- show / hide ----------

        public IEnumerator Show(float dur)
        {
            if (!_built) Build();
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                for (int i = 0; i < _frame.Count; i++) InkLine.SetAlpha(_frame[i], _color, k);
                SetPipAlpha(k);
                yield return null;
            }
            for (int i = 0; i < _frame.Count; i++) InkLine.SetAlpha(_frame[i], _color, 1f);
            SetPipAlpha(1f);
        }

        /// <summary>Snap the die fully visible without a fade (used by the editor preview, and available at
        /// runtime if a beat wants the die shown instantly).</summary>
        public void ShowInstant()
        {
            if (!_built) Build();
            for (int i = 0; i < _frame.Count; i++) InkLine.SetAlpha(_frame[i], _color, 1f);
            SetPipAlpha(1f);
        }

        public IEnumerator Hide(float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = 1f - t / d;
                for (int i = 0; i < _frame.Count; i++) InkLine.SetAlpha(_frame[i], _color, k);
                SetPipAlpha(k);
                if (_odds != null) InkText.SetAlpha(_odds, k);
                yield return null;
            }
            gameObject.SetActive(false);
        }

        // ---------- the roll ----------

        /// <summary>Tumble the die and land it on <paramref name="landing"/> (1..6): a rapid face cycle that
        /// decelerates, a little wobble and scale bounce, then an amber flash and settle on the result.</summary>
        public IEnumerator Roll(int landing, float dur)
        {
            landing = Mathf.Clamp(landing, 1, 6);
            float d = Mathf.Max(dur, 0.3f);
            float t = 0f;
            int last = _face;
            while (t < d)
            {
                float k = t / d;                                   // 0..1
                int f = Random.Range(1, 7);
                if (f == last) f = f % 6 + 1;                       // never show the same face twice running
                last = f;
                SetFace(f);
                float wobble = Mathf.Sin(t * 26f) * 10f * (1f - k); // degrees, settling
                float bounce = 1f + Mathf.Sin(t * 30f) * 0.05f * (1f - k);
                transform.localRotation = Quaternion.Euler(0f, 0f, wobble);
                transform.localScale = _baseScale * bounce;
                float interval = Mathf.Lerp(0.04f, 0.2f, k * k);   // slows toward the end
                yield return new WaitForSeconds(interval);
                t += interval;
            }
            transform.localRotation = Quaternion.identity;
            SetFace(landing);
            yield return FlashAndSettle();
        }

        private IEnumerator FlashAndSettle()
        {
            // a quick overshoot bounce
            float t = 0f, d = 0.28f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = t / d;
                float s = 1f + Mathf.Sin(k * Mathf.PI) * 0.14f;
                transform.localScale = _baseScale * s;
                Color c = Color.Lerp(_land, _color, k);            // amber flash fading to ink
                for (int i = 0; i < _pips.Count; i++) if (_pips[i] != null) InkLine.SetAlpha(_pips[i], c, 1f);
                yield return null;
            }
            transform.localScale = _baseScale;
            for (int i = 0; i < _pips.Count; i++) if (_pips[i] != null) InkLine.SetAlpha(_pips[i], _color, 1f);
        }

        // ---------- pips ----------

        public void SetFace(int v)
        {
            _face = Mathf.Clamp(v, 1, 6);
            for (int i = 0; i < _pips.Count; i++) if (_pips[i] != null) Destroy(_pips[i].gameObject);
            _pips.Clear();
            foreach (var p in PipLayout(_face)) Pip(p);
        }

        private void Pip(Vector2 c)
        {
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, c, _pipR, 0f, 360f, 12);
            var lr = InkLine.Create(_pipRoot, "Pip", _mat, _width * 2.0f, _color, _sorting + 2);
            InkLine.SetPoints(lr, pts);
            _pips.Add(lr);
        }

        private void SetPipAlpha(float a)
        {
            for (int i = 0; i < _pips.Count; i++) if (_pips[i] != null) InkLine.SetAlpha(_pips[i], _color, a);
        }

        private IEnumerable<Vector2> PipLayout(int v)
        {
            float o = _pipInset;
            Vector2 TL = new Vector2(-o, o), TR = new Vector2(o, o), C = Vector2.zero;
            Vector2 BL = new Vector2(-o, -o), BR = new Vector2(o, -o);
            Vector2 ML = new Vector2(-o, 0f), MR = new Vector2(o, 0f);
            switch (v)
            {
                case 1: return new[] { C };
                case 2: return new[] { TL, BR };
                case 3: return new[] { TL, C, BR };
                case 4: return new[] { TL, TR, BL, BR };
                case 5: return new[] { TL, TR, C, BL, BR };
                default: return new[] { TL, ML, BL, TR, MR, BR };
            }
        }

        // ---------- the rounded-square die outline ----------

        private static List<Vector3> RoundedSquare(float half, float r)
        {
            var pts = new List<Vector3>();
            r = Mathf.Min(r, half * 0.9f);
            float inner = half - r;
            // walk CCW from the bottom edge, arcing each corner
            pts.Add(new Vector3(-inner, -half, 0f));
            pts.Add(new Vector3(inner, -half, 0f));
            InkLine.AddArc(pts, new Vector2(inner, -inner), r, -90f, 0f, 6);
            pts.Add(new Vector3(half, inner, 0f));
            InkLine.AddArc(pts, new Vector2(inner, inner), r, 0f, 90f, 6);
            pts.Add(new Vector3(-inner, half, 0f));
            InkLine.AddArc(pts, new Vector2(-inner, inner), r, 90f, 180f, 6);
            pts.Add(new Vector3(-half, -inner, 0f));
            InkLine.AddArc(pts, new Vector2(-inner, -inner), r, 180f, 270f, 6);
            return pts;
        }
    }
}
