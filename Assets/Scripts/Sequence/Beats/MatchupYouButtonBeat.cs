using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>Chapter 5, matchup 6 (the callback gag): YOU vs the Walking Button. The player against the
    /// indestructible button from the earlier chapters, reused whole. The imp needles that the player is not
    /// as sure as they want to be, given the button's track record. The button is spawned as its live figure
    /// (not a doodle) and comes alive as a cheeky, offended fighter.</summary>
    public sealed class MatchupYouButtonBeat : MatchupBeat
    {
        [Header("The button (reused callback figure)")]
        [SerializeField] private float _buttonScale = 1.6f;
        [SerializeField] private float _wakeDelay = 0.2f;
        [SerializeField] private float _comeAliveDuration = 0.5f;

        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "Now a personal one. [amber]You[/amber] versus the button. Yes, that button. The one you keep meeting. The one you shot, that got up and walked off without a word.",
                "Sit with your record against it for a moment. It has been [red]shot[/red], pressed, cursed, auctioned off, and it once came charging straight at your face out of the pitch dark, and every single time it simply got up, a little offended, and left. And here you are. A dead man. Fists up. So. [amber]You[/amber], or the one thing in all of creation you have never once managed to kill.",
            },
            A = MatchupSide.Solo("You", DoodleKind.Brawler, Palette.InkGreen),
            B = MatchupSide.Solo("the button", DoodleKind.None, Palette.Ink),   // the live button figure is spawned in PopulateSide
            ReactA = "[amber]You[/amber]. You backed yourself against the one thing that has proven, over and over, that it cannot die. That is either magnificent self belief or you have learned absolutely nothing in here. It is watching you, by the way. It looks a touch hurt that you would even ask.",
            ReactB = "The [amber]button[/amber]. Betting against yourself. Bleak. Also, honestly, the smart money. It has a far better survival record than anyone in this room, and one of us is already dead.",
            SeedA = 34,
            SeedB = 66,
            Heading = "how the bar voted",
        };

        protected override void PopulateSide(SideView view, MatchupSide side)
        {
            if (view.Index == 1 && _kit.WalkingButtonPrefab != null)
            {
                var button = Instantiate(_kit.WalkingButtonPrefab, view.Root);
                button.name = "TheButton";
                button.transform.localPosition = Vector3.zero;
                button.transform.localScale = new Vector3(_buttonScale, _buttonScale, 1f);
                button.SetAlpha(0f);
                view.Button = button;
                return;
            }
            base.PopulateSide(view, side);
        }

        protected override IEnumerator OnSidesShown(SequenceContext ctx)
        {
            if (_sideB != null && _sideB.Button != null)
            {
                yield return new WaitForSeconds(_wakeDelay);
                yield return _sideB.Button.ComeAlive(_comeAliveDuration);
            }
        }
    }
}
