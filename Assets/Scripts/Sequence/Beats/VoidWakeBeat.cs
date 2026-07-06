using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The player comes to: a lone ink figure inks into the empty void and sways, foggy and
    /// half remembering, before it steadies. Brief by design; the disorientation is carried
    /// by the unsteady lean, not by time. The avatar is the reused Figure, built hidden.
    /// </summary>
    public sealed class VoidWakeBeat : SequenceBeat
    {
        [SerializeField] private Figure _avatar;

        [Header("Waking")]
        [SerializeField] private float _preDelay = 0.4f;
        [SerializeField] private float _fadeIn = 1.6f;
        [Tooltip("How far the figure lists while coming to.")]
        [SerializeField] private float _swayAngle = 9f;
        [SerializeField] private float _swayPeriod = 1.5f;
        [SerializeField] private float _settle = 0.7f;
        [SerializeField] private float _holdAfter = 0.5f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_avatar == null) yield break;
            if (!_avatar.gameObject.activeSelf) _avatar.gameObject.SetActive(true);
            _avatar.SetInkAlpha(0f);
            var tr = _avatar.transform;
            var baseRot = tr.localRotation;

            if (_preDelay > 0f) yield return new WaitForSeconds(_preDelay);

            // Ink in while listing unsteadily.
            float t = 0f, d = Mathf.Max(_fadeIn, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                _avatar.SetInkAlpha(k);
                float sway = Mathf.Sin(t * (Mathf.PI * 2f / Mathf.Max(_swayPeriod, 0.01f))) * _swayAngle * (1f - k * 0.5f);
                tr.localRotation = baseRot * Quaternion.Euler(0f, 0f, sway);
                yield return null;
            }
            _avatar.SetInkAlpha(1f);

            // Steady onto its feet.
            float s = 0f, sd = Mathf.Max(_settle, 0.05f);
            var from = tr.localRotation;
            while (s < sd)
            {
                s += Time.deltaTime;
                tr.localRotation = Quaternion.Slerp(from, baseRot, EaseUtil.OutCubic(s / sd));
                yield return null;
            }
            tr.localRotation = baseRot;
            if (_holdAfter > 0f) yield return new WaitForSeconds(_holdAfter);
        }
    }
}
