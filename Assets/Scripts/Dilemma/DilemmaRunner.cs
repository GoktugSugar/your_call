using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One dilemma's loop, in one place: present, choose, consequence, stats, then wait for
    /// an advance. Pure flow over the shared seams, with no verb branches and no scene
    /// management, so both the standalone <see cref="DilemmaStage"/> (which reloads after)
    /// and a sequenced <see cref="DilemmaBeat"/> (which moves to the next beat after) drive
    /// the exact same loop. It asks a <see cref="VerbResolver"/> for the outcome and a
    /// <see cref="ConsequencePresenter"/> to play it, and records the profile silently.
    /// </summary>
    public sealed class DilemmaRunner
    {
        private readonly Dilemma _dilemma;
        private readonly ConsequencePresenter _presenter;
        private readonly NarratorView _narrator;
        private readonly StatsView _stats;
        private readonly Profile _profile;
        private readonly ChoiceButtons _choices;   // null: no text fallback (diegetic only)
        private readonly DilemmaTiming _t;
        private readonly System.Func<DilemmaChoice, IEnumerator> _onEndsGame; // null: no ending choices

        private VerbResolver _resolver;
        private int _chosenIndex = -1;

        public DilemmaRunner(Dilemma dilemma, ConsequencePresenter presenter, NarratorView narrator,
            StatsView stats, Profile profile, ChoiceButtons choices, DilemmaTiming timing,
            System.Func<DilemmaChoice, IEnumerator> onEndsGame = null)
        {
            _dilemma = dilemma;
            _presenter = presenter;
            _narrator = narrator;
            _stats = stats;
            _profile = profile;
            _choices = choices;
            _t = timing;
            _onEndsGame = onEndsGame;
        }

        public DilemmaPhase Phase { get; private set; }

        public IEnumerator Run()
        {
            _resolver = VerbResolvers.For(_dilemma.Verb);
            _presenter.BuildScene(_dilemma);
            _presenter.Chosen += OnChosen;
            _presenter.ArmChoice(false);
            if (_choices != null) _choices.Chosen += OnChosen;

            try
            {
                // Present
                Phase = DilemmaPhase.Present;
                _narrator.Show(_dilemma.NarratorPrompt);
                while (_narrator.IsShowing) yield return null;
                yield return new WaitForSeconds(_t.PresentHold);

                // Choose
                Phase = DilemmaPhase.Choose;
                _presenter.ArmChoice(true);
                var choices = _dilemma.Choices;
                if (_choices != null)
                {
                    string l0 = choices.Count > 0 ? choices[0].Label : string.Empty;
                    string l1 = choices.Count > 1 ? choices[1].Label : string.Empty;
                    _choices.Present(l0, l1);
                }
                while (_chosenIndex < 0) yield return null;

                var choice = choices[_chosenIndex];
                _profile.Record(choice.ProfileImpact);          // silent; never drawn
                _presenter.OnCommitted(choice, _chosenIndex);
                yield return new WaitForSeconds(_t.PostChoiceBeat);

                // Consequence
                Phase = DilemmaPhase.Consequence;
                _narrator.Clear();
                var outcome = _resolver.Resolve(new DilemmaContext(_dilemma, _chosenIndex));
                yield return _presenter.PlayConsequence(choice, outcome);

                // A choice-triggered ending (the baby opener's kill choice): the consequence has landed;
                // hand off to the ending instead of the normal reaction and stats. The ending owns the
                // rest (the imp's break, then the credits, which reload the scene).
                if (choice.EndsGame && _onEndsGame != null)
                {
                    yield return _onEndsGame(choice);
                    yield break;
                }

                yield return new WaitForSeconds(_t.PreStatsBeat);

                // The choice and its consequence land first: the imp's reaction plays over the
                // world, then the player clicks (or keys) to continue. Only then does the room's
                // verdict appear, so the reaction and the stats never share a screen or a click.
                Phase = DilemmaPhase.Stats;
                _narrator.Show(outcome.NarratorReact);
                while (_narrator.IsShowing) yield return null;

                // Click gate: hold the reaction for at least ReactionHold (also a lockout against a
                // carried-over click), then wait for the continue click before revealing the stats.
                float gate = 0f;
                while (true)
                {
                    gate += Time.deltaTime;
                    if (gate > _t.ReactionHold && PointerInput.AdvancePressed) break;
                    yield return null;
                }
                _narrator.Clear();

                // The stats panel then presents alone and owns the input: one advance dismisses it.
                yield return _stats.Reveal(outcome.Report, _t.StatsFade);
                Phase = DilemmaPhase.End;
                yield return new WaitForSeconds(_t.EndInputDelay);
                while (!PointerInput.AdvancePressed) yield return null;
            }
            finally
            {
                _presenter.Chosen -= OnChosen;
                if (_choices != null) _choices.Chosen -= OnChosen;
            }
        }

        private void OnChosen(int index)
        {
            if (_chosenIndex >= 0) return;
            _chosenIndex = index;
            _presenter.ArmChoice(false);
            if (_choices != null) _choices.Dismiss();
        }
    }
}
