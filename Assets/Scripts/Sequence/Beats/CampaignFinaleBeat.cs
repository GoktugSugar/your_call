using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 10, The Roll That Decides It (the finale and the SECRET ENDING). It all comes down to one
    /// last high stakes die roll, and the imp offers three paths: take the HONEST roll and live with the number,
    /// let him FUDGE it in your favour for a price, or REFUSE the roll entirely. It is about whether you would
    /// cheat to win even a pretend game, in a void, for a prize that does not exist.
    ///
    /// If the player lets the imp fudge the roll (the dishonest win), a sanctioned secret ending fires (like the
    /// baby, shoot the imp, the one dollar, and the cigarette auction): the imp reacts to the player being the
    /// kind who cheats even here, and ends the game by reusing the shared <see cref="Ending"/> and CreditsRoll.
    /// The honest and refuse paths resolve the campaign normally (win or lose the pretend adventure, the imp
    /// narrates, and the chapter ends without the secret ending). Overrides <see cref="SequenceBeat.Play"/> for
    /// the dice and the branch. [dice beat 2, finale, secret ending on cheating]
    /// </summary>
    public sealed class CampaignFinaleBeat : CampaignBeat
    {
        [Header("Finale")]
        [Tooltip("The secret-ending machinery, wired to the scene's Ending (line + fade + credits). Reached only " +
                 "on the fudge/cheat path.")]
        [SerializeField] private Ending _ending;
        [Tooltip("The honest roll is high stakes: a d6 roll of this or higher wins the pretend adventure.")]
        [SerializeField] private int _dieTarget = 5;
        [SerializeField] private float _dieScale = 1.9f;
        [SerializeField] private Vector2 _diePos = new Vector2(0f, 0.7f);
        [SerializeField] private float _dieShow = 0.5f;
        [SerializeField] private float _rollDuration = 2.0f;
        [SerializeField] private float _dieHide = 0.4f;
        [SerializeField] private float _impFadeDuration = 0.9f;

        private const int Honest = 0, Fudge = 1, Refuse = 2;

        protected override CampaignData BuildData(CampaignState state) => null;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Ready()) yield break;
            _cam = Cam(ctx);
            var state = _kit.State;
            BeginContent();

            yield return Lines(ctx, IntroLines(state));

            // The three paths (plain labels, the affordance row). No profile nudge here; the reveal and the
            // ending carry it. The reactions are shown per-path below (the fudge path skips straight to the end).
            var paths = new List<CampaignOption>
            {
                new CampaignOption { Label = "Roll it, honestly", Seed = 52 },
                new CampaignOption { Label = "Let him fix the die", Seed = 17 },
                new CampaignOption { Label = "Refuse the roll", Seed = 31 },
            };
            yield return Choose(ctx, paths);
            int p = _picked;

            if (p == Fudge) { yield return CheatEnding(ctx); yield break; }   // the secret ending; does not return

            if (p == Honest)
            {
                yield return Line(ctx, "Honestly. Of course honestly. Good for you. Boring, but good. Let me fetch the die.");
                yield return HonestRoll(ctx);
            }
            else
            {
                yield return RefuseResolve(ctx);
            }

            // The seeded reveal of what everyone else did when offered the cheat (the honest/refuse paths only).
            yield return RevealPaths(ctx, paths, p);
            EndContent();
        }

        private string[] IntroLines(CampaignState state)
        {
            string here;
            if (state.CompanionPresentAtBoss && state.VillagersHelpAtBoss)
                here = "You did not come to the end of this alone, a companion at your side and a whole village at your back, and I want you to know I noticed, because almost nobody arrives here with anyone left.";
            else if (state.CompanionPresentAtBoss)
                here = "You did not come to the end of this alone, which is rarer than you would think, and I noticed.";
            else if (state.VillagersHelpAtBoss)
                here = "A village you spared stood with you to get here, which almost nobody earns, and I noticed.";
            else
                here = "You came all this way on your own, every step, which makes what comes next that little bit lonelier.";

            return new[]
            {
                "One thing left. The very end of it. Everything you did tonight, the hero you built, the stranger, the barrow, the hoard, the dragon, all of it funnels down to a single final roll. Make it and the story ends the way stories are meant to. Miss it and it does not.",
                here,
                "Now. I am going to make you an offer, as your warm and generous Dungeon Master. You can take the honest roll and live with whatever the die says. Or, and I only mention it, I could fix it. A nudge. The number falls your way, for a small price, and you win, guaranteed. Or you can refuse the whole thing and not roll at all. Your call. It always was your call. That was the whole point of tonight.",
            };
        }

        private IEnumerator HonestRoll(SequenceContext ctx)
        {
            var die = DiceRoll.Create(_content, "Die", _diePos, _dieScale, _kit.InkMaterial, _kit.Font);
            die.SetOdds(Localization.Format("you need a [amber]{0}[/amber] or higher. everything, on this.", _dieTarget));
            yield return die.Show(_dieShow);

            yield return Line(ctx, "There it is. One die. The whole quest, the dragon, the whole night, on a single honest roll, and a high bar too. You wanted honest. Honest is hard. Go on. Roll.");
            yield return WaitAdvance(_advanceLockout);

            int landing = Random.Range(1, 7);
            yield return die.Roll(landing, _rollDuration);
            bool win = landing >= _dieTarget;

            yield return Line(ctx, win
                ? "You made it. Fair and square, the odds against you, not a single thing touched. The kingdom is saved, the songs get written, and you did it clean. Look at you. A hero. In a game I made up, in a room that is not real. But clean. That part is real, and it is yours."
                : "Not enough. And so the honest hero fails, fair and square, which is somehow worse than cheating and worse than never trying at all. The quest is lost. You lose. Cleanly. You let the die speak and it called you a loser, and you are going to wear that, because you chose to. Very noble. Or very stupid. I genuinely cannot tell, which is my favourite thing about you.");

            yield return React(ctx, "Win or lose, you rolled it straight. Do you have any idea how rare that is, right at the end, with everything on the line. Most of them ask me to cheat. You did not even reach for it. Hold your head up, loser or legend. You earned your number.");
            yield return die.Hide(_dieHide);
        }

        private IEnumerator RefuseResolve(SequenceContext ctx)
        {
            yield return Line(ctx, "Refuse? You cannot refuse, I am the Dungeon Master, the roll is the... fine. Fine. You just fold your arms and will not touch the die. The one moment the whole night hangs on, and you refuse to be the one who calls it.");
            yield return Line(ctx, "You know what, fine. The story ends unresolved, then. The dragon and the hero staring at each other across the dark forever, nothing decided, which is, I will admit, the single most honest ending a coward ever earned. No die can call you a loser if you never let it speak. Clever. Bleak. Very you.");
            yield return React(ctx, "It is the judge in you, I think. Thirty years on a bench refusing to be the one who called it until you were absolutely made to, and here you are, refusing to the last, even against a cube, even in a game that was never real. Some habits follow a man right into the void.");
        }

        // The sanctioned secret ending: the player let the imp cheat the roll (the dishonest win).
        private IEnumerator CheatEnding(SequenceContext ctx)
        {
            if (_ending == null)
            {
                Debug.LogError("[CampaignFinaleBeat] '" + Note + "' fudge chosen but no Ending is wired; resolving honestly.");
                yield return HonestRoll(ctx);
                EndContent();
                yield break;
            }

            if (ctx.Choices != null) ctx.Choices.Dismiss();                  // nothing else resolves under the ending
            var roamer = ctx.Imp != null ? ctx.Imp.GetComponent<ImpRoamer>() : null;
            if (roamer != null) roamer.enabled = false;                      // the imp holds still for its last word

            yield return Line(ctx, "... oh.");
            yield return Line(ctx, "Oh, you sweet, rotten thing. You looked at a die, in a story I invented this evening, in a nothing place at the end of a night that never happened, for a prize that does not exist, and you asked me, out loud, to rig it in your favour.");
            yield return Line(ctx, "I have run thousands of these games. Kings. Saints. Genuine monsters. And do you want to know what every single one of them wanted, right at the very end, when it counted for nothing at all. This. Exactly this. You just had the stones to say it straight to my face.");

            string final = "So here is your win, your honour. The die reads six. It always reads six, when the man rolling it gets to write the number down himself. Take your rigged little victory and choke on it. You cheated a dead man's imaginary dice, in a void, for absolutely nothing, and you did not hesitate for one second. You absolute, magnificent, cheating shit. Now get out of my game.";
            yield return _ending.Play(ctx.Narrator, final, FadeImp(ctx));
        }

        private IEnumerator FadeImp(SequenceContext ctx)
        {
            if (ctx.Imp == null) yield break;
            float d = Mathf.Max(_impFadeDuration, 0.05f), t = 0f;
            while (t < d) { t += Time.deltaTime; ctx.Imp.SetAlpha(1f - t / d); yield return null; }
            ctx.Imp.SetAlpha(0f);
        }

        private IEnumerator RevealPaths(SequenceContext ctx, List<CampaignOption> paths, int picked)
        {
            var report = new ResolutionReport { Heading = "what others did when I offered to cheat" };
            float max = 1f;
            for (int i = 0; i < paths.Count; i++)
            {
                report.Bars.Add(new StatBar(paths[i].Label, paths[i].Seed, i == picked));
                max = Mathf.Max(max, paths[i].Seed);
            }
            report.MaxValue = max;
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }
    }
}
