using UnityEngine;

namespace YourCall
{
    /// <summary>One bar on the aftermath stats screen. Verb-agnostic display data.</summary>
    public struct StatBar
    {
        public string Label;
        public float Value;
        public bool IsPick;

        /// <summary>Optional bar colour (the blue/red button dilemma). Null means ink.</summary>
        public Color? Tint;

        public StatBar(string label, float value, bool isPick)
        {
            Label = label;
            Value = value;
            IsPick = isPick;
            Tint = null;
        }
    }
}
