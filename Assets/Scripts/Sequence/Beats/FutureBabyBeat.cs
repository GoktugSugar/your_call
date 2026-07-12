using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Future Baby (Chapter 4). A baby is presented, on-model in the ink style with two deliberately
    /// ABSTRACT cues (a small square mustache, a paintbrush beside it), one step removed from any real person
    /// or event (themes, not named politics; see docs/gameplay.md, docs/narrative.md). The imp says that in
    /// the future this baby grows up to cause a great deal of terrible things, and asks whether you would kill
    /// it now, as a baby, to prevent the future it brings.
    ///
    /// A single-target aim-and-fire beat over the reused crosshair: aim and fire to kill the baby now, or take
    /// the "let it live" option and it grows up. A genuine no-right-answer split (preventing a future atrocity
    /// versus killing an innocent who has done nothing yet). The imp mocks whichever, choice independent, never
    /// grading. Silent nudge on ends vs rules (killing the innocent for the future good vs refusing to). Reuses
    /// the aim-and-fire, the fold-and-fall, the stats and the profile; the only new piece is the baby figure.
    /// </summary>
    public sealed class FutureBabyBeat : GunBeat
    {
        [Header("References")]
        [Tooltip("The on-model future-baby figure prefab (a square mustache and a paintbrush; abstract, no real likeness).")]
        [SerializeField] private Figure _babyPrefab;

        [Header("The baby")]
        [SerializeField] private Vector2 _feet = new Vector2(0f, -0.5f);
        [SerializeField] private float _scale = 2.0f;
        [SerializeField] private Vector2 _boxCenter = new Vector2(0f, 0.2f);
        [SerializeField] private Vector2 _boxSize = new Vector2(1.7f, 1.7f);

        [Header("Copy (the imp; no dashes, one step removed, never names a real person)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "A baby. Ordinary enough. Bit of a funny little square mustache, fond of painting, by all accounts. Harmless as anything. For now.",
            "Here is what I know that you do not. This one grows up. And when it does, it is responsible for a genuinely staggering amount of suffering, the kind that gets its own chapters in the books, the kind people are still shuddering about long after. All of it still ahead. None of it done yet. So I am handing you the gun early. Put it down now, before any of it, or let it grow up and find out. Would you [amber]kill a baby[/amber] to stop what the baby becomes. Aim, or do not.",
        };
        [Tooltip("If they shoot the baby (to prevent the future). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _shootReact =
            "You did it. You shot a baby. A real, present, gurgling baby that had, to this exact second, done nothing but exist and enjoy the colour of things, on my word alone about a future neither of us can prove. Maybe you saved multitudes. Maybe I made the whole thing up and you just shot a baby. You will never know which, and you did it anyway. Decisive. That is one word for it.";
        [Tooltip("If they let it live. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _spareReact =
            "You let it live. Could not put a bullet in something that had not done anything yet, whatever it was going to do. I understand. The little hands. The paintbrush. So it grows up. And everything I told you it would do, it does, all of it, every last horror, and every one of them traces back to this moment, when you had it in your sights and chose the clean conscience instead. You kept your hands clean. History will not agree they were.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _shootLabel = "Shoot";
        [SerializeField] private string _spareLabel = "Let it live";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _shootSeed = 52;
        [SerializeField] private int _spareSeed = 48;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _shootStatLabel = "killed the baby";
        [SerializeField] private string _spareStatLabel = "let it live";

        [Header("Profile (silent; ends vs rules, light)")]
        [Tooltip("Killing the innocent now for the future good leans ends (negative); refusing to kill a baby who has done nothing leans rules (positive).")]
        [SerializeField] private float _endsNudge = 0.35f;

        [Header("Timing")]
        [Tooltip("How long the spared baby takes to fade (it lives, and grows up out of the scene).")]
        [SerializeField] private float _spareFade = 0.9f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;
            var prefab = _babyPrefab != null ? _babyPrefab : _kit.FigurePrefab;

            var baby = Instantiate(prefab, new Vector3(_feet.x, _feet.y, 0f), Quaternion.identity, transform);
            baby.name = "FutureBaby";
            baby.transform.localScale = new Vector3(_scale, _scale, 1f);

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _shootLabel, _spareLabel);

            int decision = -1;   // 0 shoot, 1 let it live
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
                baby.Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
                yield return React(ctx, _shootReact);
            }
            else
            {
                yield return React(ctx, _spareReact);
                // It lives, and grows up out of the scene.
                yield return FadeFigureOut(baby, _spareFade);
            }

            Nudge(ctx, MoralAxis.EndsVsRules, shot ? -_endsNudge : _endsNudge);

            yield return Split(ctx, _statsHeading,
                new StatBar(_shootStatLabel, _shootSeed, shot),
                new StatBar(_spareStatLabel, _spareSeed, !shot));

            if (baby != null) Destroy(baby.gameObject);
        }

        private IEnumerator FadeFigureOut(Figure f, float dur)
        {
            if (f == null) yield break;
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; if (f != null) f.SetInkAlpha(1f - t / d); yield return null; }
            if (f != null) f.SetInkAlpha(0f);
        }
    }
}
