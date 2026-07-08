using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The quick, light consequence for an everyday no-right-answer question (a would-you-rather,
    /// a matter of taste, an absurd hypothetical). No apparatus and nobody folds: just a brief ink
    /// flourish so even a light question resolves into a small drawn moment rather than plain text
    /// (see docs/art-and-ui.md). The player answers through the shared text <see cref="ChoiceButtons"/>,
    /// so this presenter owns no diegetic input. It keeps no per question state, so a single instance
    /// is reused by every light question in a sequence. One job: play the light beat.
    /// </summary>
    public sealed class LightChoiceConsequence : ConsequencePresenter
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("The accent, on the light beat (amber is attention and consequence; see art-and-ui.md).")]
        [SerializeField] private Color _color = Palette.Amber;

        [Header("Flourish")]
        [Tooltip("World-space point the brief ink burst plays at.")]
        [SerializeField] private Vector2 _anchor = new Vector2(0f, 0.6f);
        [SerializeField] private float _radius = 0.7f;
        [SerializeField, Range(3, 24)] private int _strokes = 9;
        [SerializeField] private float _strokeWidth = 0.05f;
        [SerializeField] private int _sortingOrder = 14;

        [Header("Timing (scaled by weight)")]
        [SerializeField] private float _lightDuration = 0.7f;
        [SerializeField] private float _mediumDuration = 1.0f;
        [SerializeField] private float _heavyDuration = 1.4f;
        [Tooltip("A small held beat after the flourish, before the imp's reaction.")]
        [SerializeField] private float _settle = 0.15f;

        private Dilemma _dilemma;

        public override void BuildScene(Dilemma dilemma) { _dilemma = dilemma; }

        // No diegetic apparatus: the player answers through the shared text choices, so nothing to arm.
        public override void ArmChoice(bool on) { }

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            float dur = DurationFor(_dilemma != null ? _dilemma.Weight : DilemmaWeight.Light);
            if (_inkMaterial != null)
                InkPoof.Spawn(new Vector3(_anchor.x, _anchor.y, 0f), _inkMaterial, _color,
                    _radius, dur, _strokes, _strokeWidth, _sortingOrder);
            yield return new WaitForSeconds(dur + _settle);
        }

        private float DurationFor(DilemmaWeight weight)
        {
            switch (weight)
            {
                case DilemmaWeight.Medium: return _mediumDuration;
                case DilemmaWeight.Heavy: return _heavyDuration;
                default: return _lightDuration;
            }
        }
    }
}
