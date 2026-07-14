using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The full data for one Chapter 8 campaign beat: the imp's DM narration, the options (some optionally
    /// class gated), an optional ruling prompt, and the how-others-chose reveal heading. Built in each beat's
    /// BuildData(state), which is handed the run state so the options and text can vary by the class and the
    /// flags set earlier (the boss especially reads the companion and village flags). The imp mocks whatever
    /// the player picks, choice independent, never grades (the one sanctioned exception is the finale's cheat
    /// the roll, which is its own beat). See <see cref="CampaignBeat"/> and docs.
    /// </summary>
    public sealed class CampaignData
    {
        public string[] Narration;                     // the imp DMs the beat (one or more lines)
        public readonly List<CampaignOption> Options = new List<CampaignOption>();
        public string RulePrompt;                      // optional line right before the options appear
        public string Heading = "what the party did";  // the how-others-chose reveal heading

        // An optional coloured doodle drawn in the scene for the whole beat (the companion, the cornered beast,
        // the treasure hoard, the dragon), inked in and held above the option row and faded out at the end.
        // None = a plain beat (the menus and the pure text choices). See <see cref="CampaignBeat"/>.
        public DoodleKind SceneDoodle = DoodleKind.None;
        public Color SceneOutline;                     // alpha 0 = the doodle's own default colour
        public float SceneScale = 1.7f;
        public Vector2 ScenePos = new Vector2(0f, 0.7f);

        /// <summary>Add one option and return the data, so a beat can chain Add(...).Add(...).</summary>
        public CampaignData Add(CampaignOption o) { if (o != null) Options.Add(o); return this; }
    }
}
