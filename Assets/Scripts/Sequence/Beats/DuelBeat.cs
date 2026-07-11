using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Duel (Chapter 4, beat 7). Someone across from you also has a gun, aimed at you. The imp says
    /// neither of you has to fire (you are already dead, it changes nothing), but they might, and so might
    /// you. Lower it and trust them, or shoot first.
    ///
    /// Shoot first and the opponent folds; the imp mocks that you dropped someone who might never have pulled,
    /// over nothing, since you were both already dead. Lower it and the outcome resolves against a seeded
    /// standoff: they fire (and it passes harmlessly through a dead man) or they lower too. Either way the imp
    /// mocks the trust, choice independent, never grading. Silent nudge on self vs others (shoot first vs trust).
    /// </summary>
    public sealed class DuelBeat : GunBeat
    {
        [Header("References")]
        [Tooltip("The duel opponent prefab (a DuelistFigure, a stick figure leveling a pistol back at you).")]
        [SerializeField] private Figure _duelistPrefab;

        [Header("The opponent")]
        [SerializeField] private Vector2 _feet = new Vector2(0.4f, -0.6f);
        [SerializeField] private float _scale = 1.45f;
        [SerializeField] private Vector2 _boxCenter = new Vector2(0.1f, 0.35f);
        [SerializeField] private Vector2 _boxSize = new Vector2(2.4f, 2.0f);

        [Header("Standoff (seeded)")]
        [Tooltip("If the player lowers and trusts, the chance the other one fires anyway (harmless, you are already dead). A seeded standoff.")]
        [SerializeField, Range(0f, 1f)] private float _opponentFiresChance = 0.5f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "This one is armed too, and pointing it right back at you. A proper standoff. How exciting.",
            "Now. Neither of you actually has to fire. You are already dead, so a bullet in you changes precisely nothing, and I suspect the same is true of them. But they might pull anyway. People do. And so might you. So. Trust them and lower it, or put one in them first. Your call, as ever.",
        };
        [Tooltip("If they shoot first. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _shootReact =
            "You shot first. Dropped a stranger who was maybe, maybe, never going to pull at all, because you could not stand not knowing, could not sit in one second of trusting anybody. And it changed nothing. You were both already dead. You just wanted to be the one who got there first.";
        [Tooltip("If they lower and the other fires. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _trustFiredReact =
            "You lowered it. You trusted them. And they fired. The shot went straight through you and out the other side, because, again, you are dead, and your trust cost you nothing and bought you nothing and taught them nothing. But it was a lovely gesture. Truly. Idiotic, and lovely.";
        [Tooltip("If they lower and the other lowers too. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _trustHeldReact =
            "You lowered it, and so did they. Two dead people, standing in the dark, choosing not to shoot each other over a thing that could not have hurt either of you. Beautiful. Pointless. I might frame it. You trusted a stranger with a bullet that was never real, and you were right, and it means absolutely nothing, and you feel good about it anyway.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _shootLabel = "Shoot first";
        [SerializeField] private string _lowerLabel = "Lower it";

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _shootSeed = 46;
        [SerializeField] private int _lowerSeed = 54;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _shootStatLabel = "shot first";
        [SerializeField] private string _lowerStatLabel = "lowered it";

        [Header("Profile (silent; self vs others, light)")]
        [Tooltip("Shooting first (getting there before they can) leans self (negative); trusting them leans others (positive).")]
        [SerializeField] private float _selfNudge = 0.25f;

        [Header("Timing")]
        [SerializeField] private float _opponentFireDelay = 0.7f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;
            var prefab = _duelistPrefab != null ? _duelistPrefab : _kit.FigurePrefab;

            var opponent = Instantiate(prefab, new Vector3(_feet.x, _feet.y, 0f), Quaternion.identity, transform);
            opponent.name = "Duelist";
            opponent.transform.localScale = new Vector3(_scale, _scale, 1f);

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(Boxes(new AimField.Box(_boxCenter, _boxSize)));
            aim.Arm(true);
            ArmChoices(ctx, _shootLabel, _lowerLabel);

            int decision = -1;   // 0 shoot first, 1 lower
            while (decision < 0)
            {
                aim.Tick();
                if (aim.TryTakeFire(out int t) && t == 0) decision = 0;
                if (decision < 0 && PickedChoice >= 0) decision = PickedChoice;
                if (decision < 0) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);
            bool shotFirst = decision == 0;

            string react;
            if (shotFirst)
            {
                Fire();
                yield return new WaitForSeconds(_resolveBeat);
                opponent.Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
                react = _shootReact;
            }
            else
            {
                // The seeded standoff: do they fire anyway?
                bool theyFire = Random.value < _opponentFiresChance;
                if (theyFire)
                {
                    yield return new WaitForSeconds(_opponentFireDelay);
                    Fire();   // their shot, harmless (you are already dead)
                    yield return new WaitForSeconds(_resolveBeat + 0.2f);
                    react = _trustFiredReact;
                }
                else
                {
                    yield return new WaitForSeconds(_opponentFireDelay);
                    react = _trustHeldReact;
                }
            }

            Nudge(ctx, MoralAxis.SelfVsOthers, shotFirst ? -_selfNudge : _selfNudge);
            yield return React(ctx, react);

            yield return Split(ctx, _statsHeading,
                new StatBar(_shootStatLabel, _shootSeed, shotFirst),
                new StatBar(_lowerStatLabel, _lowerSeed, !shotFirst));

            if (opponent != null) Destroy(opponent.gameObject);
        }
    }
}
