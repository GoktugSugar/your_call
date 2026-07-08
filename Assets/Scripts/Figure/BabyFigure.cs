using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A small, on-model baby doodle: a big round head over a little swaddled bundle, a single hair
    /// curl, and a deliberately minimal face (two dot eyes, a tiny smile). Clearly a baby, never
    /// detailed or creepy (see docs/art-and-ui.md). Reuses <see cref="Figure"/> whole for its ink,
    /// brand, and fold-and-fade, overriding only the shape. Used on the baby-versus-man opener (and the
    /// three-track finish is a child, not this). One job: be the baby on the rail.
    /// </summary>
    public sealed class BabyFigure : Figure
    {
        protected override void BuildShape()
        {
            // Base (bottom of the bundle) sits at the local origin, like the stick figure's feet.
            var bundle = new List<Vector3>();
            InkLine.AddArc(bundle, new Vector2(0f, 0.19f), 0.155f, 0f, 360f, 24);   // a rounded swaddle
            AddStroke("Bundle", bundle);

            var head = new List<Vector3>();
            InkLine.AddArc(head, new Vector2(0f, 0.46f), 0.155f, 0f, 360f, 24);      // a big baby head
            AddStroke("Head", head);

            // One little hair curl on top.
            var curl = new List<Vector3>
            {
                new Vector3(-0.015f, 0.615f, 0f),
                new Vector3(0.02f, 0.66f, 0f),
                new Vector3(0.06f, 0.635f, 0f),
                new Vector3(0.045f, 0.60f, 0f),
            };
            AddStroke("Curl", curl, LineWidth * 0.85f);

            // Minimal face: two dot eyes and a tiny smile. Nothing more, so it never reads creepy.
            var eyeL = new List<Vector3>();
            InkLine.AddArc(eyeL, new Vector2(-0.055f, 0.48f), 0.017f, 0f, 360f, 8);
            AddStroke("EyeL", eyeL, LineWidth * 0.85f);
            var eyeR = new List<Vector3>();
            InkLine.AddArc(eyeR, new Vector2(0.055f, 0.48f), 0.017f, 0f, 360f, 8);
            AddStroke("EyeR", eyeR, LineWidth * 0.85f);

            var smile = new List<Vector3>();
            InkLine.AddArc(smile, new Vector2(0f, 0.44f), 0.045f, 215f, 325f, 10);
            AddStroke("Smile", smile, LineWidth * 0.85f);
        }
    }
}
