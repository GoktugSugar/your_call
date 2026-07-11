using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The duel opponent (Chapter 4, The Duel): an ordinary stick figure standing across from the player
    /// with one arm raised, leveling a small ink pistol back at them. Drawn on-model in the simple line
    /// (see docs/art-and-ui.md), reusing <see cref="Figure"/> whole for its ink, fold-and-fade (so it folds
    /// if the player shoots first), overriding only the shape. The "aimed at you" reads from the raised gun
    /// arm and the imp's words; no detailed or menacing face. One job: be the other gun in the standoff.
    /// </summary>
    public sealed class DuelistFigure : Figure
    {
        protected override void BuildShape()
        {
            var headCenter = new Vector2(0f, NeckY + HeadRadius);
            var head = new List<Vector3>();
            InkLine.AddArc(head, headCenter, HeadRadius, -90f, 270f, HeadSegments);
            AddStroke("Head", head);

            // Torso and legs.
            AddStroke("Torso", new List<Vector3> { new Vector3(0f, ShoulderY, 0f), new Vector3(0f, HipY, 0f) });
            AddStroke("LegL", new List<Vector3> { new Vector3(0f, HipY, 0f), new Vector3(-LegSpan, 0f, 0f) });
            AddStroke("LegR", new List<Vector3> { new Vector3(0f, HipY, 0f), new Vector3(LegSpan, 0f, 0f) });

            // The idle arm hangs at the figure's side.
            AddStroke("ArmDown", new List<Vector3>
            {
                new Vector3(0f, ShoulderY, 0f),
                new Vector3(ArmSpan, ShoulderY - ArmDrop, 0f),
            });

            // The gun arm: raised and extended, leveling the pistol back toward the player.
            var shoulder = new Vector3(0f, ShoulderY, 0f);
            var elbow = new Vector3(-0.28f, ShoulderY + 0.02f, 0f);
            var wrist = new Vector3(-0.52f, ShoulderY, 0f);
            AddStroke("ArmGun", new List<Vector3> { shoulder, elbow, wrist });

            // A small ink pistol at the hand: a barrel, a slide line above it, and a grip.
            AddStroke("Barrel", new List<Vector3> { new Vector3(-0.52f, ShoulderY, 0f), new Vector3(-0.80f, ShoulderY, 0f) }, LineWidth * 0.9f);
            AddStroke("Slide", new List<Vector3> { new Vector3(-0.55f, ShoulderY + 0.05f, 0f), new Vector3(-0.76f, ShoulderY + 0.05f, 0f) }, LineWidth * 0.7f);
            AddStroke("Grip", new List<Vector3> { new Vector3(-0.54f, ShoulderY - 0.01f, 0f), new Vector3(-0.46f, ShoulderY - 0.16f, 0f) }, LineWidth * 0.9f);
        }
    }
}
