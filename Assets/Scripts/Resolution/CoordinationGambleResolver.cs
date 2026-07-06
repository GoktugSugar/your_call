namespace YourCall
{
    /// <summary>
    /// The outcome depends on a seeded crowd aggregate, not the player alone: the gambled
    /// party is spared only if the crowd's safe fraction reaches the threshold. This makes
    /// the "how the crowd chose" number load bearing, unlike the trolley's reflective bar.
    /// </summary>
    public sealed class CoordinationGambleResolver : VerbResolver
    {
        public override DilemmaVerb Verb => DilemmaVerb.CoordinationGamble;

        public override DilemmaOutcome Resolve(DilemmaContext c)
        {
            var outcome = new DilemmaOutcome();
            var chosen = c.Chosen;

            if (!string.IsNullOrEmpty(chosen.StruckParty)) outcome.StruckParties.Add(chosen.StruckParty);

            float frac = c.Dilemma.CrowdSafeFraction;
            float threshold = c.Dilemma.CrowdThreshold;
            bool crowdHeld = frac >= threshold;

            bool gambleStruck = false;
            if (!string.IsNullOrEmpty(chosen.GambledParty) && !crowdHeld)
            {
                outcome.StruckParties.Add(chosen.GambledParty);
                gambleStruck = true;
            }

            outcome.NarratorReact = (gambleStruck && !string.IsNullOrEmpty(chosen.NarratorReactStruck))
                ? chosen.NarratorReactStruck
                : chosen.NarratorReact;

            outcome.Report = BuildCrowdReport(c, frac, threshold);
            return outcome;
        }

        private static ResolutionReport BuildCrowdReport(DilemmaContext c, float frac, float threshold)
        {
            var r = new ResolutionReport
            {
                Heading = c.Dilemma.StatsHeading,
                MaxValue = 100f,
                HasThreshold = true,
                ThresholdValue = threshold * 100f,
                ThresholdLabel = c.Dilemma.ThresholdLabel
            };

            var choices = c.Dilemma.Choices;
            for (int i = 0; i < choices.Count; i++)
            {
                // The safe-aligned choice carries the crowd's safe fraction; the gamble the rest.
                bool isGamble = !string.IsNullOrEmpty(choices[i].GambledParty);
                float value = (isGamble ? (1f - frac) : frac) * 100f;
                r.Bars.Add(new StatBar(choices[i].Label, value, i == c.ChosenIndex));
            }
            return r;
        }
    }
}
