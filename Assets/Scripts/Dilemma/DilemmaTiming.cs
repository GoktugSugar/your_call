using System;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The tunable beats of one dilemma's loop, bundled so both the standalone
    /// <see cref="DilemmaStage"/> and a sequenced <see cref="DilemmaBeat"/> can expose and
    /// hand the same timings to the shared <see cref="DilemmaRunner"/>. Defaults match the
    /// original stage values.
    /// </summary>
    [Serializable]
    public struct DilemmaTiming
    {
        [Tooltip("Held pause after the prompt finishes inking, before the choice arms.")]
        public float PresentHold;
        [Tooltip("Beat after a choice is committed, before the consequence plays.")]
        public float PostChoiceBeat;
        [Tooltip("Beat after the consequence, before the stats ink in.")]
        public float PreStatsBeat;
        [Tooltip("Fade used to dim the world for the stats tableau.")]
        public float StatsFade;
        [Tooltip("Input lockout after the stats appear, before an advance is accepted.")]
        public float EndInputDelay;

        public static DilemmaTiming Default => new DilemmaTiming
        {
            PresentHold = 0.7f,
            PostChoiceBeat = 0.45f,
            PreStatsBeat = 0.9f,
            StatsFade = 0.5f,
            EndInputDelay = 0.5f,
        };
    }
}
