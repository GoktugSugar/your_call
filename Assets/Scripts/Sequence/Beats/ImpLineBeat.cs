using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The guide speaks. One or more lines ink on through the reused NarratorView, which pages
    /// any line too long for the box; the player advances with a click or key, and the imp
    /// repositions on each new box. This is the "imp dialogue" beat: the narration between
    /// dilemmas and the whole opening monologue are just lists of these lines.
    /// </summary>
    public sealed class ImpLineBeat : SequenceBeat
    {
        [SerializeField, TextArea(2, 5)] private string[] _lines;

        [Header("Pacing")]
        [Tooltip("A click sooner than this after a line finishes is ignored, so one click never skips two boxes.")]
        [SerializeField] private float _clickLockout = 0.25f;
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

                    ctx.Narrator.Show(line);                        // types + pages, clicks turn its pages
                    while (ctx.Narrator.IsShowing) yield return null;

                    // Then a click or key advances past this box to the next line.
                    float t = 0f;
                    while (true)
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
