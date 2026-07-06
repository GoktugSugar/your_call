using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The aftermath tableau: it dims the world, then inks in the stats from a
    /// ResolutionReport with the player's pick in amber. Verb-agnostic; an optional
    /// threshold marker turns a reflective bar into the load-bearing number a coordination
    /// gamble turned on. Minimal UI: no window, no chrome, just marks on the dimmed page.
    /// </summary>
    public class StatsView : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _ink = Palette.Ink;
        [SerializeField] private Color _amber = Palette.Amber;
        [SerializeField] private Color _muted = Palette.Muted;

        [Header("Dim")]
        [SerializeField] private Color _scrimColor = Palette.Paper;
        [SerializeField, Range(0f, 1f)] private float _scrimAlpha = 0.8f;

        [Header("Bars")]
        [SerializeField] private float _barWidth = 0.24f;
        [SerializeField] private float _pickWidthMul = 1.22f;
        [SerializeField] private float _barMaxLength = 4.0f;
        [SerializeField] private float _barStartX = -2.1f;
        [SerializeField] private float _rowSpacing = 1.25f;
        [SerializeField] private int _sortingScrim = 30;
        [SerializeField] private int _sortingContent = 32;

        [Header("Type")]
        [SerializeField] private float _headingSize = 3.2f;
        [SerializeField] private float _labelSize = 2.7f;
        [SerializeField] private float _countSize = 3.6f;
        [SerializeField] private float _hintSize = 2.3f;
        [SerializeField] private float _thresholdSize = 2.2f;
        [SerializeField] private string _hintText = "press any key to go again";

        private SpriteRenderer _scrim;
        private TextMeshPro _heading;
        private TextMeshPro _hint;
        private LineRenderer _threshold;
        private TextMeshPro _thresholdLabel;
        private readonly List<LineRenderer> _bars = new List<LineRenderer>();
        private readonly List<float> _barTargets = new List<float>();
        private readonly List<TextMeshPro> _labels = new List<TextMeshPro>();
        private readonly List<TextMeshPro> _counts = new List<TextMeshPro>();
        private bool _built;

        private void Awake() { Build(); }

        private void Build()
        {
            if (_built) return;
            _scrim = MakeScrim();
            _heading = InkText.Create(transform, "Heading", _headingSize, _muted, TextAlignmentOptions.Center, _sortingContent);
            _hint = InkText.Create(transform, "Hint", _hintSize, _muted, TextAlignmentOptions.Center, _sortingContent);
            _thresholdLabel = InkText.Create(transform, "ThresholdLabel", _thresholdSize, _ink, TextAlignmentOptions.Center, _sortingContent);
            _threshold = InkLine.Create(transform, "ThresholdLine", _inkMaterial, _barWidth * 0.3f, _ink, _sortingContent + 1, 2);
            _threshold.positionCount = 2;
            SetAlpha(_scrim, 0f);
            InkText.SetAlpha(_heading, 0f);
            InkText.SetAlpha(_hint, 0f);
            InkText.SetAlpha(_thresholdLabel, 0f);
            InkLine.SetAlpha(_threshold, _ink, 0f);
            _built = true;
        }

        private SpriteRenderer MakeScrim()
        {
            var tex = new Texture2D(4, 4, TextureFormat.RGBA32, false);
            var px = new Color32[16];
            for (int i = 0; i < px.Length; i++) px[i] = new Color32(255, 255, 255, 255);
            tex.SetPixels32(px); tex.Apply();
            var spr = Sprite.Create(tex, new Rect(0, 0, 4, 4), new Vector2(0.5f, 0.5f), 4f);

            var go = new GameObject("Scrim");
            go.transform.SetParent(transform, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = spr;
            sr.color = new Color(_scrimColor.r, _scrimColor.g, _scrimColor.b, 0f);
            sr.sortingOrder = _sortingScrim;
            go.transform.localScale = new Vector3(64f, 44f, 1f);
            return sr;
        }

        public IEnumerator Reveal(ResolutionReport report, float fade)
        {
            BuildRows(report);

            int n = _bars.Count;
            float contentCenterX = _barStartX + _barMaxLength * 0.5f;
            float top = (n - 1) * 0.5f * _rowSpacing;
            _heading.transform.localPosition = new Vector3(contentCenterX, top + 1.95f, 0f);
            _hint.transform.localPosition = new Vector3(contentCenterX, -top - 1.15f, 0f);
            _heading.text = report != null ? report.Heading : string.Empty;
            _hint.text = _hintText;

            bool showThreshold = report != null && report.HasThreshold && report.MaxValue > 0f && n > 0;
            if (showThreshold)
            {
                float mx = _barStartX + _barMaxLength * Mathf.Clamp01(report.ThresholdValue / report.MaxValue);
                float topY = top + _rowSpacing * 0.5f;
                float botY = -top - _rowSpacing * 0.5f;
                _threshold.SetPosition(0, new Vector3(mx, topY, 0f));
                _threshold.SetPosition(1, new Vector3(mx, botY, 0f));
                _thresholdLabel.transform.localPosition = new Vector3(mx, topY + 0.35f, 0f);
                _thresholdLabel.text = Mathf.RoundToInt(report.ThresholdValue) + "  " + report.ThresholdLabel;
            }

            // 1) Dim the world.
            float t = 0f, f = Mathf.Max(fade, 0.01f);
            while (t < f) { t += Time.deltaTime; SetAlpha(_scrim, EaseUtil.OutCubic(t / f) * _scrimAlpha); yield return null; }
            SetAlpha(_scrim, _scrimAlpha);

            // 2) Ink in the heading, grow the bars, fade the labels and counts in.
            InkText.SetAlpha(_heading, 1f);
            t = 0f; float grow = 0.6f;
            while (t < grow)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / grow);
                for (int i = 0; i < n; i++)
                {
                    _bars[i].SetPosition(1, new Vector3(_barStartX + _barTargets[i] * k, RowY(i, n), 0f));
                    InkText.SetAlpha(_labels[i], k);
                    InkText.SetAlpha(_counts[i], k);
                }
                yield return null;
            }
            for (int i = 0; i < n; i++)
            {
                _bars[i].SetPosition(1, new Vector3(_barStartX + _barTargets[i], RowY(i, n), 0f));
                InkText.SetAlpha(_labels[i], 1f);
                InkText.SetAlpha(_counts[i], 1f);
            }

            // 3) The threshold marker (the line the crowd had to cross).
            if (showThreshold)
            {
                t = 0f; float tf = 0.35f;
                while (t < tf) { t += Time.deltaTime; float k = t / tf; InkLine.SetAlpha(_threshold, _ink, k); InkText.SetAlpha(_thresholdLabel, k); yield return null; }
                InkLine.SetAlpha(_threshold, _ink, 1f); InkText.SetAlpha(_thresholdLabel, 1f);
            }

            // 4) The quiet replay hint.
            t = 0f; float hf = 0.4f;
            while (t < hf) { t += Time.deltaTime; InkText.SetAlpha(_hint, t / hf); yield return null; }
            InkText.SetAlpha(_hint, 1f);
        }

        /// <summary>
        /// Lift the whole tableau back off the page and clear it, so a chained sequence can
        /// carry on to the next beat over a clean void. Standalone scenes reload instead and
        /// never call this.
        /// </summary>
        public IEnumerator Hide(float fade)
        {
            float t = 0f, f = Mathf.Max(fade, 0.01f);
            while (t < f)
            {
                t += Time.deltaTime;
                float k = 1f - EaseUtil.OutCubic(t / f);
                SetAlpha(_scrim, _scrimAlpha * k);
                InkText.SetAlpha(_heading, k);
                InkText.SetAlpha(_hint, k);
                InkText.SetAlpha(_thresholdLabel, k);
                InkLine.SetAlpha(_threshold, _ink, k);
                for (int i = 0; i < _bars.Count; i++) FadeLine(_bars[i], k);
                for (int i = 0; i < _labels.Count; i++) InkText.SetAlpha(_labels[i], k);
                for (int i = 0; i < _counts.Count; i++) InkText.SetAlpha(_counts[i], k);
                yield return null;
            }
            SetAlpha(_scrim, 0f);
            InkText.SetAlpha(_heading, 0f);
            InkText.SetAlpha(_hint, 0f);
            InkText.SetAlpha(_thresholdLabel, 0f);
            InkLine.SetAlpha(_threshold, _ink, 0f);
            ClearRows();
        }

        private static void FadeLine(LineRenderer lr, float k)
        {
            if (lr == null) return;
            var c = lr.startColor; c.a = k; InkLine.SetColor(lr, c);
        }

        private float RowY(int i, int n)
        {
            float top = (n - 1) * 0.5f * _rowSpacing;
            return top - i * _rowSpacing;
        }

        private void BuildRows(ResolutionReport report)
        {
            ClearRows();
            if (report == null) return;
            float max = Mathf.Max(1f, report.MaxValue);
            var bars = report.Bars;
            int n = bars.Count;
            for (int i = 0; i < n; i++)
            {
                bool pick = bars[i].IsPick;
                bool coloured = bars[i].Tint.HasValue;
                Color barColor;
                float barWidth;
                if (coloured)
                {
                    // Coloured dilemma: keep the bar's own colour, deepen and widen the pick.
                    barColor = pick ? Deepen(bars[i].Tint.Value) : bars[i].Tint.Value;
                    barWidth = pick ? _barWidth * _pickWidthMul : _barWidth;
                }
                else
                {
                    barColor = pick ? _amber : _ink;
                    barWidth = _barWidth;
                }
                float rowY = RowY(i, n);
                float len = _barMaxLength * Mathf.Clamp01(bars[i].Value / max);

                var bar = InkLine.Create(transform, "Bar" + i, _inkMaterial, barWidth, barColor, _sortingContent);
                bar.positionCount = 2;
                bar.SetPosition(0, new Vector3(_barStartX, rowY, 0f));
                bar.SetPosition(1, new Vector3(_barStartX, rowY, 0f));
                _bars.Add(bar); _barTargets.Add(len);

                var label = InkText.Create(transform, "Label" + i, _labelSize, pick ? _amber : _muted, TextAlignmentOptions.Left, _sortingContent);
                label.rectTransform.sizeDelta = new Vector2(6f, 1f);
                label.transform.localPosition = new Vector3(_barStartX + 3.0f, rowY + 0.34f, 0f);
                label.text = bars[i].Label;
                InkText.SetAlpha(label, 0f);
                _labels.Add(label);

                var count = InkText.Create(transform, "Count" + i, _countSize, pick ? _amber : _ink, TextAlignmentOptions.Left, _sortingContent);
                count.rectTransform.sizeDelta = new Vector2(2.5f, 1f);
                count.transform.localPosition = new Vector3(_barStartX + len + 0.3f + 1.25f, rowY, 0f);
                count.text = Mathf.RoundToInt(bars[i].Value).ToString();
                InkText.SetAlpha(count, 0f);
                _counts.Add(count);
            }
        }

        private void ClearRows()
        {
            foreach (var b in _bars) if (b) Destroy(b.gameObject);
            foreach (var l in _labels) if (l) Destroy(l.gameObject);
            foreach (var c in _counts) if (c) Destroy(c.gameObject);
            _bars.Clear(); _barTargets.Clear(); _labels.Clear(); _counts.Clear();
        }

        private static void SetAlpha(SpriteRenderer sr, float a)
        {
            var c = sr.color; c.a = a; sr.color = c;
        }

        private static Color Deepen(Color c)
        {
            return new Color(c.r * 0.62f, c.g * 0.62f, c.b * 0.62f, c.a);
        }
    }
}
