using System.Collections.Generic;

namespace YourCall
{
    /// <summary>
    /// Everything the aftermath stats screen needs to ink in, produced by the resolver so
    /// StatsView never has to know which verb it is showing. The optional threshold marker
    /// is what makes the coordination gamble's number read as load bearing, not reflective.
    /// </summary>
    public sealed class ResolutionReport
    {
        public string Heading;
        public readonly List<StatBar> Bars = new List<StatBar>();
        public float MaxValue = 1f;

        public bool HasThreshold;
        public float ThresholdValue;
        public string ThresholdLabel;
    }
}
