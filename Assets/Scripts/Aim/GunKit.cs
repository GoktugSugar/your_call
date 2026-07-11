using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The gun chapter's shared apparatus, in one place: the single first person <see cref="Crosshair"/>
    /// and its amber <see cref="AimHighlight"/> lock (the very same pair the man-and-the-last-bear opener
    /// aims with, reused chapter wide), the gun's <see cref="GunSfx"/> shot (which rides on the crosshair),
    /// the shared <see cref="Figure"/> prefab the beats instance their targets from, and the ink material
    /// and Caveat font. Every gun beat references one <see cref="GunKit"/> instead of wiring six references
    /// each, so the crosshair, the amber lock and the gunshot are literally the same objects across the
    /// whole chapter (see docs/tech.md, Chapter 4). It holds no logic; it is a labelled tray of shared refs.
    /// </summary>
    public sealed class GunKit : MonoBehaviour
    {
        [Header("Aim (the reused bear crosshair + amber lock + gunshot)")]
        [SerializeField] private Crosshair _crosshair;
        [SerializeField] private AimHighlight _aimHighlight;

        [Header("Targets")]
        [Tooltip("The plain stick figure prefab the beats instance their targets from (the man, the crowd, the pleading soul). Non-figure targets bring their own prefab.")]
        [SerializeField] private Figure _figurePrefab;

        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Caveat, for the floating pleas and any beat labels. Empty uses the default font.")]
        [SerializeField] private TMP_FontAsset _font;

        public Crosshair Crosshair => _crosshair;
        public AimHighlight AimHighlight => _aimHighlight;
        public Figure FigurePrefab => _figurePrefab;
        public Material InkMaterial => _inkMaterial;
        public TMP_FontAsset Font => _font;

        /// <summary>The gunshot lives with the gun (the crosshair), the same split as the bear station.</summary>
        public GunSfx GunSfx => _crosshair != null ? _crosshair.GetComponent<GunSfx>() : null;
    }
}
