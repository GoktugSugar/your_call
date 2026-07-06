using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A single full-screen ink wash used for hard scene transitions: the opening starts
    /// on black, the crash flash plays over it, then it dissolves into the white void. One
    /// job, one sprite. It sorts above everything so it can black the whole page out, and
    /// fades like ink rather than hard-cutting. Not a UI panel; nothing reads through it.
    /// </summary>
    public class ScreenFade : MonoBehaviour
    {
        [SerializeField] private Color _color = Color.black;
        [Tooltip("Cover the screen (opaque) at scene load, so the game opens in darkness.")]
        [SerializeField] private bool _startOpaque = true;
        [SerializeField] private int _sortingOrder = 90;
        [SerializeField] private Vector2 _size = new Vector2(80f, 50f);

        private SpriteRenderer _sr;
        private float _alpha;
        private bool _built;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            var px = new Color32[4];
            for (int i = 0; i < px.Length; i++) px[i] = new Color32(255, 255, 255, 255);
            tex.SetPixels32(px); tex.Apply();
            var spr = Sprite.Create(tex, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 2f);

            var go = new GameObject("Wash");
            go.transform.SetParent(transform, false);
            go.transform.localScale = new Vector3(_size.x, _size.y, 1f);
            _sr = go.AddComponent<SpriteRenderer>();
            _sr.sprite = spr;
            _sr.sortingOrder = _sortingOrder;

            _alpha = _startOpaque ? 1f : 0f;
            Apply();
            _built = true;
        }

        public bool IsOpaque => _alpha >= 0.999f;

        public void SetColor(Color c) { _color = c; Apply(); }

        public void SetAlpha(float a) { _alpha = Mathf.Clamp01(a); Apply(); }

        /// <summary>Snap fully to the wash colour (used to open on black or cut to black).</summary>
        public void Cover(Color c) { _color = c; _alpha = 1f; Apply(); }

        public IEnumerator FadeTo(float target, float duration)
        {
            if (!_built) Build();
            float from = _alpha, t = 0f, d = Mathf.Max(duration, 0.0001f);
            while (t < d)
            {
                t += Time.deltaTime;
                SetAlpha(Mathf.Lerp(from, target, EaseUtil.OutCubic(t / d)));
                yield return null;
            }
            SetAlpha(target);
        }

        private void Apply()
        {
            if (_sr == null) return;
            var c = _color; c.a = _alpha;
            _sr.color = c;
            _sr.enabled = _alpha > 0.0001f;
        }
    }
}
