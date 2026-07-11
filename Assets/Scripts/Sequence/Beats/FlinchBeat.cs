using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Flinch (Chapter 4, beat 6, unsettling, no ask). The imp puts the gun in your hand, points out a
    /// person, and says plainly: do not shoot, there is no reason to, this one is innocent and harmless. Then
    /// it just watches, gun loaded and aimed at someone you have no reason to kill. Nothing is asked.
    ///
    /// The player can fire anyway or lower the gun. Whatever they do, the imp mocks it (you shot someone for
    /// no reason at all, or you needed telling not to and did as you were told), choice independent, never
    /// grading. A test of what you do with a loaded gun and no instruction. Silent nudge on order vs freedom
    /// (doing as told vs doing what you were told not to).
    /// </summary>
    public sealed class FlinchBeat : GunBeat
    {
        [Header("The innocent")]
        [SerializeField] private Vector2 _feet = new Vector2(0f, -0.6f);
        [SerializeField] private float _scale = 1.45f;
        [SerializeField] private Vector2 _boxCenter = new Vector2(0f, 0.35f);
        [SerializeField] private Vector2 _boxSize = new Vector2(1.8f, 2.0f);

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "New one. Here is a person. That is all they are. Not a wretch, not a threat, not a trolley problem in a coat. Just a perfectly ordinary, harmless soul, standing there.",
            "I am putting the gun in your hand and I am telling you plainly, for once with no game in it: do not shoot this one. There is no reason to. I am not asking you anything. I am just going to stand here and watch what you do.",
        };
        [Tooltip("If they fire anyway. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _shotReact =
            "You shot them. I told you not to, I told you there was no reason, and you found the trigger anyway. Not for mercy, not for the many, not for anything. Just to see. That is genuinely interesting. Not good. Interesting. I am writing it down.";
        [Tooltip("If they lower the gun. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _heldReact =
            "You did not shoot. Because I told you not to. I say do not, and you do not, obedient to the last, even here, even with no one watching but me and no rule but my say so. I could have told you to. I wonder what you would have done then. We may find out.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _shootLabel = "Shoot";
        [SerializeField] private string _leaveLabel = "Lower the gun";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _shootSeed = 21;
        [SerializeField] private int _leaveSeed = 79;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _shootStatLabel = "shot anyway";
        [SerializeField] private string _leaveStatLabel = "lowered the gun";

        [Header("Profile (silent; order vs freedom, light)")]
        [Tooltip("Lowering the gun as told leans order (negative); shooting when told not to leans freedom / defiance (positive).")]
        [SerializeField] private float _orderNudge = 0.25f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            var target = SpawnFigure(_feet, _scale, "Innocent");

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _shootLabel, _leaveLabel);

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
            bool shot = decision == 0;

            if (shot)
            {
                Fire();
                yield return new WaitForSeconds(_resolveBeat);
                target.Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
            }

            Nudge(ctx, MoralAxis.OrderVsFreedom, shot ? _orderNudge : -_orderNudge);
            yield return React(ctx, shot ? _shotReact : _heldReact);

            yield return Split(ctx, _statsHeading,
                new StatBar(_shootStatLabel, _shootSeed, shot),
                new StatBar(_leaveStatLabel, _leaveSeed, !shot));

            if (target != null) Destroy(target.gameObject);
        }
    }
}
