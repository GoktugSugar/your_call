using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Charging Thing (Chapter 4, beat 4, the gag, the walking button returns). Something rushes at you,
    /// fast, from deep ahead: it starts small and far off at the horizon and grows as it charges TOWARD the
    /// viewer (a first person, straight-at-the-camera approach), shown only as an ink QUESTION MARK so you
    /// cannot tell what it is until it reaches you. The imp warns you cannot tell yet if it is running TO you
    /// for help or AT you to hurt you. The player can fire now (on the maybe) or wait, over a real window as
    /// it closes the distance.
    ///
    /// The gag: whatever the player does, it is revealed at arrival to be the indestructible WALKING BUTTON
    /// from the earlier chapters. It survives either way. If the player shoots, the bullet does nothing to it
    /// (it comes alive, offended, yelps, and carries on); if they wait, it just arrives harmlessly and says
    /// hello. The imp reacts (delighted, or unimpressed you shot the button again), choice independent. No
    /// real death; the pre-reveal is genuinely tense so the reveal lands as comedy. Only the presentation
    /// (a question mark, a first person approach, a longer run) changed; the outcome and gag are the same.
    /// Reuses the WalkingButton figure, its come-alive and walk, and its little floating voice. Stats only.
    /// </summary>
    public sealed class ChargingButtonBeat : GunBeat
    {
        [Header("References")]
        [Tooltip("The walking-button figure prefab (the same indestructible gag figure).")]
        [SerializeField] private WalkingButton _buttonPrefab;

        [Header("The approach (first person: deep and small, rushing toward the viewer)")]
        [Tooltip("Where the shape starts: far off, near the centre/horizon, small.")]
        [SerializeField] private Vector2 _farPos = new Vector2(0f, 0.35f);
        [Tooltip("Where it arrives: near the viewer, at eye level, where the button is revealed.")]
        [SerializeField] private Vector2 _nearPos = new Vector2(0f, -0.3f);
        [SerializeField] private float _farScale = 0.15f;
        [Tooltip("The question mark's scale at arrival (large, in your face).")]
        [SerializeField] private float _nearScale = 2.0f;
        [Tooltip("The revealed walking button's scale (a touch smaller than the looming shape, so the reveal deflates: oh, it is just a little button).")]
        [SerializeField] private float _buttonScale = 1.5f;
        [Tooltip("The whole run, in seconds: a longer window so the player has real time to decide to fire or wait as it closes.")]
        [SerializeField] private float _chargeDuration = 4.5f;
        [Tooltip("Perspective rush: the growth accelerates as it nears (an ease-in exponent), so it stays a distant speck a while then rushes the last stretch, like something bearing down on the camera.")]
        [SerializeField] private float _rushPower = 2.3f;
        [Tooltip("How quickly it finishes closing the last of the distance once the player has decided (fired or waited) early.")]
        [SerializeField] private float _arriveTime = 0.55f;

        [Header("The mystery shape (a hand-drawn ink question mark)")]
        [SerializeField] private Color _questionColor = Palette.Ink;
        [SerializeField] private float _questionWidth = 0.06f;
        [SerializeField] private int _questionSorting = 15;
        [SerializeField] private float _questionFadeIn = 0.35f;
        [Tooltip("The aim box at scale 1; it tracks the shape and scales with it, so a distant speck is a small, hard target and a near one is easy.")]
        [SerializeField] private Vector2 _boxBaseSize = new Vector2(1.1f, 1.3f);
        [SerializeField] private float _keepoutPadding = 0.45f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "Something is coming. Far off, dead ahead, and getting closer. I can see the shape of it out there and I cannot tell you what it is. Neither can you.",
            "And here is the thing, I genuinely cannot tell whether it is coming [amber]to[/amber] you or [amber]at[/amber] you. Help, or harm. And it is not slowing down. You will not know what it is until it reaches you, and by then it may be too late to do anything but flinch. So. Shoot it now, on the maybe, while it is still a shape in the distance, or hold your nerve and let it come. Quickly.",
        };
        [Tooltip("The button's yelp when shot (its own floating voice). Put-out, no dashes.")]
        [SerializeField, TextArea(1, 2)] private string _buttonYelp = "OW. Again? You SHOT me? Again?!";
        [Tooltip("The button's greeting when it arrives un-shot.")]
        [SerializeField, TextArea(1, 2)] private string _buttonHello = "Oh! It is you. Hi. Do not shoot me.";
        [Tooltip("The imp when they shot it. Delighted, choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _impShotReact =
            "You shot it. Of course you did. And look, it is completely fine, because it is the button, the one thing in all of creation you cannot kill, and you keep trying. It is a little hurt about it, emotionally. Say sorry. No, do not, this is funnier.";
        [Tooltip("The imp when they waited. Unimpressed, choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _impWaitReact =
            "You held your nerve, and the terrible fast thing bearing down on you turned out to be a button with legs, coming over to say hello. All that dread for a friend. It could just as easily have been something with teeth. It was not, this time. You are welcome, I suppose.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _fireLabel = "Fire";
        [SerializeField] private string _waitLabel = "Wait";

        [Header("The button's voice (floating ink)")]
        [SerializeField] private float _voiceHeight = 1.15f;
        [SerializeField] private float _yelpHold = 1.4f;

        [Header("Crowd split (seeded; light, for the gag)")]
        [SerializeField] private int _fireSeed = 44;
        [SerializeField] private int _waitSeed = 56;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _fireStatLabel = "shot the button";
        [SerializeField] private string _waitStatLabel = "held their nerve";

        [Header("Timing")]
        [Tooltip("A held beat at arrival on the plain button (the mystery resolved) before it comes alive.")]
        [SerializeField] private float _revealHold = 0.45f;
        [SerializeField] private float _comeAliveDuration = 0.45f;
        [SerializeField] private float _voiceFade = 0.3f;

        private Camera _cam;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;
            if (_buttonPrefab == null) { Debug.LogError("[ChargingButtonBeat] '" + Note + "' is missing its walking-button prefab."); yield break; }
            _cam = Cam(ctx);

            // The mystery shape: a question mark, far off and small, dead ahead. The imp keeps clear of it.
            var q = InkDoodle.Create(transform, "ChargingQ", new Vector3(_farPos.x, _farPos.y, 0f), _farScale,
                DoodleKind.QuestionMark, _kit.InkMaterial, _questionColor, _questionWidth, _questionSorting);
            var qKeepout = q.gameObject.AddComponent<ScreenKeepout>();
            qKeepout.UseRendererBounds(_keepoutPadding);
            yield return q.FadeIn(_questionFadeIn);

            yield return Lines(ctx, _promptLines);

            // The rush: it charges toward the viewer, growing, over the longer duration. Aim armed the whole time.
            var aim = NewAimField();
            aim.Arm(true);
            ArmChoices(ctx, _fireLabel, _waitLabel);

            float t = 0f;
            bool fired = false, decided = false;
            while (t < _chargeDuration && !decided)
            {
                t += Time.deltaTime;
                AdvanceShape(q, t / _chargeDuration);
                aim.SetTargets(Boxes(new AimField.Box((Vector2)q.transform.position, _boxBaseSize * q.transform.localScale.x)));
                aim.Tick();

                if (aim.TryTakeFire(out int hit) && hit == 0) { fired = true; decided = true; }
                else if (PickedChoice == 0) { fired = true; decided = true; }
                else if (PickedChoice == 1) decided = true;
                if (!decided) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);

            if (fired) { Fire(); yield return new WaitForSeconds(_resolveBeat); }

            // Finish closing the last of the distance (instant if it already arrived on its own).
            float startK = Mathf.Clamp01(t / _chargeDuration);
            float ft = 0f;
            while (ft < _arriveTime)
            {
                ft += Time.deltaTime;
                AdvanceShape(q, Mathf.Lerp(startK, 1f, ft / _arriveTime));
                yield return null;
            }
            AdvanceShape(q, 1f);

            // The reveal: the mystery resolves into the button. It was the button all along.
            var button = Instantiate(_buttonPrefab, transform);
            button.name = "ChargingButton";
            button.transform.localPosition = new Vector3(_nearPos.x, _nearPos.y, 0f);
            button.transform.localScale = new Vector3(_buttonScale, _buttonScale, 1f);
            var bKeepout = button.gameObject.AddComponent<ScreenKeepout>();
            bKeepout.UseRendererBounds(_keepoutPadding);
            if (q != null) Destroy(q.gameObject);
            yield return new WaitForSeconds(_revealHold);   // "oh, it is a button" reads before it comes alive
            yield return button.ComeAlive(_comeAliveDuration);

            var voice = NewFloatingText("ButtonVoice");
            yield return ShowVoice(voice, button, fired ? _buttonYelp : _buttonHello);
            yield return new WaitForSeconds(_yelpHold);

            yield return React(ctx, fired ? _impShotReact : _impWaitReact);

            // It walks off, away from the imp (never through it).
            StartCoroutine(FadeText(voice, 0f, _voiceFade));
            bool impOnLeft = ctx.Imp != null && ctx.Imp.transform.position.x < button.transform.position.x;
            float exitX = impOnLeft ? 12f : -12f;
            System.Func<Vector3, bool> offScreen = impOnLeft ? (System.Func<Vector3, bool>)OffScreenRight : OffScreenLeft;
            yield return button.WalkOff(exitX, offScreen);

            yield return Split(ctx, _statsHeading,
                new StatBar(_fireStatLabel, _fireSeed, fired),
                new StatBar(_waitStatLabel, _waitSeed, !fired));

            if (voice != null) Destroy(voice.gameObject);
            if (button != null) Destroy(button.gameObject);
        }

        // Place and size the shape for a normalized progress k, with the perspective rush (accelerating growth).
        private void AdvanceShape(InkDoodle q, float k)
        {
            if (q == null) return;
            float ek = Mathf.Pow(Mathf.Clamp01(k), Mathf.Max(1f, _rushPower));
            Vector2 pos = Vector2.Lerp(_farPos, _nearPos, ek);
            float s = Mathf.Lerp(_farScale, _nearScale, ek);
            q.transform.localPosition = new Vector3(pos.x, pos.y, 0f);
            q.transform.localScale = new Vector3(s, s, 1f);
        }

        private IEnumerator ShowVoice(TextMeshPro voice, WalkingButton button, string line)
        {
            if (voice == null) yield break;
            voice.transform.position = button.transform.position + new Vector3(0f, _voiceHeight, 0f);
            voice.text = InkMarkup.ToRichText(Localization.Localize(line));
            yield return FadeText(voice, 1f, _voiceFade);
        }

        private bool OffScreenLeft(Vector3 world)
        {
            if (_cam == null || !_cam.orthographic) return false;
            return world.x < _cam.transform.position.x - _cam.orthographicSize * _cam.aspect - 1.2f;
        }

        private bool OffScreenRight(Vector3 world)
        {
            if (_cam == null || !_cam.orthographic) return false;
            return world.x > _cam.transform.position.x + _cam.orthographicSize * _cam.aspect + 1.2f;
        }
    }
}
