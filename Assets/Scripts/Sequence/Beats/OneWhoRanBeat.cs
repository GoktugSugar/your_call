using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The One Who Ran (Chapter 4, beat 3). Two people were told to run for their lives. One kept running and
    /// left the other behind to be caught; the other would not go without his friend, and so he was caught.
    /// Now both stand before your gun. One bullet, and the imp wants you to spend it: on the coward who saved
    /// himself, or on the loyal one who is only here because he would not run. This is not about suffering
    /// (nobody is suffering); it is about desert and loyalty, who has it coming.
    ///
    /// A two-target aim over the reused crosshair: the player fires on the loyal one or the one who ran (or
    /// picks via the text fallback). Whichever they shoot folds; the other lives and walks. The imp mocks
    /// whichever (justice for the betrayer, or sparing the coward and putting down the good fool), choice
    /// independent, never grading. It is a genuine split (loyalty and desert pull both ways). Stats only.
    /// </summary>
    public sealed class OneWhoRanBeat : GunBeat
    {
        [Header("The two (left = the loyal one who stayed, right = the one who ran)")]
        [SerializeField] private Vector2 _loyalFeet = new Vector2(-2.7f, -0.6f);
        [SerializeField] private Vector2 _runnerFeet = new Vector2(2.7f, -0.6f);
        [SerializeField] private float _scale = 1.4f;
        [SerializeField] private Vector2 _boxSize = new Vector2(1.8f, 2.0f);
        [SerializeField] private float _boxCenterYOffset = 0.9f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "These two were told to run. Simple. Run, do not stop, do not look back. One of them did exactly that, and left the other behind to be caught. The other would not go without his friend. So he stayed, and he was caught. And now, look, here they both are.",
            "You have [amber]one[/amber] bullet, and I would like you to spend it. Not on suffering, nobody here is suffering. On desert. Who has it coming. The coward who saved his own skin, or the loyal one who is only standing here because he would not save his. Whichever you shoot, the other walks free. Aim, or do not.",
        };
        [Tooltip("Floated over the loyal one (left), kept above the head.")]
        [SerializeField, TextArea(1, 2)] private string _loyalPlea = "I stayed. I would not leave him.";
        [Tooltip("Floated over the one who ran (right), kept above the head.")]
        [SerializeField, TextArea(1, 2)] private string _runnerPlea = "I ran. I am still breathing.";
        [Tooltip("If they shoot the loyal one who stayed. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _shotLoyalReact =
            "You shot the one who stayed. The good one, whose only crime was refusing to leave a friend behind, and you put the bullet in him and let the one who ran walk off whistling. Mercy, tell yourself, ending the loyal fool before his loyalty could cost him one thing more. Or maybe you just quietly respect a survivor. The one who ran certainly does. Look at him go.";
        [Tooltip("If they shoot the one who ran. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _shotRunnerReact =
            "You shot the one who ran. Justice, you are telling yourself, the betrayer got what betrayers get. Very neat. Or you simply could not stand the smug little miracle of a thing that chose itself and lived. Either way the loyal one goes free now, rewarded for the loyalty that got him caught, and he gets to carry forever the knowledge that he only made it out because you did his hating for him.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _loyalLabel = "Shoot the loyal one";
        [SerializeField] private string _runnerLabel = "Shoot the one who ran";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _loyalSeed = 43;
        [SerializeField] private int _runnerSeed = 57;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _loyalStatLabel = "shot the loyal one";
        [SerializeField] private string _runnerStatLabel = "shot the one who ran";

        [Header("Timing")]
        [Tooltip("How long the survivor takes to walk / fade out (they live).")]
        [SerializeField] private float _leaveFade = 0.9f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            var loyal = SpawnFigure(_loyalFeet, _scale, "LoyalOne");
            var runner = SpawnFigure(_runnerFeet, _scale, "TheRunner");
            var pleaLoyal = NewFloatingText("PleaLoyal");
            var pleaRunner = NewFloatingText("PleaRunner");

            yield return Lines(ctx, _promptLines);
            StartCoroutine(ShowPlea(pleaLoyal, loyal, _loyalPlea));
            yield return ShowPlea(pleaRunner, runner, _runnerPlea);

            var aim = NewAimField();
            aim.SetTargets(Boxes(
                new AimField.Box(new Vector2(_loyalFeet.x, _loyalFeet.y + _boxCenterYOffset), _boxSize),
                new AimField.Box(new Vector2(_runnerFeet.x, _runnerFeet.y + _boxCenterYOffset), _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _loyalLabel, _runnerLabel);

            int shot = -1;   // 0 loyal, 1 runner
            while (shot < 0)
            {
                aim.Tick();
                if (aim.TryTakeFire(out int t) && t >= 0) shot = t;
                if (shot < 0 && PickedChoice >= 0) shot = PickedChoice;
                if (shot < 0) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);
            bool shotRunner = shot == 1;

            Fire();
            yield return new WaitForSeconds(_resolveBeat);
            StartCoroutine(FadeText(pleaLoyal, 0f, _pleaFade));
            StartCoroutine(FadeText(pleaRunner, 0f, _pleaFade));

            var struck = shotRunner ? runner : loyal;
            var survivor = shotRunner ? loyal : runner;
            struck.Strike(_foldDuration);
            yield return new WaitForSeconds(_foldDuration + _foldSettle);

            // The other lives: they walk free while the imp reads the choice back.
            StartCoroutine(FadeFigureOut(survivor, _leaveFade));
            yield return React(ctx, shotRunner ? _shotRunnerReact : _shotLoyalReact);

            yield return Split(ctx, _statsHeading,
                new StatBar(_loyalStatLabel, _loyalSeed, !shotRunner),
                new StatBar(_runnerStatLabel, _runnerSeed, shotRunner));

            if (pleaLoyal != null) Destroy(pleaLoyal.gameObject);
            if (pleaRunner != null) Destroy(pleaRunner.gameObject);
            if (loyal != null) Destroy(loyal.gameObject);
            if (runner != null) Destroy(runner.gameObject);
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
