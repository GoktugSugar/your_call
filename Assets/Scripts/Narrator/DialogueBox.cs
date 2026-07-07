using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A clean, rounded, hand-drawn ink frame that holds the imp's typed lines: softly rounded
    /// corners over a faint paper fill, its ink border alive with a slight, controlled wobble
    /// (a smooth breathing of the line, not a rough scribble and not a sterile vector rectangle).
    /// Not chrome, not a modal pop-up, no portraits or buttons; the one documented softening of
    /// the "no boxes" rule (see art-and-ui.md). It fades in with a line and out when it clears.
    /// The NarratorView types inside it with an inner margin; this only draws the frame.
    /// </summary>
    public sealed class DialogueBox : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("The frame appears while this narrator has a line up, and leaves when it clears.")]
        [SerializeField] private NarratorView _narrator;

        [Header("Frame")]
        [SerializeField] private Vector2 _size = new Vector2(16f, 1.55f);
        [SerializeField] private Color _borderColor = Palette.Ink;
        [Tooltip("A hair lighter than the paper ground, so the caption area reads as its own page.")]
        [SerializeField] private Color _fillColor = new Color(0.980f, 0.968f, 0.936f, 1f);
        [SerializeField] private float _borderWidth = 0.048f;
        [Tooltip("Softer, rounder corners than a sharp rectangle.")]
        [SerializeField] private float _cornerRadius = 0.34f;
        [SerializeField, Range(3, 16)] private int _cornerSegments = 8;
        [SerializeField] private int _sortingFill = 17;
        [SerializeField] private int _sortingBorder = 19;

        [Header("Living line (controlled wobble)")]
        [Tooltip("How far the ink line breathes. Small: a living line, not a scribble.")]
        [SerializeField] private float _wobbleAmplitude = 0.012f;
        [SerializeField] private float _wobbleSpeed = 1.6f;

        [Header("Fade")]
        [SerializeField] private float _fadeSpeed = 5f;

        private SpriteRenderer _fill;
        private LineRenderer _border;
        private Vector3[] _base;
        private float _alpha;
        private bool _built;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _fill = MakeFill();
            var pts = RoundedRect(_size * 0.995f, _cornerRadius, _cornerSegments);
            _base = pts.ToArray();
            _border = InkLine.Create(transform, "Border", _inkMaterial, _borderWidth, _borderColor, _sortingBorder);
            InkLine.SetPoints(_border, pts);
            _alpha = 0f;
            Apply();
            _built = true;
        }

        private void Update()
        {
            float target = (_narrator != null && _narrator.HasLine) ? 1f : 0f;
            _alpha = Mathf.MoveTowards(_alpha, target, Time.deltaTime * _fadeSpeed);
            Apply();
            if (_alpha > 0.001f) Wobble();
        }

        // A smooth, position-coherent breathing of the border, so the loop stays closed and it
        // reads as a living hand-drawn line rather than a boiling scribble.
        private void Wobble()
        {
            if (_border == null || _base == null) return;
            float t = Time.time * _wobbleSpeed;
            for (int i = 0; i < _base.Length; i++)
            {
                Vector3 b = _base[i];
                float ox = Mathf.Sin(t + b.x * 1.7f + b.y * 2.3f) * _wobbleAmplitude;
                float oy = Mathf.Cos(t * 1.15f + b.x * 2.1f - b.y * 1.3f) * _wobbleAmplitude;
                _border.SetPosition(i, new Vector3(b.x + ox, b.y + oy, 0f));
            }
        }

        private SpriteRenderer MakeFill()
        {
            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            var px = new Color32[4];
            for (int i = 0; i < px.Length; i++) px[i] = new Color32(255, 255, 255, 255);
            tex.SetPixels32(px); tex.Apply();
            var spr = Sprite.Create(tex, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 2f);

            var go = new GameObject("Fill");
            go.transform.SetParent(transform, false);
            go.transform.localScale = new Vector3(_size.x * 0.965f, _size.y * 0.88f, 1f);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = spr;
            sr.sortingOrder = _sortingFill;
            return sr;
        }

        private void Apply()
        {
            bool on = _alpha > 0.001f;
            if (_fill != null)
            {
                var c = _fillColor; c.a = _fillColor.a * _alpha; _fill.color = c;
                _fill.enabled = on;
            }
            if (_border != null)
            {
                InkLine.SetAlpha(_border, _borderColor, _alpha);
                _border.enabled = on;
            }
        }

        private static List<Vector3> RoundedRect(Vector2 size, float r, int seg)
        {
            float hw = size.x * 0.5f, hh = size.y * 0.5f;
            r = Mathf.Max(0.01f, Mathf.Min(r, Mathf.Min(hw, hh)));
            var p = new List<Vector3>();
            Vector2 bl = new Vector2(-hw + r, -hh + r);
            Vector2 br = new Vector2(hw - r, -hh + r);
            Vector2 tr = new Vector2(hw - r, hh - r);
            Vector2 tl = new Vector2(-hw + r, hh - r);
            p.Add(new Vector3(-hw + r, -hh, 0f));
            p.Add(new Vector3(hw - r, -hh, 0f));
            InkLine.AddArc(p, br, r, -90f, 0f, seg);
            p.Add(new Vector3(hw, hh - r, 0f));
            InkLine.AddArc(p, tr, r, 0f, 90f, seg);
            p.Add(new Vector3(-hw + r, hh, 0f));
            InkLine.AddArc(p, tl, r, 90f, 180f, seg);
            p.Add(new Vector3(-hw, -hh + r, 0f));
            InkLine.AddArc(p, bl, r, 180f, 270f, seg);
            p.Add(new Vector3(-hw + r, -hh, 0f));
            return p;
        }
    }
}
