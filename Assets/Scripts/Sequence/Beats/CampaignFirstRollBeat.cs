using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 3, The First Roll. The beat that teaches the die. Dice are rare and special in this
    /// chapter (only two beats use one), so this one exists to introduce the mechanic: a situation that needs a
    /// roll, the odds shown on the die, the player rolls, and the imp narrates whatever comes up and needles the
    /// player on how they take luck. There is no branching outcome (the story rolls on whether you make the roll
    /// or not, no fail state); it is purely the teach. It overrides <see cref="SequenceBeat.Play"/> for the dice
    /// rather than returning option data. [dice beat 1]
    /// </summary>
    public sealed class CampaignFirstRollBeat : CampaignBeat
    {
        [Header("Dice (this beat)")]
        [Tooltip("The die is a d6; a roll of this or higher clears the situation. The odds line reads it out.")]
        [SerializeField] private int _dieTarget = 3;
        [SerializeField] private float _dieScale = 1.8f;
        [SerializeField] private Vector2 _diePos = new Vector2(0f, 0.7f);
        [SerializeField] private float _dieShow = 0.5f;
        [SerializeField] private float _rollDuration = 1.7f;
        [SerializeField] private float _dieHide = 0.4f;

        // Play is overridden for the dice; BuildData is never called.
        protected override CampaignData BuildData(CampaignState state) => null;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Ready()) yield break;
            _cam = Cam(ctx);
            var state = _kit.State;
            BeginContent();

            yield return Line(ctx, ClassSetup(state.Class));
            yield return Line(ctx, "This is the part where we roll. See the die. Six sides, one number, pure dumb chance, and for one moment neither of us is in charge of the story. Not you. Not even me. I love it and I hate it in exactly equal measure.");

            var die = DiceRoll.Create(_content, "Die", _diePos, _dieScale, _kit.InkMaterial, _kit.Font);
            die.SetOdds(Localization.Format("roll a [amber]{0}[/amber] or higher and you clear it", _dieTarget));
            yield return die.Show(_dieShow);

            yield return Line(ctx, "Go on. Roll it. Click the die, click anything, I am not precious about the how.");
            yield return WaitAdvance(_advanceLockout);

            int landing = Random.Range(1, 7);
            yield return die.Roll(landing, _rollDuration);
            bool cleared = landing >= _dieTarget;

            yield return Line(ctx, cleared
                ? "It comes up good. You clear it, clean and lucky and completely undeserved. Feel that little jolt in your chest just now, that warm rush. That is luck, and you, my friend, are already hooked on it."
                : "It comes up short. You do not clear it. The fall, the splash, the indignity, all rendered in loving detail. Do not panic, you are the protagonist, you are fine. But do notice how betrayed you feel. By a cube. That I control.");

            yield return React(ctx, "Interesting, how fast you took a number personally. A die landed and you already have feelings about whether the universe is fond of you. Hold onto that feeling. We are going to want it later, when it actually counts.");

            yield return die.Hide(_dieHide);
            EndContent();
        }

        private static string ClassSetup(CampaignClass cls)
        {
            switch (cls)
            {
                case CampaignClass.Knight: return "A chasm splits the road ahead, wider than sense allows. A knight does not go around a chasm. A knight backs up, and takes a run at it.";
                case CampaignClass.Rogue: return "A locked gate, an old and clever lock, and your picks in your hand. Most locks open for a rogue. Most of them. Let us find out about this one.";
                case CampaignClass.Wizard: return "A warded door, humming with someone else's spell, and you reaching for the counter you are almost, almost certain is the right one.";
                case CampaignClass.Bard: return "A bridge troll wants a toll, or a song, and you have decided, against all advice including mine, on a song.";
                case CampaignClass.Cleric: return "A fevered child at the roadside, too hot to the touch, and your two hands, and a prayer you are not at all certain will land.";
                default: return "A chasm splits the road ahead, wider than sense allows, and you back up to take a run at it.";
            }
        }
    }
}
