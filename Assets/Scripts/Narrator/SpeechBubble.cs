using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A hand-drawn ink speech bubble that pops up next to a figure (the menu imp) and frames the
    /// reused NarratorView's typed line, with a small tail pointing back at the figure. A rounded,
    /// slightly wobbly ink outline over a faint paper fill, in the doodle style and the Caveat hand.
    /// It sizes itself to the text and places itself clear of the screen edges and the menu's central
    /// content, flipping above or below the figure as room allows. Reusable; the main menu uses it in
    /// place of the bottom dialogue box. One job: frame a short line in a bubble by the imp.
    /// </summary>
    public sealed class SpeechBubble : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private NarratorView _narrator;
        [Tooltip("The figure the bubble points at (the imp).")]
        [SerializeField] private Transform _target;
        [SerializeField] private Camera _camera;

        [Header("Frame")]
        [SerializeField] private Color _borderColor = Palette.Ink;
        [SerializeField] private Color _fillColor = new Color(0.980f, 0.968f, 0.936f, 1f);
        [SerializeField] private float _borderWidth = 0.05f;
        [SerializeField] private float _cornerRadius = 0.35f;
        [SerializeField, Range(3, 16)] private int _cornerSegments = 6;
        [SerializeField] private int _sortingFill = 17;
        [SerializeField] private int _sortingBorder = 19;

        [Header("Living line (controlled wobble)")]
        [SerializeField] private float _wobbleAmplitude = 0.012f;
        [SerializeField] private float _wobbleSpeed = 1.7f;

        [Header("Size / fit")]
        [Tooltip("The text wraps at this width; the bubble grows taller for a longer bark.")]
        [SerializeField] private float _maxTextWidth = 3.4f;
        [SerializeField] private Vector2 _padding = new Vector2(0.5f, 0.4f);
        [SerializeField] private Vector2 _minSize = new Vector2(1.8f, 1.1f);

        [Header("Placement")]
        [Tooltip("When above the imp, the bubble bottom sits this far above its origin (clears the horns).")]
        [SerializeField] private float _gapAbove = 1.7f;
        [Tooltip("When below the imp, the bubble top sits this far below its origin (clears the feet).")]
        [SerializeField] private float _gapBelow = 0.5f;
        [Tooltip("Keep the bubble this far inside the screen edges.")]
        [SerializeField] private float _screenMargin = 0.3f;
        [Tooltip("Half-width of the central zone (title + menu items) the bubble must not cross.")]
        [SerializeField] private float _centerClearHalfWidth = 4.0f;
        [Tooltip("The tail points at this height above the imp origin (roughly its body), not its feet.")]
        [SerializeField] private float _tailTargetY = 0.9f;

        [Header("Tail")]
        [SerializeField] private float _tailWidth = 0.16f;
        [SerializeField] private float _tailLength = 0.4f;

        [Header("Fade")]
        [SerializeField] private float _fadeSpeed = 6f;

        private SpriteRenderer _fill;
        private LineRenderer _border;
        private LineRenderer _tail;
        private Vector3[] _borderBase;
        private Vector2 _size;
        private float _alpha;
        private bool _shown;
        private bool _built;

        /// <summary>True while the line is still typing on.</summary>
        public bool IsSpeaking => _narrator != null && _narrator.IsShowing;

        /// <summary>True until the bubble has fully faded out (so a caller can wait for it to clear).</summary>
        public bool IsVisible => _alpha > 0.01f;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _fill = MakeFill();
            _border = InkLine.Create(transform, "Border", _inkMaterial, _borderWidth, _borderColor, _sortingBorder);
            _tail = InkLine.Create(transform, "Tail", _inkMaterial, _borderWidth, _borderColor, _sortingBorder);
            _alpha = 0f;
            Apply();
            _built = true;
        }

        /// <summary>Pop the bubble up by the target and type a line into it (with the blip voice).</summary>
        public void Speak(string text)
        {
            if (!_built) Build();
            if (_camera == null) _camera = Camera.main;

            // Lay the text out at a fixed wrap width and read its size.
            _narrator.SetTextArea(new Vector2(_maxTextWidth, 6f));
            _narrator.Show(text);
            Vector2 pref = _narrator.PreferredSize;
            float innerW = Mathf.Min(Mathf.Max(pref.x, 0.5f), _maxTextWidth);
            float innerH = Mathf.Max(pref.y, 0.4f);
            _size = new Vector2(
                Mathf.Max(innerW + _padding.x * 2f, _minSize.x),
                Mathf.Max(innerH + _padding.y * 2f, _minSize.y));

            Vector3 anchor = _target != null ? _target.position : transform.position;
            Vector3 pos = ComputePosition(anchor, _size);
            transform.position = new Vector3(pos.x, pos.y, transform.position.z);
            if (_narrator != null)
                _narrator.transform.position = new Vector3(pos.x, pos.y, _narrator.transform.position.z);

            Vector3 tailTarget = anchor + Vector3.up * _tailTargetY;
            RebuildFrame(_size, tailTarget - pos);
            _shown = true;
        }

        /// <summary>Clear the line and fade the bubble out.</summary>
        public void Hide()
        {
            _shown = false;
            if (_narrator != null) _narrator.Clear();
        }

        private Vector3 ComputePosition(Vector3 anchor, Vector2 size)
        {
            float halfW = size.x * 0.5f, halfH = size.y * 0.5f;
            float camX = _camera != null ? _camera.transform.position.x : 0f;
            float camY = _camera != null ? _camera.transform.position.y : 0f;
            float sHalfH = _camera != null && _camera.orthographic ? _camera.orthographicSize : 5f;
            float sHalfW = sHalfH * (_camera != null ? _camera.aspect : 1.7f);
            float top = camY + sHalfH, bottom = camY - sHalfH;
            float left = camX - sHalfW, right = camX + sHalfW;

            // Vertical: prefer above the imp; flip below if that would run off the top.
            float posY = anchor.y + _gapAbove + halfH;
            if (posY + halfH > top - _screenMargin)
                posY = anchor.y - _gapBelow - halfH;
            posY = Mathf.Clamp(posY, bottom + halfH + _screenMargin, top - halfH - _screenMargin);

            // Horizontal: near the imp's x, but clear of the central content and on screen.
            float posX;
            if (anchor.x <= camX)
            {
                float minX = left + halfW + _screenMargin;
                float maxX = -_centerClearHalfWidth - halfW;
                posX = maxX >= minX ? Mathf.Clamp(anchor.x, minX, maxX) : (minX + maxX) * 0.5f;
            }
            else
            {
                float minX = _centerClearHalfWidth + halfW;
                float maxX = right - halfW - _screenMargin;
                posX = maxX >= minX ? Mathf.Clamp(anchor.x, minX, maxX) : (minX + maxX) * 0.5f;
            }
            return new Vector3(posX, posY, 0f);
        }

        private void RebuildFrame(Vector2 size, Vector2 tailLocal)
        {
            var pts = RoundedRect(size * 0.995f, _cornerRadius, _cornerSegments);
            _borderBase = pts.ToArray();
            InkLine.SetPoints(_border, pts);

            _fill.transform.localScale = new Vector3(size.x * 0.96f, size.y * 0.92f, 1f);

            // Tail: a little beak on the edge nearest the imp, pointing at it.
            float halfW = size.x * 0.5f, halfH = size.y * 0.5f;
            bool above = tailLocal.y <= 0f;   // the imp is below the bubble
            float baseY = above ? -halfH : halfH;
            float tipY = above ? baseY - _tailLength : baseY + _tailLength;
            float baseX = Mathf.Clamp(tailLocal.x, -halfW + 0.3f, halfW - 0.3f);
            float tipX = Mathf.Clamp(tailLocal.x, baseX - 0.3f, baseX + 0.3f);
            InkLine.SetPoints(_tail, new List<Vector3>
            {
                new Vector3(baseX - _tailWidth, baseY, 0f),
                new Vector3(tipX, tipY, 0f),
                new Vector3(baseX + _tailWidth, baseY, 0f),
            });
        }

        private void Update()
        {
            if (!_built) return;
            float target = _shown ? 1f : 0f;
            _alpha = Mathf.MoveTowards(_alpha, target, Time.deltaTime * _fadeSpeed);
            Apply();
            if (_alpha > 0.001f) Wobble();
        }

        private void Wobble()
        {
            if (_border == null || _borderBase == null) return;
            float t = Time.time * _wobbleSpeed;
            for (int i = 0; i < _borderBase.Length; i++)
            {
                Vector3 b = _borderBase[i];
                float ox = Mathf.Sin(t + b.x * 1.7f + b.y * 2.3f) * _wobbleAmplitude;
                float oy = Mathf.Cos(t * 1.15f + b.x * 2.1f - b.y * 1.3f) * _wobbleAmplitude;
                _border.SetPosition(i, new Vector3(b.x + ox, b.y + oy, 0f));
            }
        }

        private void Apply()
        {
            bool on = _alpha > 0.001f;
            if (_fill != null)
            {
                var c = _fillColor; c.a = _fillColor.a * _alpha; _fill.color = c;
                _fill.enabled = on;
            }
            if (_border != null) { InkLine.SetAlpha(_border, _borderColor, _alpha); _border.enabled = on; }
            if (_tail != null) { InkLine.SetAlpha(_tail, _borderColor, _alpha); _tail.enabled = on; }
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
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = spr;
            sr.sortingOrder = _sortingFill;
            return sr;
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
