using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>Chapter 5, matchup 10 (the callback finale, personalized): EVERYTHING YOU HAVE KILLED SO FAR
    /// vs YOU. The imp tallies the things the player killed across the game and sends them all at once against
    /// the player. The mob is built from the run's <see cref="KillLog"/> when it recorded any (so a full
    /// playthrough is personalised), and falls back to an authored roster of the game's known killables (the
    /// bear and a spread of the people) so the finale always lands, including Chapter 5 played on its own via
    /// the dev picker. All drawn red, the vengeful dead. Ties the whole game back onto the player; the imp
    /// relishes it, choice independent, never grades.</summary>
    public sealed class MatchupKilledEverythingBeat : MatchupBeat
    {
        [Header("The mob of the dead")]
        [Tooltip("Cap on how many figures to actually draw (representative of the mob, not the literal tally).")]
        [SerializeField] private int _maxUnits = 13;
        [Tooltip("The colour of the vengeful dead (red = death, coming for you).")]
        [SerializeField] private Color _deadColor = Palette.InkRed;

        private List<CrowdUnit> _roster;

        protected override MatchupData BuildData()
        {
            _roster = BuildRoster();
            return new MatchupData
            {
                Setup = new[]
                {
                    "Last one. And this one is personal, because I have been keeping count the whole time. You have done a fair amount of [red]killing[/red] to get this far. The bear. Whoever was standing on those tracks. That man, or the other one. Every soul you folded up for a number, or a laugh, or for nothing at all.",
                    "So here is the final matchup. [red]Everything you have killed[/red], every last one of them, all at once, versus [amber]you[/amber]. They have been waiting. They remember every detail. And it is a great many of them against [amber]one[/amber] dead judge with his fists up. Who wins.",
                },
                A = MatchupSide.Mob("everyone you killed", DoodleKind.Brawler, _deadColor, _roster != null ? _roster.Count : 10),
                B = MatchupSide.Solo("You", DoodleKind.Brawler, Palette.InkGreen),
                ReactA = "The [red]dead[/red]. You looked at everything you have ever killed, massing up and coming for you all at once, and you backed THEM. Honest, at least. A man who knows exactly what he has earned.",
                ReactB = "[amber]You[/amber]. Against everyone you killed. The sheer, magnificent nerve of it. They outnumber you enormously and each and every one of them has a deeply personal reason to be here. But sure. Fists up. Best of luck.",
                SeedA = 58,
                SeedB = 42,
                Heading = "how the bar voted",
            };
        }

        // Side A is the mob of the dead (index 0); side B (You) falls through to the plain doodle.
        protected override void PopulateSide(SideView view, MatchupSide side)
        {
            if (view.Index == 0)
            {
                BuildCrowd(view, _roster);
                return;
            }
            base.PopulateSide(view, side);
        }

        // The mob is an authored roster of the game's known killables, so it is always a full, satisfying crowd
        // that always includes the bear (the prompt's sanctioned fallback), with the run's actually-recorded
        // kills folded in on top, so a full playthrough that killed something unusual sees it in the mob too.
        // Full per-kill tracking across every killing beat is a later step (see docs/open-questions.md); today
        // the bear opener records its shot into KillLog and the roster covers the rest.
        private List<CrowdUnit> BuildRoster()
        {
            var units = new List<CrowdUnit>
            {
                new CrowdUnit(DoodleKind.Grizzly, _deadColor),   // the last bear
            };
            for (int i = 0; i < 8; i++) units.Add(new CrowdUnit(DoodleKind.Brawler, _deadColor));  // the people

            var log = KillLog.Instance;
            if (log != null)
            {
                for (int i = 0; i < log.Kills.Count && units.Count < _maxUnits; i++)
                {
                    var k = log.Kills[i];
                    if (!ContainsKind(units, k.Doodle)) units.Add(new CrowdUnit(k.Doodle, _deadColor));
                }
            }
            if (units.Count > _maxUnits) units.RemoveRange(_maxUnits, units.Count - _maxUnits);
            return units;
        }

        private static bool ContainsKind(List<CrowdUnit> units, DoodleKind kind)
        {
            for (int i = 0; i < units.Count; i++) if (units[i].Kind == kind) return true;
            return false;
        }
    }
}
