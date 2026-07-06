using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The guide scribbles into being. A tiny cutscene beat that just plays the imp's pop in,
    /// so its entrance is one clear moment rather than a line of text. The imp persists after.
    /// </summary>
    public sealed class ImpAppearBeat : SequenceBeat
    {
        [SerializeField] private float _preDelay = 0.3f;
        [SerializeField] private float _popDuration = 0.55f;
        [SerializeField] private float _postDelay = 0.35f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Imp == null) yield break;
            if (!ctx.Imp.gameObject.activeSelf) ctx.Imp.gameObject.SetActive(true);
            if (_preDelay > 0f) yield return new WaitForSeconds(_preDelay);
            yield return ctx.Imp.PopIn(_popDuration);
            if (_postDelay > 0f) yield return new WaitForSeconds(_postDelay);
        }
    }
}
