using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Menu flavour: every so often the imp says a short one liner, as if talking, through the
    /// reused <see cref="NarratorView"/> (so it inks into the dialogue box and the blip voice
    /// speaks it, and the roamer hops it to a fresh spot for the box). These are throwaway barks
    /// in the imp's gleeful tormentor voice, not a dilemma and not real conversation: a random line
    /// from an authored pool, never the same one twice running, held a moment, then cleared, with a
    /// tunable pause before the next. It only drives the narrator; menu navigation reads its own
    /// input, so the player can hover and select at any time and a bark never blocks. One job: keep
    /// the imp muttering. Keep each bark a single sentence so it fills one box (no click to page on).
    /// </summary>
    public sealed class MenuImpBarker : MonoBehaviour
    {
        [Header("Reference")]
        [SerializeField] private NarratorView _narrator;

        [Header("Barks (short one liners, editable)")]
        [Tooltip("Pulled at random, never the same twice running. Keep each to one sentence so it fits " +
                 "one box. No dashes in player-facing text.")]
        [SerializeField, TextArea(1, 2)]
        private string[] _barks =
        {
            "Still here, are we?",
            "You already know which one you will pick, and so do I.",
            "Take your time, no one is waiting for you now.",
            "A new game, as if the last one went so well for you.",
            "Go on, press something, I love to watch you decide.",
            "All this hovering, you were always a staller.",
            "Continue is greyed out, nothing back there for you.",
            "I can hear the little cogs grinding from here.",
            "Choose, or do not, it is all the same to me.",
            "You judged so many, and look who is squirming now.",
        };

        [Header("Pacing")]
        [Tooltip("Wait this long after the menu appears before the first bark.")]
        [SerializeField] private float _firstDelay = 3f;
        [Tooltip("Gap between one bark clearing and the next starting (randomised in this range).")]
        [SerializeField] private float _pauseMin = 4.5f;
        [SerializeField] private float _pauseMax = 8f;
        [Tooltip("Hold the finished line up this long before clearing it.")]
        [SerializeField] private float _holdAfterTyped = 2.4f;
        [SerializeField] private bool _barking = true;

        private int _lastIndex = -1;

        private void OnEnable() { StartCoroutine(Loop()); }

        private IEnumerator Loop()
        {
            if (_narrator == null || _barks == null || _barks.Length == 0) yield break;

            yield return new WaitForSeconds(_firstDelay);
            while (_barking)
            {
                _narrator.Show(Pick());
                while (_narrator.IsShowing) yield return null;    // let it ink on (a click only finishes it)
                yield return new WaitForSeconds(_holdAfterTyped);
                _narrator.Clear();
                yield return new WaitForSeconds(Random.Range(_pauseMin, _pauseMax));
            }
        }

        // A random bark, never the last one again, so it does not repeat back to back.
        private string Pick()
        {
            if (_barks.Length == 1) return _barks[0];
            int i;
            do { i = Random.Range(0, _barks.Length); } while (i == _lastIndex);
            _lastIndex = i;
            return _barks[i];
        }
    }
}
