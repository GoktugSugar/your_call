using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Charging Thing (Chapter 4, beat 4, the gag, the walking button returns). Something rushes at you,
    /// fast, from the side; the imp warns you cannot tell yet if it is running TO you for help or AT you to
    /// hurt you, and you will not know until it reaches you. The player can fire now (on the maybe) or wait.
    ///
    /// The gag: whatever the player does, it is revealed to be the indestructible WALKING BUTTON from the
    /// earlier chapters, charging in. It survives either way. If the player shoots, the bullet does nothing
    /// to it (it comes alive, offended, yelps, and carries on); if they wait, it just arrives harmlessly and
    /// says hello. The imp reacts (delighted, or unimpressed you shot the button again), choice independent.
    /// No real death; the pre-reveal is framed as genuinely tense so the reveal lands as comedy. Reuses the
    /// WalkingButton figure, its come-alive and walk, and its little floating voice. Stats only.
    /// </summary>
    public sealed class ChargingButtonBeat : GunBeat
    {
        [Header("References")]
        [Tooltip("The walking-button figure prefab (the same indestructible gag figure).")]
        [SerializeField] private WalkingButton _buttonPrefab;

        [Header("The charge")]
        [SerializeField] private float _startX = 5.5f;
        [SerializeField] private float _stopX = 1.2f;
        [SerializeField] private float _y = -0.3f;
        [SerializeField] private float _buttonScale = 1.1f;
        [SerializeField] private float _chargeSpeed = 6f;
        [SerializeField] private Vector2 _boxSize = new Vector2(1.5f, 1.5f);
        [SerializeField] private float _keepoutPadding = 0.45f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "Something is coming. Fast. From the right, you feel it before you see it.",
            "And here is the thing, I genuinely cannot tell you whether it is running [amber]to[/amber] you or [amber]at[/amber] you. Help, or harm. You will not know until it arrives, and by then it may be too late to do anything but flinch. So. Shoot it now, on the maybe, or hold your nerve and wait. Quickly.",
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
        [SerializeField] private float _comeAliveDuration = 0.45f;
        [SerializeField] private float _voiceFade = 0.3f;

        private Camera _cam;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;
            if (_buttonPrefab == null) { Debug.LogError("[ChargingButtonBeat] '" + Note + "' is missing its walking-button prefab."); yield break; }
            _cam = Cam(ctx);

            var button = Instantiate(_buttonPrefab, transform);
            button.name = "ChargingButton";
            button.transform.localPosition = new Vector3(_startX, _y, 0f);
            button.transform.localScale = new Vector3(_buttonScale, _buttonScale, 1f);
            var keepout = button.gameObject.AddComponent<ScreenKeepout>();
            keepout.UseRendererBounds(_keepoutPadding);

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.Arm(true);
            ArmChoices(ctx, _fireLabel, _waitLabel);

            float x = _startX;
            bool fired = false, done = false;
            while (!done)
            {
                x = Mathf.MoveTowards(x, _stopX, _chargeSpeed * Time.deltaTime);
                button.transform.localPosition = new Vector3(x, _y, 0f);
                aim.SetTargets(Boxes(new AimField.Box(new Vector2(button.transform.position.x, button.transform.position.y + 0.1f), _boxSize)));
                aim.Tick();

                if (aim.TryTakeFire(out int t) && t == 0) { fired = true; done = true; }
                else if (PickedChoice == 0) { fired = true; done = true; }
                else if (PickedChoice == 1) done = true;
                else if (x <= _stopX + 0.0001f) done = true;
                if (!done) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);

            if (fired) Fire();
            else
            {
                // Finish arriving harmlessly.
                while (x > _stopX + 0.0001f)
                {
                    x = Mathf.MoveTowards(x, _stopX, _chargeSpeed * Time.deltaTime);
                    button.transform.localPosition = new Vector3(x, _y, 0f);
                    yield return null;
                }
            }

            // The reveal: the hurtling thing sprouts limbs and a put-out face. It is, of course, the button.
            if (fired) yield return new WaitForSeconds(_resolveBeat);
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
