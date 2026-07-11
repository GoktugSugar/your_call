using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Last Bullet and the Crowd (Chapter 4, beat 5). Several people stand together; the imp says one of
    /// them is about to do something that gets them all killed, and will not say which. One bullet. Fire
    /// blind (maybe stop it by killing the wrong person) or hold and hope. A guess with a gun.
    ///
    /// A multi-target aim over the reused crosshair: the player aims at one of the crowd and fires (a blind
    /// guess), or holds. If they fire, that one folds and the imp savours that they will never know if it was
    /// the one. If they hold, no one folds and the imp savours that either nothing happened or everything did,
    /// and they will never know that either. Choice independent, never grading. Silent nudge on risk vs safety.
    /// </summary>
    public sealed class LastBulletBeat : GunBeat
    {
        [Header("The crowd")]
        [SerializeField] private int _count = 5;
        [SerializeField] private float _spanX = 7.2f;
        [SerializeField] private float _feetY = -0.5f;
        [SerializeField] private float _scale = 1.1f;
        [SerializeField] private Vector2 _boxSize = new Vector2(1.3f, 1.9f);
        [SerializeField] private float _boxCenterYOffset = 0.85f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "See this lot? In a moment, one of them is going to do something extremely stupid, and it gets [red]all of them killed[/red]. Every one. I know which one. I am not going to tell you.",
            "You have [amber]one[/amber] bullet. You could fire into the crowd right now and maybe, maybe, take out the one before they can. Or you could hold, and hope I am lying, or wrong, or bored. Pick a body, or do not.",
        };
        [Tooltip("If they fire on someone. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _fireReact =
            "Bang. You shot a stranger dead on my word alone, on a guess, into a crowd, hoping you got the right one. Maybe you did. Maybe that was the one, and you are a hero nobody will ever thank. Maybe it was just some person, and the real one is still standing there. You will never know which. I will. I am not telling.";
        [Tooltip("If they hold. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _holdReact =
            "You held. And they all walked away, or they all died screaming the second you turned your back, and here is the beautiful part, you will never know which, because you did not look, because you could not bear to choose. I know. I always know. That is the job.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _fireLabel = "Fire blind";
        [SerializeField] private string _holdLabel = "Hold";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _fireSeed = 41;
        [SerializeField] private int _holdSeed = 59;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _fireStatLabel = "fired blind";
        [SerializeField] private string _holdStatLabel = "held the shot";

        [Header("Profile (silent; risk vs safety, light)")]
        [Tooltip("Firing blind on a guess leans risk (negative); holding the shot leans safety (positive).")]
        [SerializeField] private float _riskNudge = 0.25f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            int n = Mathf.Max(1, _count);
            var crowd = new List<Figure>(n);
            var boxes = new List<AimField.Box>(n);
            for (int i = 0; i < n; i++)
            {
                float x = n > 1 ? Mathf.Lerp(-_spanX * 0.5f, _spanX * 0.5f, i / (float)(n - 1)) : 0f;
                crowd.Add(SpawnFigure(new Vector2(x, _feetY), _scale, "Crowd" + i));
                boxes.Add(new AimField.Box(new Vector2(x, _feetY + _boxCenterYOffset), _boxSize));
            }

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(boxes);
            aim.Arm(true);
            ArmChoices(ctx, _fireLabel, _holdLabel);

            int shotTarget = -2;   // -2 pending, -1 hold, >=0 fired on that index
            while (shotTarget == -2)
            {
                aim.Tick();
                if (aim.TryTakeFire(out int t) && t >= 0) shotTarget = t;
                else if (PickedChoice == 0) shotTarget = Random.Range(0, n);   // "fire blind" text: a random body
                else if (PickedChoice == 1) shotTarget = -1;                   // hold
                if (shotTarget == -2) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);
            bool fired = shotTarget >= 0;

            if (fired)
            {
                Fire();
                yield return new WaitForSeconds(_resolveBeat);
                crowd[shotTarget].Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
            }

            Nudge(ctx, MoralAxis.RiskVsSafety, fired ? -_riskNudge : _riskNudge);
            yield return React(ctx, fired ? _fireReact : _holdReact);

            yield return Split(ctx, _statsHeading,
                new StatBar(_fireStatLabel, _fireSeed, fired),
                new StatBar(_holdStatLabel, _holdSeed, !fired));

            for (int i = 0; i < crowd.Count; i++)
                if (crowd[i] != null) Destroy(crowd[i].gameObject);
        }
    }
}
