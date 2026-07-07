using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Quietly ink a figure in or out (no fold, no strike): a small, general sequence tool for
    /// any figure that should appear or withdraw between beats, without the Figure's fold.
    /// </summary>
    public sealed class FigureFadeBeat : SequenceBeat
    {
        [SerializeField] private Figure _figure;
        [SerializeField] private bool _fadeIn = false;
        [SerializeField] private float _duration = 1.0f;
        [SerializeField] private float _preDelay = 0.0f;
        [Tooltip("Deactivate the figure's GameObject once it has faded out.")]
        [SerializeField] private bool _deactivateAtEnd = true;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_figure == null) yield break;
            if (_preDelay > 0f) yield return new WaitForSeconds(_preDelay);
            if (_fadeIn && !_figure.gameObject.activeSelf) _figure.gameObject.SetActive(true);

            float t = 0f, d = Mathf.Max(_duration, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                _figure.SetInkAlpha(_fadeIn ? k : 1f - k);
                yield return null;
            }
            _figure.SetInkAlpha(_fadeIn ? 1f : 0f);
            if (!_fadeIn && _deactivateAtEnd) _figure.gameObject.SetActive(false);
        }
    }
}
