using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// He comes to. The game is his own point of view, so there is no body to show: the
    /// disorientation is carried by the black wash clearing unevenly (a glimpse, slipping
    /// back under, then settling open) and by the view drifting and steadying, as if the
    /// eyes are focusing. Brief, and it hands straight to the imp resolving into being.
    /// No figure, no amber; just the wash and the camera.
    /// </summary>
    public sealed class VoidWakeBeat : SequenceBeat
    {
        [Header("Waking")]
        [Tooltip("Hold on black before he starts to come to.")]
        [SerializeField] private float _preDelay = 0.5f;
        [Tooltip("How long the woozy clearing takes.")]
        [SerializeField] private float _wakeDuration = 2.8f;
        [SerializeField] private float _holdAfter = 0.35f;

        [Header("Uneven wash")]
        [Tooltip("Strength of the flicker superimposed on the fade, so it clears unevenly.")]
        [SerializeField, Range(0f, 0.5f)] private float _washFlicker = 0.18f;
        [Tooltip("How many times consciousness swims before it settles.")]
        [SerializeField] private float _washFlickerCycles = 3.5f;

        [Header("Settling view")]
        [Tooltip("How far the point of view drifts before it steadies.")]
        [SerializeField] private float _settleSway = 0.35f;
        [SerializeField] private float _settleFreqX = 0.7f;
        [SerializeField] private float _settleFreqY = 0.45f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            var fade = ctx.Fade;
            var cam = ctx.Camera;
            Vector3 camBase = cam != null ? cam.transform.position : Vector3.zero;

            if (fade != null) fade.SetAlpha(1f);   // the crash left the screen black
            if (_preDelay > 0f) yield return new WaitForSeconds(_preDelay);

            float t = 0f, d = Mathf.Max(_wakeDuration, 0.1f);
            const float tau = Mathf.PI * 2f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.Clamp01(t / d);

                if (fade != null)
                {
                    // A smooth fall from black, with a decaying flicker so it swims open.
                    float fall = 1f - EaseUtil.SmoothStep(k);
                    float flicker = Mathf.Sin(k * Mathf.PI * _washFlickerCycles) * _washFlicker * (1f - k);
                    fade.SetAlpha(EaseUtil.Clamp01(fall + flicker));
                }

                if (cam != null)
                {
                    float decay = (1f - k) * (1f - k);
                    float ox = Mathf.Sin(t * _settleFreqX * tau) * _settleSway * decay;
                    float oy = Mathf.Cos(t * _settleFreqY * tau) * _settleSway * 0.6f * decay;
                    cam.transform.position = camBase + new Vector3(ox, oy, 0f);
                }
                yield return null;
            }

            if (fade != null) fade.SetAlpha(0f);
            if (cam != null) cam.transform.position = camBase;
            if (_holdAfter > 0f) yield return new WaitForSeconds(_holdAfter);
        }
    }
}
