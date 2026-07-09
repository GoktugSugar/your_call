using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The best life any human has actually lived, shown as an on-model stick figure wearing a small
    /// hand-drawn crown, used by Chapter 2's better-offer button (see gameplay.md). It is otherwise an
    /// ordinary <see cref="Figure"/>: the beat recolours the whole thing (crown included) to a warm gold
    /// via <see cref="Figure.Brand(Color)"/> (gold = the best life, see art-and-ui.md), and it inks in,
    /// folds and fades exactly like any figure. Overrides only the shape (the stick line plus the crown),
    /// inheriting the rest. One job: be the golden crowned one.
    /// </summary>
    public sealed class CrownedFigure : Figure
    {
        protected override void BuildShape()
        {
            // The standard stick line (matching the base Figure), built from the shared proportions.
            var leftHand = new Vector3(-ArmSpan, ShoulderY - ArmDrop, 0f);
            var rightHand = new Vector3(ArmSpan, ShoulderY - ArmDrop, 0f);
            var shoulder = new Vector3(0f, ShoulderY, 0f);
            var hip = new Vector3(0f, HipY, 0f);
            var leftFoot = new Vector3(-LegSpan, 0f, 0f);
            var rightFoot = new Vector3(LegSpan, 0f, 0f);
            var headCenter = new Vector2(0f, NeckY + HeadRadius);

            var body = new List<Vector3> { leftHand, shoulder };
            InkLine.AddArc(body, headCenter, HeadRadius, -90f, 270f, HeadSegments); // seals at the neck
            body.Add(shoulder);
            body.Add(hip);
            body.Add(leftFoot);
            body.Add(hip);
            body.Add(rightFoot);
            body.Add(hip);
            body.Add(shoulder);
            body.Add(rightHand);
            AddStroke("Ink", body);

            // A small three-point crown resting on the crown of the head, drawn as one stroke (spikes then
            // the base band). Sized from the head so it stays on-model if the proportions are tuned.
            float cx = 0f;
            float topOfHead = headCenter.y + HeadRadius;         // ~0.96 at defaults
            float baseY = topOfHead - HeadRadius * 0.28f;        // sits just onto the head
            float spikeY = topOfHead + HeadRadius * 0.92f;       // the spike tips
            float valleyY = topOfHead + HeadRadius * 0.22f;
            float half = HeadRadius * 1.28f;                      // crown half-width

            var crown = new List<Vector3>
            {
                new Vector3(cx - half, baseY, 0f),               // base left
                new Vector3(cx - half * 0.72f, spikeY, 0f),      // spike 1
                new Vector3(cx - half * 0.34f, valleyY, 0f),     // valley
                new Vector3(cx, spikeY + HeadRadius * 0.16f, 0f),// spike 2 (centre, tallest)
                new Vector3(cx + half * 0.34f, valleyY, 0f),     // valley
                new Vector3(cx + half * 0.72f, spikeY, 0f),      // spike 3
                new Vector3(cx + half, baseY, 0f),               // base right
                new Vector3(cx - half, baseY, 0f),               // close the base band
            };
            AddStroke("Crown", crown, LineWidth * 0.9f);
        }
    }
}
