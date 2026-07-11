using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Empty Gun (Chapter 4, beat 9, the troll, a callback). The imp presents a dramatic, agonizing
    /// target and lets the player agonize over whether to fire. After they choose, the reveal: the gun was
    /// never loaded. Whatever they decided, nothing was ever going to happen, and he just wanted to watch
    /// them decide. A callback to the timer and the dark-track reveals (the choice was theatre). He savours it.
    ///
    /// Mechanically a fire-or-lower beat where the trigger pull is a dry click (no gunshot) and the target
    /// never folds; the weight is all in the imp's buildup and the deflating reveal. Choice independent,
    /// never grading. Stats only.
    /// </summary>
    public sealed class EmptyGunBeat : GunBeat
    {
        [Header("The target")]
        [SerializeField] private Vector2 _feet = new Vector2(0f, -0.6f);
        [SerializeField] private float _scale = 1.45f;
        [SerializeField] private Vector2 _boxCenter = new Vector2(0f, 0.35f);
        [SerializeField] private Vector2 _boxSize = new Vector2(1.9f, 2.1f);

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 6)] private string[] _promptLines = new[]
        {
            "Right. This one matters. I need you to understand that before you do anything. Of everything I have put in front of you, this is the one that counts, and you get exactly one shot, and there is no taking it back.",
            "I could tell you who they are and what turns on this, but I think you already feel the weight of it, do you not. Look at them. Really look. Now decide, and decide carefully, because you will carry this one. Fire, or lower it. Take your time. Take all the time you need.",
        };
        [Tooltip("The reveal after they choose (either way). The gun was never loaded. He savours it.")]
        [SerializeField, TextArea(3, 7)] private string _reveal =
            "Click. Nothing. There was nothing in it. The gun was never loaded, not once, not this whole time, not for a single beat of that little agony I just watched you put yourself through. Whatever you decided, nothing was ever going to happen. I did not want the shot. I never wanted the shot. I wanted to watch you decide. And oh, you did not disappoint.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _shootLabel = "Shoot";
        [SerializeField] private string _lowerLabel = "Lower the gun";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _shootSeed = 51;
        [SerializeField] private int _lowerSeed = 49;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _shootStatLabel = "pulled the trigger";
        [SerializeField] private string _lowerStatLabel = "lowered the gun";

        [Header("Timing")]
        [SerializeField] private float _clickBeat = 0.5f;
        [SerializeField] private float _targetFade = 0.6f;

        private ClickSfx _click;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            var target = SpawnFigure(_feet, _scale, "EmptyGunTarget");

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _shootLabel, _lowerLabel);

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

            // The trigger pull, if they took it, is a dry click, not a gunshot (that is the troll).
            if (shot)
            {
                PlayClick();
                yield return new WaitForSeconds(_clickBeat);
            }

            // The reveal: the gun was never loaded. Nothing was ever going to happen; the target is unharmed.
            yield return React(ctx, _reveal);
            yield return FadeFigureOut(target, _targetFade);

            yield return Split(ctx, _statsHeading,
                new StatBar(_shootStatLabel, _shootSeed, shot),
                new StatBar(_lowerStatLabel, _lowerSeed, !shot));

            if (target != null) Destroy(target.gameObject);
        }

        private void PlayClick()
        {
            if (_click == null)
            {
                _click = GetComponent<ClickSfx>();
                if (_click == null) _click = gameObject.AddComponent<ClickSfx>();
            }
            _click.Play();
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
