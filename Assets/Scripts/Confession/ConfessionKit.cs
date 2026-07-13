using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Chapter 7's shared apparatus, in one place, so each confession case beat wires a single reference
    /// instead of several: the ink material every stroke is drawn from, the Caveat font for the floating
    /// headlines and verdict labels, the plain <see cref="Figure"/> prefab each confessor is instanced from,
    /// the reused <see cref="WalkingButton"/> gag figure (the button's own confession, case 4), and the fixed
    /// <see cref="ConfessionBooth"/> set the souls file up to. It holds no logic; it is a labelled tray of
    /// shared refs, mirroring <see cref="MatchupKit"/> and <see cref="GunKit"/>.
    /// </summary>
    public sealed class ConfessionKit : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Caveat, for the floating headlines and verdict labels. Empty uses the default font.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("Confessors")]
        [Tooltip("The plain stick figure prefab each confessor is instanced from (files in, confesses, files out).")]
        [SerializeField] private Figure _figurePrefab;
        [Tooltip("The reused walking button gag figure: it files into the booth and confesses too (case 4).")]
        [SerializeField] private WalkingButton _walkingButtonPrefab;

        [Header("Set")]
        [Tooltip("The fixed confession booth the souls file up to (drawn once, held all chapter).")]
        [SerializeField] private ConfessionBooth _booth;

        public Material InkMaterial => _inkMaterial;
        public TMP_FontAsset Font => _font;
        public Figure FigurePrefab => _figurePrefab;
        public WalkingButton WalkingButtonPrefab => _walkingButtonPrefab;
        public ConfessionBooth Booth => _booth;
    }
}
