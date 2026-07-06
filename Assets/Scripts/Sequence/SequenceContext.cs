using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The persistent pieces a sequence hands to every beat: the embodied guide and its
    /// voice, the shared aftermath and choice widgets, the profile, the camera, and the
    /// screen wash. Beats read what they need and stay decoupled from each other and from
    /// how the sequence is wired.
    /// </summary>
    public sealed class SequenceContext
    {
        public readonly NarratorView Narrator;
        public readonly ImpFigure Imp;
        public readonly StatsView Stats;
        public readonly ChoiceButtons Choices;
        public readonly Profile Profile;
        public readonly Camera Camera;
        public readonly ScreenFade Fade;

        public SequenceContext(NarratorView narrator, ImpFigure imp, StatsView stats,
            ChoiceButtons choices, Profile profile, Camera camera, ScreenFade fade)
        {
            Narrator = narrator;
            Imp = imp;
            Stats = stats;
            Choices = choices;
            Profile = profile;
            Camera = camera;
            Fade = fade;
        }
    }
}
