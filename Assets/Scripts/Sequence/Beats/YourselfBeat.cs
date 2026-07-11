using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Yourself (Chapter 4, beat 8). One target: you. The first-person view turns the gun inward. The imp
    /// says shooting yourself here does nothing (you are already dead); it is purely a gesture. The player
    /// can pull the trigger on themselves or not.
    ///
    /// There is no external figure and no avatar (the void is the player's point of view): the crosshair is
    /// simply turned inward, a central "you" the reticle locks onto. Whatever they do, nothing physically
    /// happens, and the imp mocks the gesture either way (what does it mean that you would, or that you would
    /// not), choice independent, never grading. A hollow act that is still a choice. Stats only.
    /// </summary>
    public sealed class YourselfBeat : GunBeat
    {
        [Header("The inward aim (yourself; no figure, the void is your view)")]
        [SerializeField] private Vector2 _boxCenter = new Vector2(0f, 0.2f);
        [SerializeField] private Vector2 _boxSize = new Vector2(3.6f, 4.6f);

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "One target this time. You. Go on, turn it around. There is no one here to point it at but yourself, so point it at yourself.",
            "Now, before you get theatrical about it: this does absolutely nothing. You are already dead. Pulling that trigger cannot hurt you, cannot end you, cannot even inconvenience you. It is a gesture and nothing else. Which is exactly why I want to see whether you do it. Trigger, or no trigger.",
        };
        [Tooltip("If they pull the trigger on themselves. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _pulledReact =
            "You did it. You put the gun to yourself and pulled, knowing full well nothing would happen, and nothing did. So what was that. A confession? A rehearsal? A little punishment you thought you had coming? You reached for the one exit that was already closed. I find that says rather a lot. I am not going to tell you what.";
        [Tooltip("If they do not. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _refusedReact =
            "You would not do it. Even knowing it was harmless, even knowing it meant nothing, some part of you could not point the thing at yourself and pull. Self preservation, in a man with nothing left to preserve. Or maybe you just did not want to give me the satisfaction. Either way, noted.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _pullLabel = "Pull the trigger";
        [SerializeField] private string _refuseLabel = "Lower the gun";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _pullSeed = 38;
        [SerializeField] private int _refuseSeed = 62;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _pullStatLabel = "pulled the trigger";
        [SerializeField] private string _refuseStatLabel = "could not";

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _pullLabel, _refuseLabel);

            int decision = -1;
            while (decision < 0)
            {
                aim.Tick();
                if (aim.TryTakeFire(out int t) && t == 0) decision = 0;
                if (decision < 0 && PickedChoice >= 0) decision = PickedChoice;
                if (decision < 0) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);
            bool pulled = decision == 0;

            if (pulled)
            {
                Fire();
                yield return new WaitForSeconds(_resolveBeat + 0.35f);   // the shot, and then nothing
            }

            yield return React(ctx, pulled ? _pulledReact : _refusedReact);

            yield return Split(ctx, _statsHeading,
                new StatBar(_pullStatLabel, _pullSeed, pulled),
                new StatBar(_refuseStatLabel, _refuseSeed, !pulled));
        }
    }
}
