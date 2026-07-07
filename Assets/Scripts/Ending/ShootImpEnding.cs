using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The secret shoot-the-imp ending. Listens for <see cref="ShootingConsequence.ImpShot"/> (the
    /// player firing the crosshair on the imp), then runs the reusable <see cref="Ending"/>: the imp
    /// swears its one line, fades away, and the credits roll. The gunshot itself is played by the
    /// shooting input on the trigger pull. One job: turn "shot the imp" into the ending, wired through
    /// the existing shooting input and the reusable ending, with no branches bolted into the dilemma loop.
    /// </summary>
    public sealed class ShootImpEnding : MonoBehaviour
    {
        [SerializeField] private ShootingConsequence _shooting;
        [SerializeField] private ImpFigure _imp;
        [SerializeField] private NarratorView _narrator;
        [SerializeField] private Ending _ending;
        [Tooltip("The text choices to dismiss when the imp is shot, so nothing else resolves under the ending.")]
        [SerializeField] private ChoiceButtons _choices;
        [SerializeField, TextArea] private string _line = "What the fuck are you doing, asshole";
        [SerializeField] private float _impFadeDuration = 0.8f;

        private bool _triggered;

        private void OnEnable() { if (_shooting != null) _shooting.ImpShot += OnImpShot; }
        private void OnDisable() { if (_shooting != null) _shooting.ImpShot -= OnImpShot; }

        private void OnImpShot()
        {
            if (_triggered || _ending == null) return;
            _triggered = true;
            if (_choices != null) _choices.Dismiss();                        // no stray resolution under the ending
            if (_imp != null)
            {
                var roamer = _imp.GetComponent<ImpRoamer>();
                if (roamer != null) roamer.enabled = false;                  // the shot imp holds still for its last word
            }
            StartCoroutine(_ending.Play(_narrator, _line, FadeImp()));
        }

        private IEnumerator FadeImp()
        {
            if (_imp == null) yield break;
            float d = Mathf.Max(_impFadeDuration, 0.05f), t = 0f;
            while (t < d) { t += Time.deltaTime; _imp.SetAlpha(1f - t / d); yield return null; }
            _imp.SetAlpha(0f);
        }
    }
}
