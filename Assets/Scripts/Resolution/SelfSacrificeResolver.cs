namespace YourCall
{
    /// <summary>
    /// Seam for the self-sacrifice verb (a cost to the player's own standing, reserved for
    /// late-game climaxes). Not built yet: apply the cost to how the player is judged here
    /// when that verb lands. See docs/gameplay.md.
    /// </summary>
    public sealed class SelfSacrificeResolver : VerbResolver
    {
        public override DilemmaVerb Verb => DilemmaVerb.SelfSacrifice;

        public override DilemmaOutcome Resolve(DilemmaContext c)
        {
            // TODO(self-sacrifice): apply the cost to the player's standing / how they are judged.
            var outcome = new DilemmaOutcome();
            var chosen = c.Chosen;
            if (!string.IsNullOrEmpty(chosen.StruckParty)) outcome.StruckParties.Add(chosen.StruckParty);
            outcome.NarratorReact = chosen.NarratorReact;
            return outcome;
        }
    }
}
