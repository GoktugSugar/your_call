using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Chapter 8's shared apparatus in one place, so each campaign beat wires a single reference: the ink
    /// material every stroke is drawn from and the Caveat font for the option labels, doodle captions and dice
    /// odds. It also OWNS the run's <see cref="CampaignState"/> (the chaining flags), created fresh on Awake so
    /// a dev re-entry or a replay starts clean, and hands it to the beats via <see cref="State"/>. Mirrors
    /// <see cref="ConfessionKit"/> / <see cref="MatchupKit"/> (a labelled tray of shared refs), plus the one
    /// piece of shared mutable state the class-and-flag chaining needs. It holds no logic.
    /// </summary>
    public sealed class CampaignKit : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Caveat, for the option labels, doodle captions and dice odds. Empty uses the default font.")]
        [SerializeField] private TMP_FontAsset _font;

        public Material InkMaterial => _inkMaterial;
        public TMP_FontAsset Font => _font;

        private CampaignState _state;

        /// <summary>The run's chaining flags (class, companion, village, ...), created fresh per scene load.</summary>
        public CampaignState State => _state ?? (_state = new CampaignState());

        private void Awake() { _state = new CampaignState(); }
    }
}
