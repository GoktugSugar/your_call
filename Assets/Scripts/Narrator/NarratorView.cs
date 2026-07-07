using System.Collections;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The narrator's line in world space, inside the DialogueBox. It inks the words on one
    /// character at a time, reliably, every page, and pages long narration by whole sentences:
    /// a page holds as many complete sentences as fit the box, and a sentence is never split
    /// across two boxes. A click or key turns the page (and finishes the current page's typing).
    /// Authored emphasis tags become palette colours via <see cref="InkMarkup"/> before render,
    /// so <see cref="Typed"/> reports the real glyphs and the blip voice stays in sync. Draws no
    /// chrome; the DialogueBox frames it and can drive its position.
    /// </summary>
    public class NarratorView : MonoBehaviour
    {
        [Header("Type")]
        [Tooltip("The dialogue handwriting font (Caveat). Left empty falls back to the default TMP font.")]
        [SerializeField] private TMP_FontAsset _font;
        [SerializeField] private float _fontSize = 2.8f;
        [SerializeField] private Color _color = Palette.Ink;
        [Tooltip("Centred by default: horizontal centre, vertical middle, inside the box.")]
        [SerializeField] private TextAlignmentOptions _alignment = TextAlignmentOptions.Center;
        [Tooltip("Text area size: leaves an inner margin versus the box.")]
        [SerializeField] private float _width = 14.6f;
        [SerializeField] private float _height = 1.1f;
        [SerializeField] private int _sortingOrder = 20;
        [SerializeField] private float _charsPerSecond = 32f;
        [Tooltip("A click sooner than this into a page is ignored, so a leftover click never makes a page appear instant.")]
        [SerializeField] private float _skipLockout = 0.18f;
        [Tooltip("A click sooner than this after a page finishes is ignored, so one click never turns two pages.")]
        [SerializeField] private float _pageAdvanceLockout = 0.2f;

        private TextMeshPro _text;
        private Coroutine _routine;

        /// <summary>True while narration is being delivered (typing or awaiting a page turn).</summary>
        public bool IsShowing { get; private set; }

        /// <summary>True while a page is actively inking on, so the imp stirs and its voice talks.</summary>
        public event System.Action<bool> Speaking;

        /// <summary>Raised per visible glyph as it inks on (skips tags), so the blip voice tracks typing exactly.</summary>
        public event System.Action<char> Typed;

        /// <summary>Raised each time a fresh box (page) is shown, so the imp repositions once per box.</summary>
        public event System.Action PageChanged;

        /// <summary>True from Show until Clear (a box is on screen, even after it finishes typing).</summary>
        public bool HasLine { get; private set; }

        private void Awake()
        {
            _text = InkText.Create(transform, "Line", _fontSize, _color, _alignment, _sortingOrder);
            if (_font != null) _text.font = _font;
            _text.rectTransform.sizeDelta = new Vector2(_width, _height);
            _text.overflowMode = TextOverflowModes.Overflow; // each page is built to fit, so no clipping
            InkText.SetAlpha(_text, 0f);
        }

        public void Show(string line)
        {
            if (_routine != null) StopCoroutine(_routine);
            IsShowing = true;
            HasLine = true;
            _routine = StartCoroutine(Run(line));
        }

        public void Clear()
        {
            if (_routine != null) StopCoroutine(_routine);
            IsShowing = false;
            HasLine = false;
            Speaking?.Invoke(false);
            if (_text != null) { _text.text = string.Empty; InkText.SetAlpha(_text, 0f); }
        }

        /// <summary>Override the text area, so a frame (e.g. the speech bubble) can set a wrap width
        /// and size itself to the result. Harmless if left alone; the dialogue box uses the defaults.</summary>
        public void SetTextArea(Vector2 size)
        {
            if (_text != null) _text.rectTransform.sizeDelta = size;
        }

        /// <summary>Measure the snug size a line would render at, wrapped to <paramref name="maxWidth"/>:
        /// the width of its longest line (never more than maxWidth) and its wrapped height. A pure
        /// calculation that does not touch the live text or the typewriter, so the speech bubble can
        /// size itself tightly to the actual text (a short line gets a small bubble).</summary>
        public Vector2 MeasureWrapped(string authored, float maxWidth)
        {
            if (_text == null) return Vector2.zero;
            Vector2 v = _text.GetPreferredValues(InkMarkup.ToRichText(authored), maxWidth, 0f);
            return new Vector2(Mathf.Clamp(v.x, 0.2f, maxWidth), Mathf.Max(v.y, 0.2f));
        }

        private IEnumerator Run(string authored)
        {
            List<string> pages = BuildPages(InkMarkup.ToRichText(authored));
            for (int p = 0; p < pages.Count; p++)
            {
                _text.text = pages[p];
                InkText.SetAlpha(_text, 1f);    // opaque; the per-glyph reveal is done in vertex alpha
                PageChanged?.Invoke();          // the imp hops to a fresh spot for this box
                yield return TypePage();
                if (p < pages.Count - 1) yield return WaitAdvance();
            }
            IsShowing = false;
        }

        // The whole page is laid out once so its centred position is fixed, then the glyphs are
        // revealed one at a time by raising their vertex alpha only, never re-laying-out, so the
        // text never shifts while typing. A click only finishes the page after a short lockout,
        // so a click carried over from the previous box can never make a page appear instant.
        private IEnumerator TypePage()
        {
            _text.maxVisibleCharacters = int.MaxValue;
            _text.ForceMeshUpdate();                       // final layout, all glyphs in the atlas
            TMP_TextInfo info = _text.textInfo;
            int total = info.characterCount;

            for (int i = 0; i < total; i++) SetGlyphAlpha(info, i, 0);   // hide, keeping colour
            _text.UpdateVertexData(TMP_VertexDataUpdateFlags.Colors32);

            Speaking?.Invoke(true);
            float cps = Mathf.Max(_charsPerSecond, 1f);
            float acc = 0f, lockT = 0f;
            int revealed = 0;

            while (revealed < total)
            {
                lockT += Time.deltaTime;
                if (lockT > _skipLockout && PointerInput.AdvancePressed)
                {
                    for (; revealed < total; revealed++) SetGlyphAlpha(info, revealed, 255); // finish (blips stop)
                    break;
                }
                acc += Time.deltaTime * cps;
                int shown = Mathf.Min(total, Mathf.FloorToInt(acc));
                if (shown > revealed)
                {
                    for (; revealed < shown; revealed++)
                    {
                        SetGlyphAlpha(info, revealed, 255);
                        Typed?.Invoke(info.characterInfo[revealed].character);
                    }
                    _text.UpdateVertexData(TMP_VertexDataUpdateFlags.Colors32);
                }
                yield return null;
            }

            _text.UpdateVertexData(TMP_VertexDataUpdateFlags.Colors32);
            Speaking?.Invoke(false);
        }

        // Raise or drop one character's four vertex alphas, preserving its RGB (so amber / blue /
        // red emphasis is kept). Spaces carry no vertices.
        private static void SetGlyphAlpha(TMP_TextInfo info, int i, byte a)
        {
            TMP_CharacterInfo ci = info.characterInfo[i];
            if (!ci.isVisible) return;
            Color32[] colors = info.meshInfo[ci.materialReferenceIndex].colors32;
            int v = ci.vertexIndex;
            colors[v + 0].a = a; colors[v + 1].a = a; colors[v + 2].a = a; colors[v + 3].a = a;
        }

        private IEnumerator WaitAdvance()
        {
            float t = 0f;
            while (true)
            {
                t += Time.deltaTime;
                if (t > _pageAdvanceLockout && PointerInput.AdvancePressed) yield break;
                yield return null;
            }
        }

        // ---------- Sentence-boundary paging ----------

        private static readonly Regex _sentenceSplit = new Regex(@"(?<=[.!?])\s+", RegexOptions.Compiled);

        // Pack whole sentences into pages that fit the box; a sentence is never split.
        private List<string> BuildPages(string rich)
        {
            var pages = new List<string>();
            var sentences = SplitSentences(rich);
            string cur = string.Empty;
            for (int i = 0; i < sentences.Count; i++)
            {
                string s = sentences[i];
                string candidate = cur.Length == 0 ? s : cur + " " + s;
                if (cur.Length == 0 || Fits(candidate)) cur = candidate; // a sentence too long to fit still gets its own page
                else { pages.Add(cur); cur = s; }
            }
            if (cur.Length > 0) pages.Add(cur);
            if (pages.Count == 0) pages.Add(rich);
            return pages;
        }

        private static List<string> SplitSentences(string rich)
        {
            var parts = _sentenceSplit.Split(rich);
            var list = new List<string>(parts.Length);
            for (int i = 0; i < parts.Length; i++)
            {
                string p = parts[i].Trim();
                if (p.Length > 0) list.Add(p);
            }
            return list;
        }

        private bool Fits(string candidate)
        {
            _text.text = candidate;
            _text.ForceMeshUpdate();
            return _text.preferredHeight <= _text.rectTransform.rect.height + 0.02f;
        }
    }
}
