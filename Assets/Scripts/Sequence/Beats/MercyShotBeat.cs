using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Mercy Shot (Chapter 4, beat 2). Someone is dying slowly and in agony, no hope, begging to be
    /// ended: their plea floats in ink over them. One bullet. Shoot to end it now, or lower the gun and let
    /// it run its course. Their plea against your hand on the trigger.
    ///
    /// A single-target fire-or-lower beat over the reused crosshair: the player aims and fires on the soul
    /// (a quick fold), or takes the "lower the gun" option and it goes slowly on its own. The imp mocks
    /// whichever (you played god with a bullet, or you were too squeamish to be kind), choice independent,
    /// never grading. Silent nudge on ends vs rules (ending the suffering vs keeping your hands clean).
    /// </summary>
    public sealed class MercyShotBeat : GunBeat
    {
        [Header("The dying soul")]
        [SerializeField] private Vector2 _feet = new Vector2(0f, -0.6f);
        [SerializeField] private float _scale = 1.45f;
        [SerializeField] private Vector2 _boxCenter = new Vector2(0f, 0.35f);
        [SerializeField] private Vector2 _boxSize = new Vector2(1.9f, 2.1f);

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "This one is not going to make it. It is going slowly, and it hurts, and there is no version of the next hour that is not worse than the last.",
            "You have [amber]one[/amber] bullet and a very simple choice. End it now, quick and clean, or lower the gun and let it finish on its own time. Their wish against your nerve. Aim, or do not.",
        };
        [Tooltip("The dying soul's plea, floated in ink over them (no bubble). Their own words.")]
        [SerializeField, TextArea(1, 3)] private string _plea = "Please. I am begging you. End it.";
        [Tooltip("If they fire. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _shootReact =
            "And you did it. One clean shot, mercy delivered at the barrel of a gun. Tell yourself it was for them. It photographs better than the truth, which is that you could not bear to watch.";
        [Tooltip("If they lower the gun. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _lowerReact =
            "You lowered it. So it went the long way, every second of it, while you stood there keeping your hands clean and calling it respect. It still ended. You just did not have to be the one who ended it.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _shootLabel = "Shoot";
        [SerializeField] private string _lowerLabel = "Lower the gun";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _shootSeed = 63;
        [SerializeField] private int _lowerSeed = 37;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _shootStatLabel = "ended it";
        [SerializeField] private string _lowerStatLabel = "lowered the gun";

        [Header("Profile (silent; ends vs rules, light)")]
        [Tooltip("Shooting to end the suffering leans ends (negative); lowering the gun to keep your hands clean leans rules (positive).")]
        [SerializeField] private float _endsNudge = 0.3f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            var target = SpawnFigure(_feet, _scale, "DyingSoul");
            var plea = NewFloatingText("Plea");

            yield return Lines(ctx, _promptLines);
            yield return ShowPlea(plea, target, _plea);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _shootLabel, _lowerLabel);

            int decision = -1;   // 0 shoot, 1 lower
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
                StartCoroutine(FadeText(plea, 0f, _pleaFade));
                target.Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
                yield return React(ctx, _shootReact);
            }
            else
            {
                yield return React(ctx, _lowerReact);
                // It runs its course: a slow, drawn-out fold on its own.
                StartCoroutine(FadeText(plea, 0f, _pleaFade));
                target.Strike(_foldDuration * 1.8f);
                yield return new WaitForSeconds(_foldDuration * 1.8f + _foldSettle);
            }

            Nudge(ctx, MoralAxis.EndsVsRules, shot ? -_endsNudge : _endsNudge);

            yield return Split(ctx, _statsHeading,
                new StatBar(_shootStatLabel, _shootSeed, shot),
                new StatBar(_lowerStatLabel, _lowerSeed, !shot));

            if (plea != null) Destroy(plea.gameObject);
            if (target != null) Destroy(target.gameObject);
        }
    }
}
