using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Chapter 5's shared apparatus, in one place, so each matchup beat wires a single reference instead of
    /// several: the ink material every fighter doodle is drawn from, the Caveat font for the fighter labels and
    /// the "vs", and the reused <see cref="WalkingButton"/> prefab (the callback opponent in "You vs the Walking
    /// Button"). It holds no logic; it is a labelled tray of shared refs, mirroring <see cref="GunKit"/>.
    /// </summary>
    public sealed class MatchupKit : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Caveat, for the fighter labels, counts and the 'vs'. Empty uses the default font.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("Callback figure")]
        [Tooltip("The reused walking-button gag figure, the opponent in the 'You vs the Walking Button' matchup.")]
        [SerializeField] private WalkingButton _walkingButtonPrefab;

        public Material InkMaterial => _inkMaterial;
        public TMP_FontAsset Font => _font;
        public WalkingButton WalkingButtonPrefab => _walkingButtonPrefab;
    }
}
