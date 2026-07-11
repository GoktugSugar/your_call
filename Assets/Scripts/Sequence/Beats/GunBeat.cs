using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The shared base for the gun chapter's aim-and-fire beats (Chapter 4). It holds the one
    /// <see cref="GunKit"/> reference (the reused crosshair, amber lock, gunshot, figure prefab and ink),
    /// and gives each beat the small pieces they all repeat: showing an imp line and waiting for a click,
    /// the reaction-then-click-gate before the crowd reveal (the same sequencing the dilemma loop uses so
    /// the choice lands before the room's verdict), instancing a target figure, floating an ink plea over
    /// a figure with no bubble (the menu-bark treatment), firing the gunshot, and the seeded how-others-chose
    /// reveal. Each concrete beat (the mercy shot, the two targets, the flinch, and so on) writes its own
    /// short <see cref="SequenceBeat.Play"/> over these, so the varied gun beats stay readable and the aim
    /// machinery is not copied nine times. The imp mocks every choice and never grades it; nothing here scores.
    /// </summary>
    public abstract class GunBeat : SequenceBeat
    {
        [Header("Gun apparatus (shared)")]
        [SerializeField] protected GunKit _kit;

        [Header("Timing (shared, tunable)")]
        [SerializeField] protected float _advanceLockout = 0.3f;
        [Tooltip("Minimum hold on the imp's reaction before the crowd reveal can be dismissed (also a lockout against a carried-over click).")]
        [SerializeField] protected float _reactHold = 1.0f;
        [SerializeField] protected float _presentHold = 0.4f;
        [SerializeField] protected float _statsFade = 0.5f;
        [SerializeField] protected float _statsHideFade = 0.6f;
        [Tooltip("A beat before the struck figure folds, after the trigger pull.")]
        [SerializeField] protected float _resolveBeat = 0.35f;
        [SerializeField] protected float _foldDuration = 0.7f;
        [SerializeField] protected float _foldSettle = 0.4f;
        [SerializeField] protected float _pleaFade = 0.35f;

        [Header("Floating plea (ink over a figure, no bubble)")]
        [SerializeField] protected float _pleaSize = 2.3f;
        [SerializeField] protected float _pleaHeight = 1.35f;
        [SerializeField] protected int _pleaSorting = 24;

        protected Camera Cam(SequenceContext ctx) => ctx != null && ctx.Camera != null ? ctx.Camera : Camera.main;

        /// <summary>Assert the shared apparatus is wired; log and bail otherwise.</summary>
        protected bool ApparatusReady()
        {
            if (_kit == null) { Debug.LogError("[GunBeat] '" + Note + "' is missing its GunKit."); return false; }
            if (_kit.Crosshair == null || _kit.AimHighlight == null)
            {
                Debug.LogError("[GunBeat] '" + Note + "' GunKit has no crosshair / aim highlight.");
                return false;
            }
            return true;
        }

        protected AimField NewAimField() => new AimField(_kit.Crosshair, _kit.AimHighlight);

        // ---- imp narration helpers ----

        /// <summary>Show one line, wait for it to finish typing, then wait for a click to continue.</summary>
        protected IEnumerator Line(SequenceContext ctx, string line)
        {
            if (string.IsNullOrEmpty(line)) yield break;
            ctx.Narrator.Show(line);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return WaitAdvance(_advanceLockout);
        }

        /// <summary>Show several lines in order, each acknowledged with a click.</summary>
        protected IEnumerator Lines(SequenceContext ctx, string[] lines)
        {
            if (lines == null) yield break;
            for (int i = 0; i < lines.Length; i++) yield return Line(ctx, lines[i]);
        }

        /// <summary>The imp's reaction to the choice, played over the world with the click gate before the
        /// crowd reveal (matching the dilemma loop): show it, hold at least <see cref="_reactHold"/>, then
        /// wait for the continue click, then clear. Choice independent; never grades.</summary>
        protected IEnumerator React(SequenceContext ctx, string line)
        {
            if (!string.IsNullOrEmpty(line))
            {
                ctx.Narrator.Show(line);
                while (ctx.Narrator.IsShowing) yield return null;
            }
            float gate = 0f;
            while (true)
            {
                gate += Time.deltaTime;
                if (gate > _reactHold && PointerInput.AdvancePressed) break;
                yield return null;
            }
            ctx.Narrator.Clear();
        }

        // ---- the crowd reveal ----

        /// <summary>The seeded how-others-chose reveal: build a report from the bars (the player's pick in
        /// amber), reveal it alone, then dismiss on a click. Display only, seeded, never gates progress.</summary>
        protected IEnumerator Split(SequenceContext ctx, string heading, params StatBar[] bars)
        {
            var report = new ResolutionReport { Heading = heading };
            float max = 1f;
            for (int i = 0; i < bars.Length; i++) max = Mathf.Max(max, bars[i].Value);
            report.MaxValue = max;
            for (int i = 0; i < bars.Length; i++) report.Bars.Add(bars[i]);
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        /// <summary>Silent profile nudge on one axis. Light and tunable; nothing consumes it yet.</summary>
        protected void Nudge(SequenceContext ctx, MoralAxis axis, float value)
        {
            if (ctx.Profile != null) ctx.Profile.Record(new[] { new AxisImpact(axis, value) });
        }

        // ---- targets ----

        /// <summary>Instance a plain stick figure target at a world position and scale, parented under the beat.</summary>
        protected Figure SpawnFigure(Vector2 feet, float scale, string name = "Target")
        {
            var f = Instantiate(_kit.FigurePrefab, new Vector3(feet.x, feet.y, 0f), Quaternion.identity, transform);
            f.name = name;
            f.transform.localScale = new Vector3(scale, scale, 1f);
            return f;
        }

        /// <summary>Fire the gunshot once (covers the diegetic aim and any text fallback).</summary>
        protected void Fire()
        {
            var sfx = _kit != null ? _kit.GunSfx : null;
            if (sfx != null) sfx.Fire();
        }

        // ---- floating ink plea over a figure (no bubble, the menu-bark treatment) ----

        protected TextMeshPro NewFloatingText(string name)
        {
            var t = InkText.Create(transform, name, _pleaSize, Palette.Ink, TextAlignmentOptions.Center, _pleaSorting);
            if (_kit != null && _kit.Font != null) t.font = _kit.Font;
            t.rectTransform.sizeDelta = new Vector2(5.5f, 1.4f);
            t.enableWordWrapping = true;
            InkText.SetAlpha(t, 0f);
            return t;
        }

        /// <summary>Show a plea over a world anchor and fade it in (routed through the emphasis markup, so any
        /// [amber] tags render as colour). Reuse the returned label to move, fade or destroy it.</summary>
        protected IEnumerator ShowPlea(TextMeshPro label, Vector3 figureWorldPos, string line, float extraHeight = 0f)
        {
            if (label == null) yield break;
            label.transform.position = figureWorldPos + new Vector3(0f, _pleaHeight + extraHeight, 0f);
            label.text = InkMarkup.ToRichText(Localization.Localize(line));
            yield return FadeText(label, 1f, _pleaFade);
        }

        protected IEnumerator FadeText(TextMeshPro label, float to, float dur)
        {
            if (label == null) yield break;
            float from = label.color.a, t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; InkText.SetAlpha(label, Mathf.Lerp(from, to, t / d)); yield return null; }
            InkText.SetAlpha(label, to);
        }

        // ---- input ----

        protected IEnumerator WaitAdvance(float lockout)
        {
            float t = 0f;
            while (true)
            {
                t += Time.deltaTime;
                if (t > lockout && PointerInput.AdvancePressed) yield break;
                yield return null;
            }
        }

        // The shared two text choices as the fallback to the crosshair (fire / do not fire). A gun beat pairs
        // these with an AimField for the diegetic pick, polling PickedChoice each frame. -1 means pending.
        private int _pick = -1;

        protected void ArmChoices(SequenceContext ctx, string left, string right)
        {
            _pick = -1;
            if (ctx.Choices == null) return;
            ctx.Choices.Chosen += OnPick;
            ctx.Choices.Present(left, right);
        }

        protected int PickedChoice => _pick;

        protected void DisarmChoices(SequenceContext ctx)
        {
            if (ctx.Choices != null) { ctx.Choices.Chosen -= OnPick; ctx.Choices.Dismiss(); }
        }

        private void OnPick(int index) { if (_pick < 0) _pick = index; }

        protected static List<AimField.Box> Boxes(params AimField.Box[] b) => new List<AimField.Box>(b);
    }
}
