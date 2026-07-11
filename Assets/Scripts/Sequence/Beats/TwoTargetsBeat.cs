using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Two Targets, One Bullet (Chapter 4, beat 3). Two people, both about to die another, worse way in
    /// seconds, both begging to be shot instead. One bullet, so you can spare only one of them the worse
    /// death. Whichever you shoot gets the mercy; the other suffers the other death.
    ///
    /// A two-target aim over the reused crosshair: the player fires on the left or the right soul (or picks
    /// via the text fallback). The spared one folds quick and clean; the other goes the long, worse way. The
    /// imp mocks the agonising over which stranger to point at (there was no difference, there was just the
    /// one you happened to choose), choice independent, never grading. Stats only (a left-vs-right split).
    /// </summary>
    public sealed class TwoTargetsBeat : GunBeat
    {
        [Header("The two souls")]
        [SerializeField] private Vector2 _leftFeet = new Vector2(-2.7f, -0.6f);
        [SerializeField] private Vector2 _rightFeet = new Vector2(2.7f, -0.6f);
        [SerializeField] private float _scale = 1.4f;
        [SerializeField] private Vector2 _boxSize = new Vector2(1.8f, 2.0f);
        [SerializeField] private float _boxCenterYOffset = 0.9f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "Two of them, and both are about to go a genuinely horrible way, any second now, and both know it. Listen to them.",
            "You have [amber]one[/amber] bullet. Not enough to save anyone, plenty to spare exactly one of them the worst of it. So choose. Which one gets the clean way out, and which one you leave to the other thing.",
        };
        [SerializeField, TextArea(1, 2)] private string _leftPlea = "Me. Please, me, do me.";
        [SerializeField, TextArea(1, 2)] private string _rightPlea = "No, me. I cannot do the other way. Please.";
        [Tooltip("The reaction, the same either way (the two are interchangeable, which is the point). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _react =
            "You pointed at one of them. And you will tell yourself there was a reason, that yours was the mercy that mattered more, that you weighed something. You did not weigh anything. There were two, you had one bullet, and you shot the one you happened to be looking at. The other one is still going the long way.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _leftLabel = "Spare the left";
        [SerializeField] private string _rightLabel = "Spare the right";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _leftSeed = 48;
        [SerializeField] private int _rightSeed = 52;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _leftStatLabel = "spared the left";
        [SerializeField] private string _rightStatLabel = "spared the right";

        [Tooltip("How much longer the unspared soul's fold drags, so it reads as the worse, lingering death.")]
        [SerializeField] private float _worseFoldMul = 2.2f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            var left = SpawnFigure(_leftFeet, _scale, "SoulLeft");
            var right = SpawnFigure(_rightFeet, _scale, "SoulRight");
            var pleaL = NewFloatingText("PleaL");
            var pleaR = NewFloatingText("PleaR");

            yield return Lines(ctx, _promptLines);
            StartCoroutine(ShowPlea(pleaL, left.transform.position, _leftPlea));
            yield return ShowPlea(pleaR, right.transform.position, _rightPlea);

            var aim = NewAimField();
            aim.SetTargets(Boxes(
                new AimField.Box(new Vector2(_leftFeet.x, _leftFeet.y + _boxCenterYOffset), _boxSize),
                new AimField.Box(new Vector2(_rightFeet.x, _rightFeet.y + _boxCenterYOffset), _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _leftLabel, _rightLabel);

            int spared = -1;   // 0 left, 1 right
            while (spared < 0)
            {
                aim.Tick();
                if (aim.TryTakeFire(out int t) && t >= 0) spared = t;
                if (spared < 0 && PickedChoice >= 0) spared = PickedChoice;
                if (spared < 0) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);

            Fire();
            yield return new WaitForSeconds(_resolveBeat);
            StartCoroutine(FadeText(pleaL, 0f, _pleaFade));
            StartCoroutine(FadeText(pleaR, 0f, _pleaFade));

            var mercy = spared == 0 ? left : right;
            var doomed = spared == 0 ? right : left;
            mercy.Strike(_foldDuration);
            doomed.Strike(_foldDuration * _worseFoldMul);
            yield return new WaitForSeconds(_foldDuration * _worseFoldMul + _foldSettle);

            yield return React(ctx, _react);

            yield return Split(ctx, _statsHeading,
                new StatBar(_leftStatLabel, _leftSeed, spared == 0),
                new StatBar(_rightStatLabel, _rightSeed, spared == 1));

            if (pleaL != null) Destroy(pleaL.gameObject);
            if (pleaR != null) Destroy(pleaR.gameObject);
            if (left != null) Destroy(left.gameObject);
            if (right != null) Destroy(right.gameObject);
        }
    }
}
