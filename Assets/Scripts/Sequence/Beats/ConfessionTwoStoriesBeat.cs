using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>Chapter 7, case 10 (the closer, the one variant): THE TWO STORIES. Two souls file in together,
    /// the two sides of the same dispute, and each tells the same events completely differently, both sincere,
    /// both convinced they were wronged. The player must rule without knowing whose version is true, and never
    /// finds out. Contradictory testimony, the judge's real nightmare, and a fitting close to the docket. [heavy]
    ///
    /// It overrides <see cref="Play"/> to present TWO confessors (one filing in from each side) with two
    /// accounts, then the three verdict ruling (believe her, believe him, or no knowing), reusing every other
    /// protected helper. This is the single two confessor variant of the reusable confession case beat.</summary>
    public sealed class ConfessionTwoStoriesBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Last case. And this is the one that used to keep you awake at night, back when the bench was real wood and the people in front of it still had blood in them.",
                "Two souls. One story. And it does not match. These two were the closest of friends for the better part of their lives, until something between them ended it, hard. They are each going to tell you what happened. They are going to tell you two completely different things.",
                "And here is the part you are going to hate. Neither of them is lying. Not on purpose. Both of them believe every single word. You will never know which one is true. Neither will I. Ready.",
            },
            // Side A (she, on the left) accuses him.
            Account = new[]
            {
                "I told him one thing. One. The single worst thing I have ever done, a thing I never breathed to another living soul, and I told him because he was my best friend and I trusted him with my whole life.",
                "And he told people. He told everyone. He took the one secret I had and handed it round like gossip at a bus stop, and he watched my entire life come apart, and he has never once admitted that it was him.",
            },
            // Side B (he, on the right) accuses her.
            AccountB = new[]
            {
                "That is not what happened. She told me that secret, yes. And then she told other people herself, drunk, at a party, and panicked in the morning, and needed a body to pin it on.",
                "So she picked me. Her best friend. She decided I was the leak because she could not survive being it, and she has told that story so many times now that she genuinely believes it. I lost her over something she did to herself.",
            },
            Headline = "He told everyone.",
            HeadlineB = "She blamed me to survive it.",
            RulePrompt = "So rule. On testimony that cancels clean out, with no evidence coming, not ever. Which of them wronged the other. This is the whole job, judge. It always was.",
            VerdictGuilty = "Believe her",
            VerdictInnocent = "Believe him",
            VerdictBoth = "There is no knowing",
            ReactGuilty = "You believed her. On nothing. On a feeling, on the way she said it, on some tell you are certain you caught, exactly the way you did it from the bench for thirty years. Maybe you are right. You will never find out. That is the job. That was always the job.",
            ReactInnocent = "You believed him. Also on nothing, because there is nothing here, there is only two people and one of them is wrong and cannot feel it. You picked a side. Judges pick. It does not make it true. It just makes it over, for everyone except the two of them.",
            ReactBoth = "You refused to pick. No way to know, so no verdict. Honest. And also completely useless to the two people standing right here who needed this to finally end. For thirty years they never once let you say I cannot know. They made you rule anyway. I am almost impressed you got to say it at last. They are not impressed. Look at them.",
            SeedGuilty = 36,
            SeedInnocent = 30,
            SeedBoth = 34,
            Heading = "how the room ruled",
            HasProfile = true,
            Axis = MoralAxis.MercyVsJustice,
            // The closer's own read: handing down a verdict on a coin you cannot see leans justice; refusing to,
            // leans mercy. Both decisive picks nudge the same way, the "no knowing" middle the other.
            NudgeGuilty = 0.5f,
            NudgeInnocent = 0.5f,
            NudgeBoth = -0.5f,
        };

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Ready()) yield break;
            var data = BuildData();
            _cam = Cam(ctx);
            BeginContent();
            yield return EnsureBooth();

            // Two souls file in, one from each side, and stand apart, facing the bench.
            var figA = SpawnFigure(new Vector2(-_pairOffsetX, _standFeet.y), _confessorScale, "ConfessorA");
            var figB = SpawnFigure(new Vector2(_pairOffsetX, _standFeet.y), _confessorScale, "ConfessorB");
            var inA = StartCoroutine(FileIn(figA, -_fileInFromX, _fileInDuration));
            var inB = StartCoroutine(FileIn(figB, _fileInFromX, _fileInDuration));
            yield return inA;
            yield return inB;

            TextMeshPro hA = null, hB = null;
            if (!string.IsNullOrEmpty(data.Headline)) { hA = NewFloating("HeadlineA"); yield return ShowHeadline(hA, figA, data.Headline); }
            if (!string.IsNullOrEmpty(data.HeadlineB)) { hB = NewFloating("HeadlineB"); yield return ShowHeadline(hB, figB, data.HeadlineB); }

            yield return Lines(ctx, data.Announce);
            yield return Lines(ctx, data.Account);    // her account
            yield return Lines(ctx, data.AccountB);   // his account

            yield return RulePrompt(ctx, data);
            yield return Rule(ctx, data.VerdictGuilty, data.VerdictInnocent, data.VerdictBoth);
            if (hA != null) StartCoroutine(FadeText(hA, 0f, _verdictFade));
            if (hB != null) StartCoroutine(FadeText(hB, 0f, _verdictFade));

            yield return React(ctx, ReactFor(data, _verdict));
            if (data.HasProfile) Nudge(ctx, data.Axis, NudgeFor(data, _verdict));

            // They leave the way they came, still each convinced they were the wronged one.
            var outA = StartCoroutine(FileOut(figA, _fileOutToX, _fileOutDuration));
            var outB = StartCoroutine(FileOut(figB, -_fileOutToX, _fileOutDuration));
            yield return outA;
            yield return outB;

            yield return Reveal(ctx, data, _verdict);
            EndContent();
        }
    }
}
