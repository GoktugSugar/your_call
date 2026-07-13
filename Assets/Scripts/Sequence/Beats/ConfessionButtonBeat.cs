using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>Chapter 7, case 4 (the gag, the mid chapter breather): THE BUTTON'S CONFESSION. The walking
    /// button from the earlier chapters files into the booth and confesses, with total sincerity, to something
    /// trivial and absurd (it once bumped a man in a doorway and did not say sorry), and earnestly demands the
    /// player's verdict. The imp treats it as a completely normal case on the docket. It reuses the walking
    /// button figure and its little floating voice; it keeps the three verdict mechanic (you rule on the
    /// button). Comic relief on the bench. [light, gag]
    ///
    /// It overrides <see cref="Play"/> to run the walking button in place of a stick figure confessor, reusing
    /// every other protected helper (the booth, the announce, the three verdict rule, the reaction, the reveal),
    /// exactly the way the Chapter 5 matchup swaps in the button for one side.</summary>
    public sealed class ConfessionButtonBeat : ConfessionCaseBeat
    {
        [Header("The button (reused gag figure)")]
        [SerializeField] private float _buttonScale = 1.3f;
        [SerializeField] private float _buttonCenterY = -0.55f;
        [SerializeField] private float _comeAliveDuration = 0.5f;
        [SerializeField] private float _voiceHold = 1.6f;
        [SerializeField] private float _voiceFade = 0.3f;

        // The button's own little voice (its floating ink outburst, no bubble, markup aware like the narrator).
        private const string VoiceBump = "I bumped a man. In a doorway.";
        private const string VoiceGuilt = "He remembers it. I would remember it.";
        private const string VoiceBye = "Thank you, your honour. I feel lighter.";

        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Case four. Oh. Oh no. It is you again. The one that walked off. The one I still have a number of unanswered questions about.",
                "It has, and I would like it formally noted that I did not request this, filed to make a confession. A real one. So. Go on then. The court recognises, and I genuinely cannot believe I am saying this out loud, the button.",
            },
            Account = new[]
            {
                "The button wishes the court to know that some time ago, during its travels, it bumped into a man in a doorway. A glancing bump. And it did not say sorry. It has, by its own account, thought about almost nothing else since.",
                "It maintains that the man definitely remembers, is very possibly still upset, and that this makes the button, and I am quoting it directly here, a [red]monster[/red]. It is asking you, in complete earnest, for a ruling.",
            },
            RulePrompt = "The button awaits your verdict on the doorway incident. Do not laugh. It will hear you, and it will take it very hard. Rule.",
            VerdictGuilty = "Guilty. It should apologise",
            VerdictInnocent = "It was nothing, let it go",
            VerdictBoth = "That doorway had two fools",
            ReactGuilty = "You found a button guilty. Of a bump. In a doorway. Some weeks ago. I have watched you sentence people over runaway trolleys and you gave this the exact same grave face. The button, for the record, looks devastated, and also profoundly grateful. It genuinely needed this from you.",
            ReactInnocent = "Acquitted. You looked a small anxious button dead in the eye and told it that it did nothing wrong, and it believed you completely, because you are a judge and it is a button and this is the closest thing to therapy either of you can currently afford.",
            ReactBoth = "Everyone in that doorway sucks, including the man, who has no idea any of this happened and has not thought about it once. A perfectly balanced verdict for a completely imaginary crime. The button is nodding along. It agrees. It always agrees. It just wanted to be here.",
            SeedGuilty = 14,
            SeedInnocent = 61,
            SeedBoth = 25,
            Heading = "how the room ruled",
        };

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Ready()) yield break;
            if (_kit.WalkingButtonPrefab == null)
            {
                Debug.LogError("[ConfessionButtonBeat] '" + Note + "' has no WalkingButton prefab on its ConfessionKit.");
                yield break;
            }
            var data = BuildData();
            _cam = Cam(ctx);
            BeginContent();
            yield return EnsureBooth();

            // The button files in as a plain button (sliding + inking), then comes to life at the booth.
            var button = Instantiate(_kit.WalkingButtonPrefab, _content);
            button.name = "TheButton";
            button.transform.localPosition = new Vector3(_fileInFromX, _buttonCenterY, 0f);
            button.transform.localScale = new Vector3(_buttonScale, _buttonScale, 1f);
            button.SetAlpha(0f);
            yield return SlideButtonIn(button, 0f, _fileInDuration);
            yield return button.ComeAlive(_comeAliveDuration);

            var voice = NewFloating("ButtonVoice");
            yield return Voice(voice, button.transform, VoiceBump);

            yield return Lines(ctx, data.Announce);
            yield return Voice(voice, button.transform, VoiceGuilt);
            yield return Lines(ctx, data.Account);

            yield return RulePrompt(ctx, data);
            yield return Rule(ctx, data.VerdictGuilty, data.VerdictInnocent, data.VerdictBoth);

            yield return React(ctx, ReactFor(data, _verdict));

            // It thanks the court and walks off, a little lighter, the way it always leaves.
            yield return Voice(voice, button.transform, VoiceBye);
            yield return button.WalkOff(_fileOutToX - 1f);

            yield return Reveal(ctx, data, _verdict);
            EndContent();
        }

        // Slide the (not yet alive) button in from off screen while inking it on.
        private IEnumerator SlideButtonIn(WalkingButton button, float toX, float dur)
        {
            float fromX = button.transform.localPosition.x, y = button.transform.localPosition.y;
            float t = 0f, d = Mathf.Max(dur, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                button.transform.localPosition = new Vector3(Mathf.Lerp(fromX, toX, k), y, 0f);
                button.SetAlpha(Mathf.Clamp01(k * 1.3f));
                yield return null;
            }
            button.transform.localPosition = new Vector3(toX, y, 0f);
            button.SetAlpha(1f);
        }

        // Its little floating voice above the button: fade in, hold to read, fade out (markup aware).
        private IEnumerator Voice(TextMeshPro label, Transform buttonTf, string line)
        {
            if (label == null) yield break;
            label.transform.position = buttonTf.position + new Vector3(0f, _buttonScale * 0.95f + 0.2f, 0f);
            label.text = InkMarkup.ToRichText(Localization.Localize(line));
            yield return FadeText(label, 1f, _voiceFade);
            yield return new WaitForSeconds(_voiceHold);
            yield return FadeText(label, 0f, _voiceFade);
        }
    }
}
