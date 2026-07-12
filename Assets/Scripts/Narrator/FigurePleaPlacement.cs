using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The shared placement for the floating ink pleas that sit over a figure's head, with no bubble, box or
    /// background: the Begging and Parent trolleys and the gun chapter's aim-and-fire beats all use the same
    /// ink-over-a-figure treatment (see docs/art-and-ui.md). It anchors the plea a clearance ABOVE the
    /// figure's actual head top, derived from the figure's own proportions times its world scale, so a figure
    /// scaled up in a gun beat lifts its plea proportionally and the text never lands on the head or body.
    /// One job: answer "where does a plea sit above this figure." Every user routes through here, so raising
    /// the clearance fixes every chapter at once.
    /// </summary>
    public static class FigurePleaPlacement
    {
        /// <summary>The world anchor for a plea floating <paramref name="clearance"/> above the figure's head,
        /// scale-aware. The figure's transform origin is its feet; its head top comes from the figure's own
        /// <see cref="Figure.HeadTopLocalY"/> times its world scale, so any figure size clears correctly.</summary>
        public static Vector3 Above(Figure figure, float clearance)
        {
            if (figure == null) return Vector3.zero;
            Transform t = figure.transform;
            float headTopWorld = t.position.y + figure.HeadTopLocalY * Mathf.Abs(t.lossyScale.y);
            return new Vector3(t.position.x, headTopWorld + clearance, 0f);
        }
    }
}
