using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A short line of ink floating over a figure, with no bubble, box, tail or background, just the
    /// words on the paper, the same treatment the menu imp's barks use (see docs/art-and-ui.md). The
    /// Begging trolley uses it for the lone soul's plea. Fades on and off; one instance per station,
    /// pointed at whichever figure is pleading. One job: float a line over a spot.
    /// </summary>
    public sealed class FloatingFigureText : MonoBehaviour
    {
        [Header("Type (Caveat, consistent with the narration)")]
        [SerializeField] private TMP_FontAsset _font;
        [SerializeField] private float _fontSize = 2.4f;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private int _sortingOrder = 24;
        [SerializeField] private float _width = 5.5f;

        [Tooltip("How far above the figure's origin the plea floats.")]
        [SerializeField] private float _heightAboveFigure = 1.25f;
        [SerializeField] private float _fade = 0.35f;

        private TextMeshPro _text;
        private Coroutine _routine;
        private bool _built;

        private void Awake() { Build(); }

        private void Build()
        {
            if (_built) return;
            _text = InkText.Create(transform, "Plea", _fontSize, _color, TextAlignmentOptions.Center, _sortingOrder);
            if (_font != null) _text.font = _font;
            _text.rectTransform.sizeDelta = new Vector2(_width, 1.4f);
            _text.enableWordWrapping = true;
            InkText.SetAlpha(_text, 0f);
            _built = true;
        }

        /// <summary>Float the line over a world anchor (the pleading figure's position) and fade it in.</summary>
        public void Show(string line, Vector3 figureWorldPos)
        {
            if (!_built) Build();
            if (string.IsNullOrEmpty(line)) { Hide(); return; }
            _text.transform.position = figureWorldPos + new Vector3(0f, _heightAboveFigure, 0f);
            _text.text = Localization.Localize(line);
            if (_routine != null) StopCoroutine(_routine);
            _routine = StartCoroutine(FadeTo(1f));
        }

        public void Hide()
        {
            if (!_built) return;
            if (_routine != null) StopCoroutine(_routine);
            _routine = StartCoroutine(FadeTo(0f));
        }

        private IEnumerator FadeTo(float target)
        {
            float from = _text.color.a, t = 0f, d = Mathf.Max(_fade, 0.01f);
            while (t < d) { t += Time.deltaTime; InkText.SetAlpha(_text, Mathf.Lerp(from, target, t / d)); yield return null; }
            InkText.SetAlpha(_text, target);
        }
    }
}
