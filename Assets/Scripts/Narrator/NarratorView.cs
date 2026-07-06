using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The narrator's line in world space. It inks in (fades while the characters type
    /// on) rather than hard-cutting, so the words carry voice. No box, no panel: this is
    /// part of the scene, not a UI overlay (see docs/art-and-ui.md).
    /// </summary>
    public class NarratorView : MonoBehaviour
    {
        [SerializeField] private float _fontSize = 3.6f;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _width = 15f;
        [SerializeField] private int _sortingOrder = 20;
        [SerializeField] private float _fadeIn = 0.35f;
        [SerializeField] private float _charsPerSecond = 55f;

        private TextMeshPro _text;
        private Coroutine _routine;

        /// <summary>True while the line is still inking in, so the flow can wait for it.</summary>
        public bool IsShowing { get; private set; }

        private void Awake()
        {
            _text = InkText.Create(transform, "Line", _fontSize, _color, TextAlignmentOptions.Top, _sortingOrder);
            _text.rectTransform.sizeDelta = new Vector2(_width, 3f);
            InkText.SetAlpha(_text, 0f);
        }

        public void Show(string line)
        {
            if (_routine != null) StopCoroutine(_routine);
            IsShowing = true;
            _routine = StartCoroutine(Ink(line));
        }

        public void Clear()
        {
            if (_routine != null) StopCoroutine(_routine);
            IsShowing = false;
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
            int shown = 0;
            while (shown < total || t < fade)
            {
                t += Time.deltaTime;
                acc += Time.deltaTime * cps;
                shown = Mathf.Min(total, Mathf.FloorToInt(acc));
                _text.maxVisibleCharacters = shown;
                InkText.SetAlpha(_text, EaseUtil.Clamp01(t / fade));
                yield return null;
            }
            _text.maxVisibleCharacters = total;
            InkText.SetAlpha(_text, 1f);
            IsShowing = false;
        }
    }
}
