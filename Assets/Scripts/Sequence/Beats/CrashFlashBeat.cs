using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The death, half remembered: a few quick ink flashes over black (lights bearing down, a
    /// swerve, the hit), a jolt, then a cut to black. The waking beat clears the black into the
    /// void, so the dissolve reads as him coming to. Impressionistic and cheap on purpose,
    /// fragmentary because he barely has it himself. The flashes are pale ink on the dark wash,
    /// so nothing colour enters and the amber stays reserved.
    /// </summary>
    public sealed class CrashFlashBeat : SequenceBeat
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _motifColor = new Color(0.93f, 0.92f, 0.88f, 1f);
        [SerializeField] private float _lineWidth = 0.06f;
        [SerializeField] private int _sortingOrder = 95;
        [SerializeField] private Color _darkColor = Color.black;

        [Header("Timing")]
        [SerializeField] private float _darkHold = 0.7f;
        [SerializeField] private float _lightsDur = 0.55f;
        [SerializeField] private float _swerveDur = 0.5f;
        [SerializeField] private float _impactDur = 0.5f;
        [SerializeField] private float _gapDur = 0.08f;
        [SerializeField] private float _holdBlack = 0.6f;

        [Header("Impact")]
        [SerializeField] private float _shakeAmp = 0.35f;

        private Transform _container;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Fade != null) ctx.Fade.Cover(_darkColor);

            _container = new GameObject("CrashFlash").transform;
            if (ctx.Camera != null) _container.SetParent(ctx.Camera.transform, false);
            _container.localPosition = new Vector3(0f, 0f, 1f);

            yield return new WaitForSeconds(_darkHold);
            yield return Headlights();
            yield return new WaitForSeconds(_gapDur);
            yield return Swerve();
            yield return new WaitForSeconds(_gapDur);
            yield return Impact();

            // Cut to black and hold. The waking beat owns the clear into the void, so the
            // dissolve reads as him coming to rather than a scene transition.
            if (ctx.Fade != null)
            {
                ctx.Fade.Cover(_darkColor);
                yield return new WaitForSeconds(_holdBlack);
            }

            if (_container != null) Destroy(_container.gameObject);
        }

        // ---------- Motifs ----------

        private IEnumerator Headlights()
        {
            var motif = NewMotif("Headlights");
            var strokes = new List<LineRenderer>();
            strokes.Add(Ring(motif, "GlareL", new Vector2(-0.75f, 0.25f), 0.32f));
            strokes.Add(Ring(motif, "GlareR", new Vector2(0.75f, 0.25f), 0.32f));
            // A few glare spokes off each light.
            for (int i = 0; i < 4; i++)
            {
                float a = 20f + i * 40f;
                strokes.Add(Spoke(motif, "SpokeL" + i, new Vector2(-0.75f, 0.25f), a, 0.18f, 0.5f));
                strokes.Add(Spoke(motif, "SpokeR" + i, new Vector2(0.75f, 0.25f), 180f - a, 0.18f, 0.5f));
            }
            yield return FlashMotif(motif, strokes, _lightsDur, 0.5f, 1.9f, 0f, 0f);
            Destroy(motif.gameObject);
        }

        private IEnumerator Swerve()
        {
            var motif = NewMotif("Swerve");
            var strokes = new List<LineRenderer>();
            var arc = new List<Vector3>();
            for (int i = 0; i <= 24; i++)
            {
                float t = i / 24f;
                float x = Mathf.Lerp(-3.4f, 3.4f, t);
                float y = -1.2f + Mathf.Sin(t * Mathf.PI) * 1.4f;
                arc.Add(new Vector3(x, y, 0f));
            }
            strokes.Add(Poly(motif, "Horizon", arc));
            strokes.Add(Poly(motif, "SkidA", new List<Vector3> { new Vector3(-1.6f, -1.9f, 0f), new Vector3(0.2f, -1.2f, 0f) }));
            strokes.Add(Poly(motif, "SkidB", new List<Vector3> { new Vector3(-1.2f, -2.2f, 0f), new Vector3(0.6f, -1.5f, 0f) }));
            yield return FlashMotif(motif, strokes, _swerveDur, 1f, 1.08f, -8f, 0f);
            Destroy(motif.gameObject);
        }

        private IEnumerator Impact()
        {
            var motif = NewMotif("Impact");
            var strokes = new List<LineRenderer>();
            int spikes = 11;
            for (int i = 0; i < spikes; i++)
            {
                float a = i * (360f / spikes) + (i % 2 == 0 ? 0f : 8f);
                float len = (i % 2 == 0) ? 2.1f : 1.3f;
                strokes.Add(Spoke(motif, "Spike" + i, Vector2.zero, a, 0.2f, len));
            }
            yield return FlashMotif(motif, strokes, _impactDur, 0.5f, 1.35f, 0f, _shakeAmp);
            Destroy(motif.gameObject);
        }

        // ---------- Helpers ----------

        private Transform NewMotif(string name)
        {
            var go = new GameObject(name);
            go.transform.SetParent(_container, false);
            return go.transform;
        }

        private LineRenderer Ring(Transform parent, string name, Vector2 c, float r)
        {
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, c, r, 0f, 360f, 20);
            return Poly(parent, name, pts);
        }

        private LineRenderer Spoke(Transform parent, string name, Vector2 c, float deg, float from, float to)
        {
            float rad = deg * Mathf.Deg2Rad;
            var dir = new Vector3(Mathf.Cos(rad), Mathf.Sin(rad), 0f);
            return Poly(parent, name, new List<Vector3> { (Vector3)c + dir * from, (Vector3)c + dir * to });
        }

        private LineRenderer Poly(Transform parent, string name, IList<Vector3> pts)
        {
            var lr = InkLine.Create(parent, name, _inkMaterial, _lineWidth, _motifColor, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            return lr;
        }

        private IEnumerator FlashMotif(Transform motif, List<LineRenderer> strokes, float dur,
            float scaleFrom, float scaleTo, float spin, float shakeAmp)
        {
            float t = 0f, d = Mathf.Max(dur, 0.05f);
            var basePos = _container != null ? _container.localPosition : Vector3.zero;
            while (t < d)
            {
                t += Time.deltaTime;
                float p = EaseUtil.Clamp01(t / d);
                float a;
                if (p < 0.2f) a = p / 0.2f;
                else if (p < 0.55f) a = 1f;
                else a = 1f - (p - 0.55f) / 0.45f;

                for (int i = 0; i < strokes.Count; i++)
                    if (strokes[i] != null) InkLine.SetAlpha(strokes[i], _motifColor, EaseUtil.Clamp01(a));

                float s = Mathf.Lerp(scaleFrom, scaleTo, EaseUtil.OutCubic(p));
                motif.localScale = new Vector3(s, s, 1f);
                motif.localRotation = Quaternion.Euler(0f, 0f, spin * p);

                if (shakeAmp > 0f && _container != null)
                {
                    float decay = 1f - p;
                    _container.localPosition = basePos + (Vector3)(Random.insideUnitCircle * (shakeAmp * decay));
                }
                yield return null;
            }
            if (shakeAmp > 0f && _container != null) _container.localPosition = basePos;
        }
    }
}
