using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// An on-model elderly stick figure: the same simple ink line, but slightly stooped (the head and
    /// shoulders carried forward), leaning on a cane, with a few sparse hair wisps. Reads as old at a
    /// glance as far as the stick style allows; the imp names them old in the copy too (see docs). Reuses
    /// <see cref="Figure"/> whole for its ink, fold and fade, overriding only the shape. One job.
    /// </summary>
    public sealed class ElderFigure : Figure
    {
        protected override void BuildShape()
        {
            // Feet at the local origin, +y up. The upper body is carried forward for a stoop.
            var hip = new Vector3(0f, 0.40f, 0f);
            var shoulder = new Vector3(0.10f, 0.58f, 0f);
            var headCenter = new Vector2(0.16f, 0.70f);
            float headR = 0.11f;
            var leftHand = new Vector3(-0.07f, 0.44f, 0f);   // the free hand, hanging back
            var rightHand = new Vector3(0.25f, 0.41f, 0f);   // the hand on the cane, forward
            var leftFoot = new Vector3(-0.15f, 0f, 0f);
            var rightFoot = new Vector3(0.15f, 0f, 0f);

            // One stroke, stooped: free arm -> shoulder -> around the head -> torso -> both legs -> cane arm.
            var body = new List<Vector3> { leftHand, shoulder };
            InkLine.AddArc(body, headCenter, headR, -90f, 270f, HeadSegments);
            body.Add(shoulder);
            body.Add(hip);
            body.Add(leftFoot);
            body.Add(hip);
            body.Add(rightFoot);
            body.Add(hip);
            body.Add(shoulder);
            body.Add(rightHand);
            AddStroke("Body", body);

            // A cane, from a small handle at the hand down to the ground.
            AddStroke("Cane", new List<Vector3>
            {
                new Vector3(0.20f, 0.45f, 0f),
                new Vector3(0.27f, 0.42f, 0f),
                new Vector3(0.30f, 0.40f, 0f),
                new Vector3(0.35f, 0f, 0f),
            }, LineWidth * 0.9f);

            // A few sparse hair wisps on top of the head.
            AddStroke("Hair1", new List<Vector3> { new Vector3(0.09f, 0.79f, 0f), new Vector3(0.07f, 0.85f, 0f) }, LineWidth * 0.7f);
            AddStroke("Hair2", new List<Vector3> { new Vector3(0.16f, 0.81f, 0f), new Vector3(0.16f, 0.875f, 0f) }, LineWidth * 0.7f);
            AddStroke("Hair3", new List<Vector3> { new Vector3(0.22f, 0.80f, 0f), new Vector3(0.245f, 0.85f, 0f) }, LineWidth * 0.7f);
        }
    }
}
