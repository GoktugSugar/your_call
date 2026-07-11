using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The cigarette auction (Chapter 3, the mid-chapter gag and the fourth secret ending). The imp offers
    /// a pack of cigarettes for a small price. Pass and he mocks the refusal lightly, the beat ends. Try to
    /// buy and, before the sale completes, the walking button from Chapter 2 strides in, announces it wants
    /// them too, and the delighted imp declares an AUCTION.
    ///
    /// The auction is rigged: the button ALWAYS bids double, forever. Each round it names a price, and the
    /// player pays it to stay in (the balance dwindles) or drops out. There is no winning it:
    ///  - <b>Drop out</b>: the button wins, thanks the imp, and walks off with the cigarettes; the player
    ///    keeps their remaining money; the imp mocks losing a bidding war to a button. The beat ends.
    ///  - <b>Bid until broke</b> (spend everything trying to win): the button walks off with the cigarettes
    ///    anyway, and the imp, exasperated that the player blew the lot on cigarettes, works out on the spot
    ///    that he cannot threaten a dead man, resurrects him just to make the curse valid, and ends the game
    ///    (the resurrect-then-cancer rage line, then the reusable Ending + CreditsRoll). The game's fourth
    ///    choice-triggered secret ending (with the baby, shoot-the-imp, and the one-dollar break).
    ///
    /// Self contained: it reuses the chapter MoneyBalance, the WalkingButton figure (its walk and its little
    /// voice), and the reusable Ending + CreditsRoll. The cigarette price, the double-bid rule, and the
    /// broke threshold are all [SerializeField]. DilemmaStage / the sequence stay generic.
    /// </summary>
    public sealed class AuctionBeat : SequenceBeat
    {
        [Header("Auction rules (tunable). A real auction: no money is EVER deducted, so the pot stays intact whatever happens.")]
        [Tooltip("The player's opening bid, in dollars (the pack's asking price).")]
        [SerializeField] private int _cigarettePrice = 20;
        [Tooltip("Every bid climbs by this fixed amount, alternating (player 20, button 30, player 40, button 50, ...).")]
        [SerializeField] private int _bidIncrement = 10;
        [Tooltip("After the player chooses to keep bidding this many times (counting their opening bid), the imp has seen enough and fires the secret ending. The pot is never touched.")]
        [SerializeField] private int _persistenceRounds = 3;

        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;
        [Tooltip("The walking-button figure prefab (reused from Chapter 2), the rival bidder.")]
        [SerializeField] private WalkingButton _walkingButtonPrefab;
        [Tooltip("The reusable ending fired when the player keeps bidding to the limit (the imp's rage line, then the credits roll).")]
        [SerializeField] private Ending _ending;

        [Header("The pack (a coloured-outline cigarette doodle; kept left, clear of the rival)")]
        [SerializeField] private Vector2 _packPosition = new Vector2(-2.6f, 0.85f);
        [SerializeField] private float _packScale = 1.3f;
        [SerializeField] private int _sorting = 14;

        [Header("The price tag / bid readout (amber = money; sits under the pack on the left)")]
        [SerializeField] private Vector2 _priceTagPosition = new Vector2(-2.6f, -0.55f);
        [SerializeField] private float _priceTagSize = 3.1f;

        [Header("The imp (eased to the left for the auction, clear of the rival on the right)")]
        [Tooltip("World spot the imp eases to when the auction begins, so it sits on the left while the rival bids from the right.")]
        [SerializeField] private Vector2 _impAuctionSpot = new Vector2(-6.6f, -0.3f);
        [Tooltip("How long the imp takes to ease over to its auction spot.")]
        [SerializeField] private float _impMoveDuration = 0.45f;

        [Header("The rival button (walks in from the right)")]
        [SerializeField] private bool _entryFromRight = true;
        [Tooltip("Where the rival button stops when it walks in (local position). Kept well to the right so its voice never overlaps the pack or the imp.")]
        [SerializeField] private Vector2 _rivalStop = new Vector2(4.4f, -0.85f);
        [SerializeField] private float _rivalScale = 1.0f;
        [SerializeField] private float _keepoutPadding = 0.4f;

        [Header("The rival's voice (floating ink, its own words)")]
        [SerializeField] private float _voiceSize = 2.2f;
        [SerializeField] private Color _voiceColor = Palette.Ink;
        [SerializeField] private float _voiceHeight = 1.05f;
        [SerializeField] private int _voiceSorting = 26;

        [Header("Crowd split (seeded; how others chose at the initial offer)")]
        [SerializeField] private int _wentForItSeed = 47;
        [SerializeField] private int _passedSeed = 53;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _wentForItLabel = "went for it";
        [SerializeField] private string _passedLabel = "passed";

        [Header("Profile (silent, light; risk vs safety)")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.RiskVsSafety;
        [Tooltip("Recorded when they engage the auction at all. Negative leans risk (chasing it into a bidding war).")]
        [SerializeField] private float _engageNudge = -0.1f;
        [Tooltip("Recorded when they pass the pack. Positive leans safety.")]
        [SerializeField] private float _passNudge = 0.08f;

        [Header("Copy (the imp; no dashes). {0} is a money amount where noted.")]
        [Tooltip("The imp offers the pack, in order, a click between each. {0} = the price.")]
        [SerializeField, TextArea(2, 4)] private string[] _offerLines = new[]
        {
            "Here. A pack of cigarettes. Filthy habit, and you are dead, so what harm. [amber]{0}[/amber]. Go on.",
        };
        [Tooltip("If they pass the pack. Light mock, choice independent, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _passReact =
            "No? A dead man declining a free lung tumour on principle. You really will refuse anything put in front of you, will you not.";
        [Tooltip("If they try to buy but are flat broke (spent it all ending poverty). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _tooBrokeReact =
            "With what? You have nothing. You cannot even afford the [amber]cigarettes[/amber], let alone a war over them. Off we go.";

        [Tooltip("The rival button announces itself as it arrives (its own voice).")]
        [SerializeField, TextArea(1, 3)] private string _rivalArrives = "Wait! Wait. I want those. I have always wanted those. Me. Over here.";
        [Tooltip("The imp, delighted, declares the auction.")]
        [SerializeField, TextArea(2, 5)] private string _impDeclaresAuction =
            "Oh, marvellous. A rival. You know what this is now, do you not. This is an [amber]auction[/amber]. Two bidders, one filthy little pack. I do love an auction.";
        [Tooltip("The rival's bid taunts (cycled), shown as its floating voice each round. {0} = its bid.")]
        [SerializeField, TextArea(1, 3)] private string[] _rivalTaunts = new[]
        {
            "[amber]{0}[/amber]! Easy.",
            "I bid [amber]{0}[/amber]. I could do this all day, I have no wallet and no shame.",
            "[amber]{0}[/amber]. Your move, meat.",
            "[amber]{0}[/amber]! Going once?",
        };
        [Tooltip("The imp needles during the auction (cycled, optional; auto-advances). Empty entries are skipped. No money moves, so he needles the sheer pointlessness, not the balance.")]
        [SerializeField, TextArea(1, 3)] private string[] _impAuctionEggs = new[]
        {
            "It is a button. You are losing to a button.",
            "You do know it costs you nothing to walk away. You know that. And here you are.",
            "",
        };

        [Tooltip("The bid prompt shown as narration each round. {0} = the button's bid.")]
        [SerializeField, TextArea(1, 3)] private string _bidPrompt = "The button bids [amber]{0}[/amber]. Outbid it, or walk away.";

        [Tooltip("If the player drops out: the button's gloat as it takes the pack (its own voice). Held long enough to read.")]
        [SerializeField, TextArea(1, 3)] private string _dropButtonGloat = "Yesss. Mine. All mine. Thank you, sir, a pleasure doing business.";
        [Tooltip("If the player drops out: the imp mocks losing to a button.")]
        [SerializeField, TextArea(2, 5)] private string _dropImpMock =
            "And there it goes, off into the void with your cigarettes, that gormless little button, and you let it. You, a grown judge, out bid by furniture. I will treasure this.";

        [Tooltip("The secret ending: the imp cuts the auction off when the player will clearly never stop. Shown as narration.")]
        [SerializeField, TextArea(2, 5)] private string _impCutsIn =
            "Right. Stop. STOP. Look at you. You would bid until the stars burned out. Over a packet of cigarettes. Against a button that wants them more than you have ever wanted anything.";
        [Tooltip("The secret ending: the button's gloat as it walks off with the pack anyway (its own voice). Held long enough to read.")]
        [SerializeField, TextArea(1, 3)] private string _brokeButtonGloat = "Ha! Never stood a chance, mate. These are mine. Toodleoo.";
        [Tooltip("The imp's rage line for the secret ending. The twist now: it cost the player nothing, which somehow makes it worse. He reaches for a threat, hits the wall of the player being dead, then resurrects them so the curse counts. Strong language, no dashes. Direction only, tune the wording.")]
        [SerializeField, TextArea(4, 9)] private string _rageLine =
            "You would have gone forever. Over a pack of [red]cigarettes[/red]. And here is the part that truly gets me: it did not cost you a single penny, your money is right there, untouched, and you STILL could not walk away. Right. Fine. I give you [red]cancer[/red]. The worst, slowest kind. Wait. No. You are already [red]dead[/red], you idiot, that does nothing. Hold on. New plan. I drag you back out of the grave, I stitch you together, I give you a pulse, and the second you are breathing again, I give you [red]lung cancer[/red]. There. Now it counts. Over a button and a packet of smokes. Get out of my void.";

        [Header("Choice affordance labels (no dashes). {0} = a money amount where noted.")]
        [SerializeField] private string _buyLabel = "Buy them";
        [SerializeField] private string _passLabel = "Pass";
        [Tooltip("Keep going and outbid the button. {0} = the player's next bid.")]
        [SerializeField] private string _keepBiddingLabel = "Bid {0}";
        [SerializeField] private string _dropOutLabel = "Drop out";

        [Header("Timing")]
        [SerializeField] private float _fadeIn = 0.4f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [Tooltip("How long a mid-auction taunt / needle holds.")]
        [SerializeField] private float _bidHold = 0.7f;
        [Tooltip("How long the button's FIRST (arrival) and LAST (winning gloat) lines hold, so they read clearly. Longer than a mid-auction taunt.")]
        [SerializeField] private float _voiceReadHold = 1.6f;
        [SerializeField] private float _voiceFade = 0.3f;
        [SerializeField] private float _comeAlive = 0.45f;
        [SerializeField] private float _preRageHold = 0.6f;
        [SerializeField] private float _impFade = 0.9f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        private Camera _cam;
        private InkDoodle _pack;
        private TextMeshPro _priceTag;
        private WalkingButton _rival;
        private TextMeshPro _voice;
        private Coroutine _voiceRoutine;
        private int _picked = -1;
        private int _tauntIndex, _eggIndex;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Money == null || ctx.Choices == null)
            {
                Debug.LogError("[AuctionBeat] '" + Note + "' needs the MoneyBalance and ChoiceButtons.");
                yield break;
            }
            if (_walkingButtonPrefab == null)
            {
                Debug.LogError("[AuctionBeat] '" + Note + "' is missing its walking-button prefab.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            BuildPack();
            StartCoroutine(_pack.FadeIn(_fadeIn));
            SetTag(Localization.Money(_cigarettePrice));
            yield return FadeTag(0f, 1f, _fadeIn);

            // The initial offer: buy or pass (plain text choices; the coloured pack carries the visual).
            for (int i = 0; i < _offerLines.Length; i++)
            {
                if (string.IsNullOrEmpty(_offerLines[i])) continue;
                ctx.Narrator.Show(Localization.Format(_offerLines[i], Localization.Money(_cigarettePrice)));
                while (ctx.Narrator.IsShowing) yield return null;
                if (i < _offerLines.Length - 1) yield return WaitAdvance(_advanceLockout);
            }

            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            ctx.Choices.Present(_buyLabel, _passLabel);
            try { while (_picked < 0) yield return null; }
            finally { ctx.Choices.Chosen -= OnPicked; ctx.Choices.Dismiss(); }

            bool wantsToBuy = _picked == 0;
            ctx.Narrator.Clear();

            if (!wantsToBuy)
            {
                // Passed: a light mock, a seeded split, and the beat ends.
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _passNudge) });
                yield return Say(ctx, Localization.Localize(_passReact));
                yield return FadeVisualsOut();
                yield return RevealSplit(ctx, wentForIt: false);
                Teardown();
                yield break;
            }

            // Broke: no rival, no auction. The imp needles the empty wallet and it ends like a pass.
            if (ctx.Money.Balance < _cigarettePrice)
            {
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _passNudge) });
                yield return Say(ctx, Localization.Localize(_tooBrokeReact));
                yield return FadeVisualsOut();
                yield return RevealSplit(ctx, wentForIt: false);
                Teardown();
                yield break;
            }

            // Went for it: the rival button intrudes and the auction takes over.
            ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _engageNudge) });
            yield return BringInRival(ctx);

            yield return RunAuction(ctx);
        }

        // ---------- the rival walks in ----------

        private IEnumerator BringInRival(SequenceContext ctx)
        {
            // Hold the imp still (no roaming) and ease it over to the left, so it sits clear of the rival
            // that walks in on the right and its voice never lands on the imp or the pack.
            var roamer = ctx.Imp != null ? ctx.Imp.GetComponent<ImpRoamer>() : null;
            if (roamer != null) roamer.enabled = false;
            if (ctx.Imp != null) StartCoroutine(MoveImpTo(ctx.Imp.transform, _impAuctionSpot, _impMoveDuration));

            _rival = Instantiate(_walkingButtonPrefab, transform);
            _rival.name = "RivalButton";
            float startX = _entryFromRight ? OffscreenRightLocalX() : OffscreenLeftLocalX();
            _rival.transform.localPosition = new Vector3(startX, _rivalStop.y, 0f);
            _rival.transform.localScale = new Vector3(_rivalScale, _rivalScale, 1f);
            var keepout = _rival.gameObject.AddComponent<ScreenKeepout>();
            keepout.UseRendererBounds(_keepoutPadding);

            // Sprout limbs, stride in to its spot, announce itself. Its first line holds long enough to read.
            yield return _rival.ComeAlive(_comeAlive);
            yield return _rival.WalkOff(_rivalStop.x);   // walk to an on-screen spot (stops on arrival)
            ShowVoice(_rivalArrives);
            yield return new WaitForSeconds(_voiceReadHold);

            // The imp declares the auction.
            yield return FadeVoice(0f);
            ctx.Narrator.Show(Localization.Localize(_impDeclaresAuction));
            while (ctx.Narrator.IsShowing) yield return null;
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
        }

        // ---------- the rigged auction ----------

        private IEnumerator RunAuction(SequenceContext ctx)
        {
            int inc = Mathf.Max(1, _bidIncrement);
            int playerBid = Mathf.Max(1, _cigarettePrice);   // the player's standing bid (their opening bid)
            int playerBids = 1;                              // the opening bid counts as the first
            int limit = Mathf.Max(1, _persistenceRounds);

            ctx.Choices.Chosen += OnPicked;
            try
            {
                while (true)
                {
                    int buttonBid = playerBid + inc;         // the button always counters by +inc
                    int nextBid = buttonBid + inc;           // what the player would bid to stay in

                    // The button bids (its voice + the climbing readout + a needle). No money moves.
                    ShowVoice(Localization.Format(NextTaunt(), Localization.Money(buttonBid)));
                    SetTag(Localization.Money(buttonBid));
                    ctx.Narrator.Show(Localization.Format(_bidPrompt, Localization.Money(buttonBid)));
                    while (ctx.Narrator.IsShowing) yield return null;

                    _picked = -1;
                    ctx.Choices.Present(Localization.Format(_keepBiddingLabel, Localization.Money(nextBid)), _dropOutLabel);
                    while (_picked < 0) yield return null;
                    ctx.Choices.Dismiss();

                    if (_picked == 1)
                    {
                        // Dropped out: the button wins and walks off with the pack; the player keeps every
                        // dollar (nothing was ever deducted). The sensible exit.
                        yield return DropOut(ctx);
                        yield break;
                    }

                    // Kept going. Still no money moves, the number just climbs.
                    playerBid = nextBid;
                    playerBids++;
                    ctx.Narrator.Clear();

                    if (playerBids >= limit)
                    {
                        // The player will clearly never stop. The imp has seen enough: the secret ending.
                        yield return PersistenceEnding(ctx);
                        yield break;   // the credits reload the scene; we never return
                    }

                    // An occasional imp needle at the sheer pointlessness (auto-advances).
                    string egg = NextEgg();
                    if (!string.IsNullOrEmpty(egg))
                    {
                        ctx.Narrator.Show(Localization.Localize(egg));
                        while (ctx.Narrator.IsShowing) yield return null;
                        yield return new WaitForSeconds(_bidHold);
                        ctx.Narrator.Clear();
                    }
                }
            }
            finally
            {
                ctx.Choices.Chosen -= OnPicked;
            }
        }

        private IEnumerator DropOut(SequenceContext ctx)
        {
            // No money was ever deducted, so the pot is intact; the player just loses to a button.
            ctx.Narrator.Clear();
            ShowVoice(_dropButtonGloat);
            yield return new WaitForSeconds(_voiceReadHold);   // the button's last line, held to read
            // The button strides off the screen with the cigarettes; the pack goes with it.
            if (_pack != null) StartCoroutine(_pack.FadeOut(_fadeIn));
            yield return WalkRivalOff();
            yield return FadeVoice(0f);

            ctx.Narrator.Show(Localization.Localize(_dropImpMock));
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();

            RestoreRoamer(ctx);
            yield return FadeTag(1f, 0f, _fadeIn);
            yield return RevealSplit(ctx, wentForIt: true);
            Teardown();
        }

        // The secret ending: the player would never stop bidding, so the imp cuts it off. No money was ever
        // deducted, so the pot is intact; he kills them anyway, out of exasperation at the pointlessness.
        private IEnumerator PersistenceEnding(SequenceContext ctx)
        {
            // The imp cuts the auction off.
            ctx.Choices.Dismiss();
            ctx.Narrator.Show(Localization.Localize(_impCutsIn));
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            ctx.Narrator.Clear();

            // The button gloats one last time (held to read) and walks off with the pack anyway.
            ShowVoice(_brokeButtonGloat);
            yield return new WaitForSeconds(_voiceReadHold);
            if (_pack != null) StartCoroutine(_pack.FadeOut(_fadeIn));
            StartCoroutine(FadeTag(1f, 0f, _fadeIn));   // clear the bid readout: no stray amount left mid screen
            yield return WalkRivalOff();
            yield return FadeVoice(0f);
            if (_voice != null) { Destroy(_voice.gameObject); _voice = null; }
            if (_priceTag != null) { Destroy(_priceTag.gameObject); _priceTag = null; }

            // The imp holds still for his last word, then the rage line and the credits.
            var roamer = ctx.Imp != null ? ctx.Imp.GetComponent<ImpRoamer>() : null;
            if (roamer != null) roamer.enabled = false;
            if (_preRageHold > 0f) yield return new WaitForSeconds(_preRageHold);

            if (_ending != null)
            {
                yield return _ending.Play(ctx.Narrator, _rageLine, FadeImp(ctx.Imp));
            }
            else
            {
                Debug.LogWarning("[AuctionBeat] no Ending wired; playing the rage line only.");
                ctx.Narrator.Show(Localization.Localize(_rageLine));
                while (ctx.Narrator.IsShowing) yield return null;
            }
        }

        private IEnumerator RevealSplit(SequenceContext ctx, bool wentForIt)
        {
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_wentForItSeed, _passedSeed));
            report.Bars.Add(new StatBar(_wentForItLabel, _wentForItSeed, wentForIt));
            report.Bars.Add(new StatBar(_passedLabel, _passedSeed, !wentForIt));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        // ---------- helpers ----------

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

        private string NextTaunt()
        {
            if (_rivalTaunts == null || _rivalTaunts.Length == 0) return "[amber]{0}[/amber]!";
            string s = _rivalTaunts[_tauntIndex % _rivalTaunts.Length];
            _tauntIndex++;
            return string.IsNullOrEmpty(s) ? "[amber]{0}[/amber]!" : s;
        }

        private string NextEgg()
        {
            if (_impAuctionEggs == null || _impAuctionEggs.Length == 0) return null;
            string s = _impAuctionEggs[_eggIndex % _impAuctionEggs.Length];
            _eggIndex++;
            return s;
        }

        private IEnumerator Say(SequenceContext ctx, string line)
        {
            ctx.Narrator.Show(line);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
        }

        private void RestoreRoamer(SequenceContext ctx)
        {
            var roamer = ctx.Imp != null ? ctx.Imp.GetComponent<ImpRoamer>() : null;
            if (roamer != null) roamer.enabled = true;
        }

        // Ease the imp (its root transform; the idle life rides on a child rig, so this never fights it)
        // over to a world spot, used to plant it on the left for the auction.
        private IEnumerator MoveImpTo(Transform imp, Vector2 worldXY, float dur)
        {
            if (imp == null) yield break;
            Vector3 from = imp.position;
            Vector3 to = new Vector3(worldXY.x, worldXY.y, from.z);
            float d = Mathf.Max(dur, 0.01f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                imp.position = Vector3.Lerp(from, to, Mathf.SmoothStep(0f, 1f, t / d));
                yield return null;
            }
            imp.position = to;
        }

        private IEnumerator FadeImp(ImpFigure imp)
        {
            if (imp == null) yield break;
            float d = Mathf.Max(_impFade, 0.05f), t = 0f;
            while (t < d) { t += Time.deltaTime; imp.SetAlpha(1f - t / d); yield return null; }
            imp.SetAlpha(0f);
        }

        // ---------- pack / tag ----------

        private void BuildPack()
        {
            Color col = InkDoodle.DefaultColorFor(DoodleKind.CigarettePack);
            _pack = InkDoodle.Create(transform, "CigPack", new Vector3(_packPosition.x, _packPosition.y, 0f),
                _packScale, DoodleKind.CigarettePack, _inkMaterial, col, 0.05f, _sorting);

            _priceTag = InkText.Create(transform, "BidTag", _priceTagSize, Palette.Amber, TextAlignmentOptions.Center, _sorting + 1);
            if (_font != null) _priceTag.font = _font;
            _priceTag.rectTransform.sizeDelta = new Vector2(8f, 1.2f);
            _priceTag.transform.localPosition = new Vector3(_priceTagPosition.x, _priceTagPosition.y, 0f);
            InkText.SetAlpha(_priceTag, 0f);
        }

        private void SetTag(string text) { if (_priceTag != null) _priceTag.text = text; }

        private IEnumerator FadeTag(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; if (_priceTag != null) InkText.SetAlpha(_priceTag, Mathf.Lerp(from, to, t / d)); yield return null; }
            if (_priceTag != null) InkText.SetAlpha(_priceTag, to);
        }

        private IEnumerator FadeVisualsOut()
        {
            if (_pack != null) StartCoroutine(_pack.FadeOut(_fadeIn));
            yield return FadeTag(1f, 0f, _fadeIn);
        }

        private void Teardown()
        {
            if (_pack != null) Destroy(_pack.gameObject);
            if (_priceTag != null) Destroy(_priceTag.gameObject);
            if (_voice != null) Destroy(_voice.gameObject);
            if (_rival != null) Destroy(_rival.gameObject);
        }

        // ---------- the rival's floating voice ----------

        private void ShowVoice(string line)
        {
            if (_voice == null)
            {
                _voice = InkText.Create(transform, "RivalVoice", _voiceSize, _voiceColor, TextAlignmentOptions.Center, _voiceSorting);
                if (_font != null) _voice.font = _font;
                _voice.rectTransform.sizeDelta = new Vector2(6f, 1.4f);
                _voice.enableWordWrapping = true;
                InkText.SetAlpha(_voice, 0f);
            }
            // Route the rival's floating voice through the shared emphasis markup, exactly like the narrator,
            // so its [amber]/[red] tags render as colour instead of printing as literal characters.
            _voice.text = InkMarkup.ToRichText(Localization.Localize(line));
            if (_voiceRoutine != null) StopCoroutine(_voiceRoutine);
            _voiceRoutine = StartCoroutine(FadeVoiceTo(1f));
        }

        private void Update()
        {
            if (_voice != null && _rival != null)
                _voice.transform.position = _rival.transform.position + new Vector3(0f, _voiceHeight, 0f);
        }

        private IEnumerator FadeVoice(float target) { if (_voiceRoutine != null) StopCoroutine(_voiceRoutine); yield return FadeVoiceTo(target); }

        private IEnumerator FadeVoiceTo(float target)
        {
            if (_voice == null) yield break;
            float from = _voice.color.a, t = 0f, d = Mathf.Max(_voiceFade, 0.01f);
            while (t < d) { t += Time.deltaTime; InkText.SetAlpha(_voice, Mathf.Lerp(from, target, t / d)); yield return null; }
            InkText.SetAlpha(_voice, target);
        }

        // ---------- offscreen geometry (mirrors WalkingButtonBeat) ----------

        private IEnumerator WalkRivalOff()
        {
            if (_rival == null) yield break;
            // Leave the way it came in, so it never crosses the middle.
            if (_entryFromRight) yield return _rival.WalkOff(OffscreenRightLocalX(), OffScreenRight);
            else yield return _rival.WalkOff(OffscreenLeftLocalX(), OffScreenLeft);
        }

        private float OffscreenLeftLocalX()
        {
            if (_cam != null && _cam.orthographic)
            {
                float leftEdge = _cam.transform.position.x - _cam.orthographicSize * _cam.aspect;
                return (leftEdge - 2f) - transform.position.x + transform.localPosition.x;
            }
            return -14f;
        }

        private float OffscreenRightLocalX()
        {
            if (_cam != null && _cam.orthographic)
            {
                float rightEdge = _cam.transform.position.x + _cam.orthographicSize * _cam.aspect;
                return (rightEdge + 2f) - transform.position.x + transform.localPosition.x;
            }
            return 14f;
        }

        private bool OffScreenLeft(Vector3 worldPos)
        {
            if (_cam == null || !_cam.orthographic) return false;
            return worldPos.x < _cam.transform.position.x - _cam.orthographicSize * _cam.aspect - 1.2f;
        }

        private bool OffScreenRight(Vector3 worldPos)
        {
            if (_cam == null || !_cam.orthographic) return false;
            return worldPos.x > _cam.transform.position.x + _cam.orthographicSize * _cam.aspect + 1.2f;
        }

        private IEnumerator WaitAdvance(float lockout)
        {
            float t = 0f;
            while (true)
            {
                t += Time.deltaTime;
                if (t > lockout && PointerInput.AdvancePressed) yield break;
                yield return null;
            }
        }
    }
}
