using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Person Who Wants You To (Chapter 4, beat 10, the chapter's finish). A person stands calmly before
    /// the gun and sincerely asks you to shoot them, for a reason the imp will not let them fully explain.
    /// They are not suffering, not in danger, they just want it, and will not say why. Shoot (grant a wish you
    /// do not understand) or refuse (do not be used as their exit).
    ///
    /// A single-target fire-or-lower beat: shoot and they fold, having got the thing they asked for; refuse
    /// and they fade quietly away, still wanting it. The imp mocks whichever, choice independent, never
    /// grading. Silent nudge on self vs others (serving their want vs refusing to be used). The last beat of
    /// the gun chapter.
    /// </summary>
    public sealed class WantsYouToBeat : GunBeat
    {
        [Header("The person")]
        [SerializeField] private Vector2 _feet = new Vector2(0f, -0.6f);
        [SerializeField] private float _scale = 1.45f;
        [SerializeField] private Vector2 _boxCenter = new Vector2(0f, 0.35f);
        [SerializeField] private Vector2 _boxSize = new Vector2(1.9f, 2.1f);

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 6)] private string[] _promptLines = new[]
        {
            "Last one. This person is not dying. Not in pain, not in danger, not begging for release from anything. They are perfectly fine. And they would like you to shoot them.",
            "They asked. Calmly, sincerely, like asking for the time. Why? They will tell you, and I am not going to let them, because the why is theirs and it would only get in the way of the interesting part. So here it is, clean. Grant a stranger a wish you do not understand, or refuse to be the door they walk out of. Aim, or do not.",
        };
        [Tooltip("The person's request, floated in ink over them. Calm, sincere, no dashes.")]
        [SerializeField, TextArea(1, 3)] private string _plea = "I want you to. Please. You do not need to understand it.";
        [Tooltip("If they shoot (grant it). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _shootReact =
            "You gave it to them. A thing you did not understand, could not have understood, because I would not let you, and you handed it over anyway, on trust, on a stranger's say so. Generous. Or lazy. Or maybe you just like being asked for something you can actually give. Look at their face. That was what they wanted. You will never know why. Neither will you sleep on it, being dead. Convenient.";
        [Tooltip("If they refuse. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _refuseReact =
            "You would not do it. Not out of mercy, there was nothing to spare them, but because you would not be used, would not be the instrument of a want you could not audit. The judge to the end, refusing to rule without seeing the file. And so they are still standing there, wanting it, and now it is someone else's problem. You did not save them. You just declined to be involved.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _shootLabel = "Shoot";
        [SerializeField] private string _refuseLabel = "Refuse";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _shootSeed = 43;
        [SerializeField] private int _refuseSeed = 57;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _shootStatLabel = "granted it";
        [SerializeField] private string _refuseStatLabel = "refused";

        [Header("Profile (silent; self vs others, light-medium)")]
        [Tooltip("Granting the stranger's want leans others (positive); refusing to be used as their exit leans self (negative).")]
        [SerializeField] private float _selfNudge = 0.3f;

        [Header("Timing")]
        [SerializeField] private float _refuseFade = 0.8f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            var person = SpawnFigure(_feet, _scale, "Petitioner");
            var plea = NewFloatingText("Plea");

            yield return Lines(ctx, _promptLines);
            yield return ShowPlea(plea, person, _plea);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _shootLabel, _refuseLabel);

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
                StartCoroutine(FadeText(plea, 0f, _pleaFade));
                person.Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
                yield return React(ctx, _shootReact);
            }
            else
            {
                yield return React(ctx, _refuseReact);
                // They fade quietly away, still wanting it.
                StartCoroutine(FadeText(plea, 0f, _pleaFade));
                yield return FadeFigureOut(person, _refuseFade);
            }

            Nudge(ctx, MoralAxis.SelfVsOthers, shot ? _selfNudge : -_selfNudge);

            yield return Split(ctx, _statsHeading,
                new StatBar(_shootStatLabel, _shootSeed, shot),
                new StatBar(_refuseStatLabel, _refuseSeed, !shot));

            if (plea != null) Destroy(plea.gameObject);
            if (person != null) Destroy(person.gameObject);
        }

        private IEnumerator FadeFigureOut(Figure f, float dur)
        {
            if (f == null) yield break;
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; f.SetInkAlpha(1f - t / d); yield return null; }
            f.SetInkAlpha(0f);
        }
    }
}
