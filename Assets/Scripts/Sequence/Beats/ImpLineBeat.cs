using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The guide speaks. One or more lines ink on through the reused NarratorView, each held
    /// long enough to read and then given way to the next; a click hurries it along. This is
    /// the "imp dialogue" beat: the narration between dilemmas and the whole opening monologue
    /// are just lists of these lines.
    /// </summary>
    public sealed class ImpLineBeat : SequenceBeat
    {
        [SerializeField, TextArea(2, 5)] private string[] _lines;

        [Header("Pacing")]
        [Tooltip("Base hold after a line finishes inking.")]
        [SerializeField] private float _holdBase = 1.0f;
        [Tooltip("Extra hold per character, so longer lines linger.")]
        [SerializeField] private float _holdPerChar = 0.028f;
        [Tooltip("A click sooner than this is ignored, so one click never skips two lines.")]
        [SerializeField] private float _clickLockout = 0.3f;
        [Tooltip("Clear the guide's words when the beat ends (otherwise the last line lingers).")]
        [SerializeField] private bool _clearAtEnd = false;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_lines != null)
            {
                for (int i = 0; i < _lines.Length; i++)
                {
                    string line = _lines[i];
                    if (string.IsNullOrEmpty(line)) continue;
                    ctx.Narrator.Show(line);
                    while (ctx.Narrator.IsShowing) yield return null;

                    float hold = _holdBase + line.Length * _holdPerChar;
                    float t = 0f;
                    while (t < hold)
                    {
                        t += Time.deltaTime;
                        if (t > _clickLockout && PointerInput.AdvancePressed) break;
                        yield return null;
                    }
                }
            }
            if (_clearAtEnd) ctx.Narrator.Clear();
        }
    }
}
