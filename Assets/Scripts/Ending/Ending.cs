using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A minimal, reusable ending: optionally a line (shown in the narrator's box), then an effect
    /// (any coroutine, for example fading a figure), then the credits roll. The real profile-based
    /// endings can reuse this same shape later. Keep it small: it only sequences the three steps.
    /// </summary>
    public sealed class Ending : MonoBehaviour
    {
        [SerializeField] private CreditsRoll _credits;
        [Tooltip("Hold after the line finishes, before the effect.")]
        [SerializeField] private float _lineHold = 1.0f;

        /// <summary>Play the ending: line (optional) then effect (optional) then the credits roll.</summary>
        public IEnumerator Play(NarratorView narrator, string line, IEnumerator effect)
        {
            if (narrator != null && !string.IsNullOrEmpty(line))
            {
                narrator.Show(line);
                while (narrator.IsShowing) yield return null;
                yield return new WaitForSeconds(_lineHold);
            }
            if (effect != null) yield return effect;
            if (narrator != null) narrator.Clear();
            if (_credits != null) yield return _credits.Play();
        }
    }
}
