using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One beat of a narrative sequence: a cutscene, a line of the guide, or a whole
    /// dilemma. Each concrete beat is a small single-purpose component; the
    /// <see cref="SequencePlayer"/> plays them in order and never needs to know which kind
    /// it is holding. Beats communicate only through their coroutine finishing.
    /// </summary>
    public abstract class SequenceBeat : MonoBehaviour
    {
        [Tooltip("Optional label for logs and readability; not shown to the player.")]
        [SerializeField] private string _note;

        public string Note => string.IsNullOrEmpty(_note) ? GetType().Name : _note;

        /// <summary>Play this beat to completion. The player waits on the returned routine.</summary>
        public abstract IEnumerator Play(SequenceContext ctx);
    }
}
