using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Marks a rectangular region of the screen as off-limits to roaming elements (the imp)
    /// while enabled. Two ways to define the region: a fixed rect (for the dialogue box and the
    /// stats panel, whose extents are known), or the real world bounds of every renderer in this
    /// object's subtree (for a dilemma station, so the region tracks the actual trolley, track,
    /// figures, room and buttons rather than a guess). It self-registers in a static list; the
    /// roamer reads it, so the two stay decoupled. One job: declare where not to go.
    /// </summary>
    public sealed class ScreenKeepout : MonoBehaviour
    {
        public enum Mode { FixedRect, RendererBounds }

        [SerializeField] private Mode _mode = Mode.FixedRect;

        [Header("Fixed rect")]
        [Tooltip("World-space size, for FixedRect.")]
        [SerializeField] private Vector2 _size = new Vector2(4f, 3f);
        [Tooltip("Centre offset from this transform, for FixedRect.")]
        [SerializeField] private Vector2 _offset = Vector2.zero;

        [Header("Both modes")]
        [Tooltip("Grow the region by this on every side, so nothing crowds the edge.")]
        [SerializeField] private float _padding = 0.4f;

        private static readonly List<ScreenKeepout> _active = new List<ScreenKeepout>();
        public static IReadOnlyList<ScreenKeepout> Active => _active;

        private void OnEnable() { if (!_active.Contains(this)) _active.Add(this); }
        private void OnDisable() { _active.Remove(this); }

        public Rect WorldRect
        {
            get
            {
                if (_mode == Mode.RendererBounds)
                {
                    if (TryRendererBounds(out Bounds b))
                        return Grow(new Rect(b.min.x, b.min.y, b.size.x, b.size.y), _padding);
                    return new Rect(1e6f, 1e6f, 0f, 0f); // nothing drawn yet: no region
                }
                Vector3 c = transform.position + (Vector3)_offset;
                return Grow(new Rect(c.x - _size.x * 0.5f, c.y - _size.y * 0.5f, _size.x, _size.y), _padding);
            }
        }

        public bool Contains(Vector2 p, float margin)
        {
            Rect r = WorldRect;
            return p.x >= r.xMin - margin && p.x <= r.xMax + margin
                && p.y >= r.yMin - margin && p.y <= r.yMax + margin;
        }

        private bool TryRendererBounds(out Bounds bounds)
        {
            bounds = default;
            bool any = false;
            var renderers = GetComponentsInChildren<Renderer>(false); // active/enabled only
            for (int i = 0; i < renderers.Length; i++)
            {
                var rend = renderers[i];
                if (rend == null || !rend.enabled) continue;
                if (!any) { bounds = rend.bounds; any = true; }
                else bounds.Encapsulate(rend.bounds);
            }
            return any;
        }

        private static Rect Grow(Rect r, float m)
            => new Rect(r.xMin - m, r.yMin - m, r.width + 2f * m, r.height + 2f * m);

        private void OnDrawGizmosSelected()
        {
            Rect r = WorldRect;
            Gizmos.color = new Color(0.9f, 0.3f, 0.2f, 0.9f);
            Gizmos.DrawWireCube(new Vector3(r.center.x, r.center.y, 0f), new Vector3(r.width, r.height, 0.05f));
        }
    }
}
