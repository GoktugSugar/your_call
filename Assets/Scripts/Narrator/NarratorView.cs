using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The narrator's line in world space. It inks in (fades while the characters type
    /// on) rather than hard-cutting, so the words carry voice. It draws no chrome of its
    /// own; a separate DialogueBox may frame it in the ink style (see docs/art-and-ui.md).
    /// It raises small events (Speaking, Typed) so the imp and its blip voice can react.
    /// </summary>
    public class NarratorView : MonoBehaviour
    {
        [SerializeField] private float _fontSize = 3.6f;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _width = 15f;
        [SerializeField] private float _height = 3f;
        [SerializeField] private int _sortingOrder = 20;
        [SerializeField] private float _fadeIn = 0.35f;
        [SerializeField] private float _charsPerSecond = 70f;

        private TextMeshPro _text;
        private Coroutine _routine;

        /// <summary>True while the line is still inking in, so the flow can wait for it.</summary>
        public bool IsShowing { get; private set; }

        /// <summary>
        /// Raised true when a line starts inking on and false when it finishes or clears, so
        /// a speaker (the imp) can stir while the words appear. The narrator stays generic;
        /// whoever embodies the voice listens.
        /// </summary>
        public event System.Action<bool> Speaking;

        /// <summary>Raised for each character as it inks on (the actual char, so a voice can
        /// skip whitespace). A gibberish-blip voice listens; the narrator stays text only.</summary>
        public event System.Action<char> Typed;

        /// <summary>True from Show until Clear (a line is on screen, even after it finishes
        /// typing), so a frame can appear with the words and leave when they clear.</summary>
        public bool HasLine { get; private set; }

        private void Awake()
        {
            _text = InkText.Create(transform, "Line", _fontSize, _color, TextAlignmentOptions.Top, _sortingOrder);
            _text.rectTransform.sizeDelta = new Vector2(_width, _height);
            InkText.SetAlpha(_text, 0f);
        }

        public void Show(string line)
        {
            if (_routine != null) StopCoroutine(_routine);
            IsShowing = true;
            HasLine = true;
            Speaking?.Invoke(true);
            _routine = StartCoroutine(Ink(line));
        }

        public void Clear()
        {
            if (_routine != null) StopCoroutine(_routine);
            IsShowing = false;
            HasLine = false;
            Speaking?.Invoke(false);
            if (_text != null) { _text.text = string.Empty; InkText.SetAlpha(_text, 0f); }
        }

        private IEnumerator Ink(string line)
        {
            _text.text = line;
            _text.ForceMeshUpdate();
            int total = _text.textInfo.characterCount;
            _text.maxVisibleCharacters = 0;

            float cps = Mathf.Max(_charsPerSecond, 1f);
            float fade = Mathf.Max(_fadeIn, 0.0001f);
            float t = 0f, acc = 0f;
            int shown = 0, announced = 0;
            while (shown < total || t < fade)
            {
                t += Time.deltaTime;
                acc += Time.deltaTime * cps;
                shown = Mathf.Min(total, Mathf.FloorToInt(acc));
                _text.maxVisibleCharacters = shown;
                for (; announced < shown; announced++)
                    if (announced < line.Length) Typed?.Invoke(line[announced]);
                InkText.SetAlpha(_text, EaseUtil.Clamp01(t / fade));
                yield return null;
            }
            _text.maxVisibleCharacters = total;
            InkText.SetAlpha(_text, 1f);
            IsShowing = false;
            Speaking?.Invoke(false);
        }
    }
}
