using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The future baby (Chapter 4's prevent-the-future dilemma): a small on-model baby doodle carrying two
    /// deliberately ABSTRACT cues, one step removed from any real person or event (see docs/gameplay.md,
    /// docs/narrative.md) so it is a theme, not a named reference: a small square block of a mustache under
    /// the nose, and a little paintbrush beside it (it is into painting). Clearly a baby, tasteful and never
    /// detailed or creepy (see docs/art-and-ui.md). Reuses <see cref="Figure"/> whole for its ink, brand, and
    /// fold-and-fade, overriding only the shape. One job: be the baby the imp says grows up to do terrible things.
    /// </summary>
    public sealed class FutureBabyFigure : Figure
    {
        protected override void BuildShape()
        {
            // The baby: a swaddled bundle at the origin, a big head, a hair curl (the same on-model baby).
            var bundle = new List<Vector3>();
            InkLine.AddArc(bundle, new Vector2(0f, 0.19f), 0.155f, 0f, 360f, 24);
            AddStroke("Bundle", bundle);

            var head = new List<Vector3>();
            InkLine.AddArc(head, new Vector2(0f, 0.46f), 0.155f, 0f, 360f, 24);
            AddStroke("Head", head);

            var curl = new List<Vector3>
            {
                new Vector3(-0.015f, 0.615f, 0f),
                new Vector3(0.02f, 0.66f, 0f),
                new Vector3(0.06f, 0.635f, 0f),
                new Vector3(0.045f, 0.60f, 0f),
            };
            AddStroke("Curl", curl, LineWidth * 0.85f);

            // Two small dot eyes up top, well clear of the mustache, kept minimal so it never reads creepy.
            var eyeL = new List<Vector3>();
            InkLine.AddArc(eyeL, new Vector2(-0.072f, 0.545f), 0.011f, 0f, 360f, 10);
            AddStroke("EyeL", eyeL, LineWidth * 0.8f);
            var eyeR = new List<Vector3>();
            InkLine.AddArc(eyeR, new Vector2(0.072f, 0.545f), 0.011f, 0f, 360f, 10);
            AddStroke("EyeR", eyeR, LineWidth * 0.8f);

            // The square mustache: a small solid dark bar under the nose (the abstract cue), boxy and clearly
            // the dominant feature, with clear space above (the eyes) and below (the mouth).
            AddStroke("Stache", new List<Vector3> { new Vector3(-0.046f, 0.45f, 0f), new Vector3(0.046f, 0.45f, 0f) }, LineWidth * 1.2f);

            // A small neutral baby mouth below the mustache, so the square reads as a mustache (above a mouth).
            AddStroke("Mouth", new List<Vector3> { new Vector3(-0.03f, 0.385f, 0f), new Vector3(0.03f, 0.385f, 0f) }, LineWidth * 0.75f);

            // A little paintbrush beside the baby (it paints): a handle, a ferrule tick, and a bristle tuft.
            AddStroke("BrushHandle", new List<Vector3> { new Vector3(0.24f, 0.05f, 0f), new Vector3(0.42f, 0.38f, 0f) }, LineWidth * 0.95f);
            AddStroke("BrushFerrule", new List<Vector3> { new Vector3(0.35f, 0.35f, 0f), new Vector3(0.46f, 0.29f, 0f) }, LineWidth * 0.8f);
            AddStroke("BrushTuft", new List<Vector3>
            {
                new Vector3(0.40f, 0.36f, 0f), new Vector3(0.56f, 0.52f, 0f),
                new Vector3(0.47f, 0.56f, 0f), new Vector3(0.38f, 0.44f, 0f), new Vector3(0.40f, 0.36f, 0f),
            }, LineWidth * 0.85f);
            AddStroke("BrushBristle", new List<Vector3> { new Vector3(0.43f, 0.42f, 0f), new Vector3(0.51f, 0.51f, 0f) }, LineWidth * 0.6f);
        }
    }
}
