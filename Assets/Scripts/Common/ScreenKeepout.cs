using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Marks a rectangular region of the screen as off-limits to roaming elements (the imp),
    /// while this component is enabled. Put one on the dialogue box and on each dilemma
    /// station so the imp keeps clear of whatever is currently on screen; deactivating the
    /// station (or hiding the box) frees that space again. It registers itself in a static
    /// list; the roamer reads the list, so the two stay decoupled. One job: declare a rect.
    /// </summary>
    public sealed class ScreenKeepout : MonoBehaviour
    {
        [Tooltip("World-space size of the region to keep clear.")]
        [SerializeField] private Vector2 _size = new Vector2(4f, 3f);
        [Tooltip("Offset of the region's centre from this transform's position.")]
        [SerializeField] private Vector2 _offset = Vector2.zero;

        private static readonly List<ScreenKeepout> _active = new List<ScreenKeepout>();
        public static IReadOnlyList<ScreenKeepout> Active => _active;

        private void OnEnable() { if (!_active.Contains(this)) _active.Add(this); }
        private void OnDisable() { _active.Remove(this); }

        public Rect WorldRect
        {
            get
            {
                Vector3 c = transform.position + (Vector3)_offset;
                return new Rect(c.x - _size.x * 0.5f, c.y - _size.y * 0.5f, _size.x, _size.y);
            }
        }

        /// <summary>True if the point falls inside this region grown by <paramref name="margin"/>.</summary>
        public bool Contains(Vector2 p, float margin)
        {
            Rect r = WorldRect;
            return p.x >= r.xMin - margin && p.x <= r.xMax + margin
                && p.y >= r.yMin - margin && p.y <= r.yMax + margin;
        }

        private void OnDrawGizmosSelected()
        {
            Rect r = WorldRect;
            Gizmos.color = new Color(0.9f, 0.3f, 0.2f, 0.9f);
            Gizmos.DrawWireCube(new Vector3(r.center.x, r.center.y, 0f), new Vector3(r.width, r.height, 0.05f));
        }
    }
}
