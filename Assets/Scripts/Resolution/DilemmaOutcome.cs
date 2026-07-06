using System.Collections.Generic;

namespace YourCall
{
    /// <summary>
    /// The result of resolving a choice: which parties fold, the narrator reaction to
    /// show, and the stats report. The presenter maps party ids to its figures.
    /// </summary>
    public sealed class DilemmaOutcome
    {
        public readonly List<string> StruckParties = new List<string>();
        public string NarratorReact;
        public ResolutionReport Report;

        public bool AnyStruck => StruckParties.Count > 0;

        public bool Strikes(string party) => StruckParties.Contains(party);
    }
}
