namespace YourCall
{
    /// <summary>One bar on the aftermath stats screen. Verb-agnostic display data.</summary>
    public struct StatBar
    {
        public string Label;
        public float Value;
        public bool IsPick;

        public StatBar(string label, float value, bool isPick)
        {
            Label = label;
            Value = value;
            IsPick = isPick;
        }
    }
}
