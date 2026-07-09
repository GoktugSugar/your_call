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

            float blueFraction = EffectiveBlueFraction(c.Dilemma);
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

        /// <summary>
        /// The blue fraction the gamble resolves against. Normally the seeded value straight off the
        /// dilemma (deterministic, offline-first). For the children variant a share of the room
        /// (<see cref="Dilemma.CrowdRandomFraction"/>) are six year olds pressing at random: that share
        /// is drawn as a fresh coin toss each play and blended with the seeded (adult) lean, so the blue
        /// fraction is genuinely noisier and the gamble is a real gamble, not a fixed outcome. Computed
        /// once per resolve, so the outcome and the stat the player is shown always agree. With a random
        /// fraction of 0 (every other dilemma) this returns the seeded value unchanged.
        /// </summary>
        private static float EffectiveBlueFraction(Dilemma d)
        {
            float seeded = d.RoomBlueFraction;
            float randomFraction = Mathf.Clamp01(d.CrowdRandomFraction);
            if (randomFraction <= 0f) return seeded;
            float cluelessBlue = Random.value;   // the kids: who knows which button they hit
            return Mathf.Clamp01((1f - randomFraction) * seeded + randomFraction * cluelessBlue);
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
