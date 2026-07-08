using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// An on-model figure carrying a clear rounded belly: a normal head and stick limbs, but the torso
    /// is a full round belly rather than a straight spine, so she reads unmistakably as pregnant in the
    /// same simple ink line (see docs/art-and-ui.md), never detailed. Reuses <see cref="Figure"/> whole
    /// for its ink, fold and fade, overriding only the shape. Used on the three-track finish. One job.
    /// </summary>
    public sealed class PregnantFigure : Figure
    {
        protected override void BuildShape()
        {
            // Feet at the local origin, +y up, like the stick figure.
            var belly = new List<Vector3>();
            InkLine.AddArc(belly, new Vector2(0f, 0.46f), 0.18f, 0f, 360f, 28);   // the round torso/belly
            AddStroke("Belly", belly);

            var head = new List<Vector3>();
            InkLine.AddArc(head, new Vector2(0f, 0.80f), 0.12f, 0f, 360f, 20);
            AddStroke("Head", head);

            // A short neck joining the head to the top of the belly.
            AddStroke("Neck", new List<Vector3>
            {
                new Vector3(0f, 0.68f, 0f),
                new Vector3(0f, 0.635f, 0f),
            });

            // Arms out from the upper sides of the belly.
            AddStroke("ArmL", new List<Vector3>
            {
                new Vector3(-0.16f, 0.575f, 0f),
                new Vector3(-0.30f, 0.52f, 0f),
                new Vector3(-0.31f, 0.44f, 0f),
            });
            AddStroke("ArmR", new List<Vector3>
            {
                new Vector3(0.16f, 0.575f, 0f),
                new Vector3(0.30f, 0.52f, 0f),
                new Vector3(0.31f, 0.44f, 0f),
            });

            // Legs down from the bottom of the belly.
            AddStroke("LegL", new List<Vector3>
            {
                new Vector3(-0.055f, 0.30f, 0f),
                new Vector3(-0.09f, 0.14f, 0f),
                new Vector3(-0.15f, 0f, 0f),
            });
            AddStroke("LegR", new List<Vector3>
            {
                new Vector3(0.055f, 0.30f, 0f),
                new Vector3(0.09f, 0.14f, 0f),
                new Vector3(0.15f, 0f, 0f),
            });
        }
    }
}
