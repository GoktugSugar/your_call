using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A minimal hand-drawn ink frame that holds the imp's typed lines: a rough, boiling ink
    /// rectangle with rounded, imperfect corners over a faint paper fill. Not chrome, not a
    /// modal pop-up, no portraits or buttons; just a stylised caption area consistent with the
    /// doodle look (the one documented softening of the "no boxes" rule, see art-and-ui.md).
    /// It fades in with a line and out when the words clear, following the reused NarratorView.
    /// The text is drawn by the NarratorView positioned inside it; this only draws the frame.
    /// </summary>
    public sealed class DialogueBox : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("The frame appears while this narrator has a line up, and leaves when it clears.")]
        [SerializeField] private NarratorView _narrator;

        [Header("Frame")]
        [SerializeField] private Vector2 _size = new Vector2(16f, 1.8f);
        [SerializeField] private Color _borderColor = Palette.Ink;
        [Tooltip("A hair lighter than the paper ground, so the caption area reads as its own page.")]
        [SerializeField] private Color _fillColor = new Color(0.980f, 0.968f, 0.936f, 1f);
        [SerializeField] private float _borderWidth = 0.05f;
        [SerializeField] private float _cornerRadius = 0.2f;
        [SerializeField, Range(2, 10)] private int _cornerSegments = 4;
        [SerializeField] private int _sortingFill = 17;
        [SerializeField] private int _sortingBorder = 19;
        [Tooltip("The living boil that makes the ink look drawn; also wobbles the corners.")]
        [SerializeField] private bool _boil = true;

        [Header("Fade")]
        [SerializeField] private float _fadeSpeed = 5f;

        private SpriteRenderer _fill;
        private LineRenderer _border;
        private float _alpha;
        private bool _built;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _fill = MakeFill();
            _border = InkLine.Create(transform, "Border", _inkMaterial, _borderWidth, _borderColor, _sortingBorder);
            InkLine.SetPoints(_border, RoundedRect(_size * 0.995f, _cornerRadius, _cornerSegments));
            if (_boil) _border.gameObject.AddComponent<LineBoil>().Capture();
            _alpha = 0f;
            Apply();
            _built = true;
        }

        private void Update()
        {
            float target = (_narrator != null && _narrator.HasLine) ? 1f : 0f;
            _alpha = Mathf.MoveTowards(_alpha, target, Time.deltaTime * _fadeSpeed);
            Apply();
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
            go.transform.localScale = new Vector3(_size.x * 0.96f, _size.y * 0.9f, 1f);
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
