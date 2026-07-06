using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The outcome follows from the player's choice alone (the trolley). The struck party
    /// is fixed by the choice; the stats are reflective ("how others chose"), not load
    /// bearing on the outcome.
    /// </summary>
    public sealed class BinaryResolver : VerbResolver
    {
        public override DilemmaVerb Verb => DilemmaVerb.Binary;

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
