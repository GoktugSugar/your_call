using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The outcome depends on a seeded crowd aggregate, not the player alone: the gambled
    /// party is spared only if the room's blue fraction reaches the threshold. In the
    /// blue/red button dilemma the gamble is the blue button, so the room's blue fraction is
    /// the load-bearing number and the gamble bar carries it. This makes "how the room voted"
    /// load bearing, unlike the trolley's reflective bar.
    /// </summary>
    public sealed class CoordinationGambleResolver : VerbResolver
    {
        public override DilemmaVerb Verb => DilemmaVerb.CoordinationGamble;

        public override DilemmaOutcome Resolve(DilemmaContext c)
        {
            var outcome = new DilemmaOutcome();
            var chosen = c.Chosen;

            if (!string.IsNullOrEmpty(chosen.StruckParty)) outcome.StruckParties.Add(chosen.StruckParty);

            float blueFraction = c.Dilemma.RoomBlueFraction;
            float threshold = c.Dilemma.CrowdThreshold;
            bool blueReachedThreshold = blueFraction >= threshold;

            bool gambleStruck = false;
            if (!string.IsNullOrEmpty(chosen.GambledParty) && !blueReachedThreshold)
            {
                outcome.StruckParties.Add(chosen.GambledParty);
                gambleStruck = true;
            }

            outcome.NarratorReact = (gambleStruck && !string.IsNullOrEmpty(chosen.NarratorReactStruck))
                ? chosen.NarratorReactStruck
                : chosen.NarratorReact;

            outcome.Report = BuildRoomReport(c, blueFraction, threshold);
            return outcome;
        }

        private static ResolutionReport BuildRoomReport(DilemmaContext c, float blueFraction, float threshold)
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
                // Blue is the gamble here, so the gamble button's share of the room is the
                // blue fraction and the safe (red) button's share is the rest.
                bool isGamble = !string.IsNullOrEmpty(choices[i].GambledParty);
                float value = (isGamble ? blueFraction : (1f - blueFraction)) * 100f;
                var bar = new StatBar(choices[i].Label, value, i == c.ChosenIndex);
                bar.Tint = isGamble ? Palette.InkBlue : Palette.InkRed;
                r.Bars.Add(bar);
            }
            return r;
        }
    }
}
