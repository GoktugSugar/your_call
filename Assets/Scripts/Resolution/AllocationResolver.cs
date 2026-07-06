namespace YourCall
{
    /// <summary>
    /// Seam for the allocation verb (divide or ration a limited good among parties).
    /// Not built yet: when that verb lands, partition the good here and strike the
    /// under-allocated parties. See docs/gameplay.md.
    /// </summary>
    public sealed class AllocationResolver : VerbResolver
    {
        public override DilemmaVerb Verb => DilemmaVerb.Allocation;

        public override DilemmaOutcome Resolve(DilemmaContext c)
        {
            // TODO(allocation): partition the limited good and strike the under-allocated parties.
            var outcome = new DilemmaOutcome();
            var chosen = c.Chosen;
            if (!string.IsNullOrEmpty(chosen.StruckParty)) outcome.StruckParties.Add(chosen.StruckParty);
            outcome.NarratorReact = chosen.NarratorReact;
            return outcome;
        }
    }
}
