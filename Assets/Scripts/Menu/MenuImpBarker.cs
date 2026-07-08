using System;
using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The menu imp's cadence: it sits at its spot and every so often (a tunable pause, not often)
    /// says one short bark as plain ink text floating over it (no bubble), in its gleeful tormentor
    /// voice. The line types out with the blip voice, holds a moment, then the text clears, and ONLY
    /// THEN does the imp hop to a fresh spot (the springy roaming motion the campaign imp uses, via
    /// the roamer). So the loop is: pause, speak in place, text clears, hop, pause. A bark can carry a
    /// facial expression so a
    /// smug line shows a smug face (neutral otherwise, and only if the imp has expressions switched
    /// on). It only drives the floating text and the imp, never input, so the player can navigate and
    /// select at any time. One job: run the menu imp's speak-then-relocate loop. Keep each bark a
    /// single sentence.
    /// </summary>
    public sealed class MenuImpBarker : MonoBehaviour
    {
        [Serializable]
        private struct Bark
        {
            [TextArea(1, 2)] public string line;
            [Tooltip("The face this bark shows (only if the imp has expressions on). Grin is neutral.")]
            public ImpExpression expression;
        }

        [Header("References")]
        [SerializeField] private FloatingBarkText _bark;
        [SerializeField] private ImpFigure _imp;
        [SerializeField] private ImpRoamer _roamer;

        [Header("Barks (short one liners, editable)")]
        [Tooltip("Pulled at random, never the same twice running. Keep each to one sentence. " +
                 "No dashes in player-facing text.")]
        [SerializeField]
        private Bark[] _barks =
        {
            new Bark { line = "Still here, are we?",                                    expression = ImpExpression.Smug },
            new Bark { line = "You already know which one you will pick, and so do I.",  expression = ImpExpression.Smug },
            new Bark { line = "Take your time, no one is waiting for you now.",          expression = ImpExpression.Grin },
            new Bark { line = "A new game, as if the last one went so well for you.",    expression = ImpExpression.Glare },
            new Bark { line = "Go on, press something, I love to watch you decide.",     expression = ImpExpression.WideGrin },
            new Bark { line = "All this hovering, you were always a staller.",           expression = ImpExpression.Smug },
            new Bark { line = "Continue is greyed out, nothing back there for you.",     expression = ImpExpression.Grin },
            new Bark { line = "I can hear the little cogs grinding from here.",          expression = ImpExpression.WideGrin },
            new Bark { line = "Choose, or do not, it is all the same to me.",            expression = ImpExpression.Grin },
            new Bark { line = "You judged so many, and look who is squirming now.",      expression = ImpExpression.Glare },
        };

        [Header("Pacing")]
        [Tooltip("Wait this long after the menu appears before the first bark.")]
        [SerializeField] private float _firstDelay = 3f;
        [Tooltip("Gap between one teleport and the next bark (randomised in this range). Keep it unhurried.")]
        [SerializeField] private float _pauseMin = 5f;
        [SerializeField] private float _pauseMax = 9f;
        [Tooltip("Hold the finished line up this long before the text clears.")]
        [SerializeField] private float _holdAfterTyped = 2.2f;
        [Tooltip("The face the imp settles back to between barks.")]
        [SerializeField] private ImpExpression _restExpression = ImpExpression.Grin;
        [SerializeField] private bool _barking = true;

        private int _lastIndex = -1;

        private void OnEnable() { StartCoroutine(Loop()); }

        private IEnumerator Loop()
        {
            if (_bark == null || _barks == null || _barks.Length == 0) yield break;

            yield return new WaitForSeconds(_firstDelay);
            while (_barking)
            {
                Bark bark = Pick();

                if (_imp != null) _imp.SetExpression(bark.expression);
                _bark.Speak(bark.line);
                while (_bark.IsSpeaking) yield return null;        // let it ink on (a click only finishes it)
                yield return new WaitForSeconds(_holdAfterTyped);

                _bark.Hide();
                while (_bark.IsVisible) yield return null;         // wait for the text to clear
                if (_imp != null) _imp.SetExpression(_restExpression);

                if (_roamer != null) _roamer.HopToNewSpot();       // ONLY now does it move, a springy campaign hop
                yield return new WaitForSeconds(UnityEngine.Random.Range(_pauseMin, _pauseMax));
            }
        }

        // A random bark, never the last one again, so it does not repeat back to back.
        private Bark Pick()
        {
            if (_barks.Length == 1) return _barks[0];
            int i;
            do { i = UnityEngine.Random.Range(0, _barks.Length); } while (i == _lastIndex);
            _lastIndex = i;
            return _barks[i];
        }
    }
}
