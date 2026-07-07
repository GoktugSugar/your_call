using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The narrator's line in world space, inside the DialogueBox. It inks the words on a
    /// character at a time, and pages long narration so nothing ever overflows the box: each
    /// page fills the frame, is typed out, and waits for a click or key to advance. It draws
    /// no chrome of its own. Authored emphasis tags ([amber]/[red]/[blue]) are turned into the
    /// palette's colours by <see cref="InkMarkup"/> before rendering. It raises small events
    /// (Speaking, Typed, PageChanged) so the imp, its blip voice, and the box can react.
    /// </summary>
    public class NarratorView : MonoBehaviour
    {
        [SerializeField] private float _fontSize = 2.8f;
        [SerializeField] private Color _color = Palette.Ink;
        [Tooltip("Text area inside the box (leave an inner margin versus the box size).")]
        [SerializeField] private float _width = 14.6f;
        [SerializeField] private float _height = 1.15f;
        [SerializeField] private int _sortingOrder = 20;
        [SerializeField] private float _charsPerSecond = 45f;
        [Tooltip("A click sooner than this after a page finishes is ignored, so one click never skips a page.")]
        [SerializeField] private float _pageAdvanceLockout = 0.22f;

        private TextMeshPro _text;
        private Coroutine _routine;

        /// <summary>True while narration is still being delivered (typing or awaiting a page turn).</summary>
        public bool IsShowing { get; private set; }

        /// <summary>True while a line is actively inking on, so a speaker (the imp) can stir.</summary>
        public event System.Action<bool> Speaking;

        /// <summary>Raised per visible glyph as it inks on (skips rich-text tags), so a blip voice can talk.</summary>
        public event System.Action<char> Typed;

        /// <summary>Raised each time a fresh page (or line) is shown, so the imp repositions once per box.</summary>
        public event System.Action PageChanged;

        /// <summary>True from Show until Clear (a box is on screen, even after it finishes typing).</summary>
        public bool HasLine { get; private set; }

        private void Awake()
        {
            _text = InkText.Create(transform, "Line", _fontSize, _color, TextAlignmentOptions.Top, _sortingOrder);
            _text.rectTransform.sizeDelta = new Vector2(_width, _height);
            _text.overflowMode = TextOverflowModes.Page;
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

        private IEnumerator Run(string authored)
        {
            _text.text = InkMarkup.ToRichText(authored);
            _text.maxVisibleCharacters = 0;
            _text.pageToDisplay = 1;
            InkText.SetAlpha(_text, 1f);
            _text.ForceMeshUpdate();

            int pageCount = Mathf.Max(1, _text.textInfo.pageCount);
            for (int page = 1; page <= pageCount; page++)
            {
                _text.pageToDisplay = page;
                PageChanged?.Invoke();          // the imp hops to a fresh spot for this box
                yield return TypePage(page);
                if (page < pageCount)
                    yield return WaitAdvance();  // click or key turns the page
            }

            IsShowing = false;
        }

        private IEnumerator TypePage(int page)
        {
            var info = _text.textInfo;
            int idx = Mathf.Clamp(page - 1, 0, Mathf.Max(0, info.pageCount - 1));
            int first = info.pageInfo[idx].firstCharacterIndex;
            int last = info.pageInfo[idx].lastCharacterIndex;
            first = Mathf.Clamp(first, 0, Mathf.Max(0, info.characterCount - 1));
            last = Mathf.Clamp(last, first, Mathf.Max(first, info.characterCount - 1));

            Speaking?.Invoke(true);
            float cps = Mathf.Max(_charsPerSecond, 1f);
            float acc = first;
            int announced = first;
            _text.maxVisibleCharacters = first;

            while (_text.maxVisibleCharacters <= last)
            {
                if (PointerInput.AdvancePressed)                 // click to finish this page now
                {
                    _text.maxVisibleCharacters = last + 1;
                    break;
                }
                acc += Time.deltaTime * cps;
                int shown = Mathf.Min(last, Mathf.FloorToInt(acc));
                _text.maxVisibleCharacters = shown + 1;
                for (; announced <= shown; announced++)
                    if (announced < info.characterCount) Typed?.Invoke(info.characterInfo[announced].character);
                yield return null;
            }

            _text.maxVisibleCharacters = last + 1;
            Speaking?.Invoke(false);
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
    }
}
