using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Pick one of several. Like <see cref="BinaryResolver"/> the outcome follows from the player's
    /// choice alone (the struck party is fixed by the pick) and the stats are reflective ("how others
    /// chose"), only there are N options rather than two. The everyday multiple-choice question type,
    /// and the three-track finish of Chapter 1. A distinct verb seam so the loop stays generic.
    /// </summary>
    public sealed class MultipleChoiceResolver : VerbResolver
    {
        public override DilemmaVerb Verb => DilemmaVerb.MultipleChoice;

        public override DilemmaOutcome Resolve(DilemmaContext c)
        {
            var outcome = new DilemmaOutcome();
            var chosen = c.Chosen;
            if (!string.IsNullOrEmpty(chosen.StruckParty)) outcome.StruckParties.Add(chosen.StruckParty);
            outcome.NarratorReact = chosen.NarratorReact;
            outcome.Report = BuildReflectiveReport(c);
            return outcome;
        }

        private static ResolutionReport BuildReflectiveReport(DilemmaContext c)
        {
            var r = new ResolutionReport { Heading = c.Dilemma.StatsHeading };
            var choices = c.Dilemma.Choices;
            float max = 1f;
            for (int i = 0; i < choices.Count; i++) max = Mathf.Max(max, choices[i].SeedVotes);
            r.MaxValue = max;
            for (int i = 0; i < choices.Count; i++)
                r.Bars.Add(new StatBar(choices[i].Label, choices[i].SeedVotes, i == c.ChosenIndex));
            return r;
        }
    }
}
