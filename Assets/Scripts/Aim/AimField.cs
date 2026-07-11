using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The reusable aim-and-fire hit test for the gun chapter (Chapter 4): given the shared first person
    /// <see cref="Crosshair"/> and its amber <see cref="AimHighlight"/> lock, it tracks which of a set of
    /// target boxes the reticle is over (driving the highlight) and reports a fire on a target. It is the
    /// generalisation of the man-and-the-last-bear station's aim logic, lifted out of
    /// <see cref="ShootingConsequence"/> so every gun beat can reuse the exact same crosshair, amber lock
    /// and click to fire without a bespoke station each (see docs/tech.md, Chapter 4).
    ///
    /// A plain helper, not a MonoBehaviour: a beat owns one, feeds it its target boxes (which can move,
    /// updated per frame), calls <see cref="Tick"/> each frame while aiming, and polls
    /// <see cref="TryTakeFire"/>. The boxes and the imp as an optional target stay the beat's business; this
    /// only answers "which box is the reticle over" and "which box did the shot hit". One job.
    /// </summary>
    public sealed class AimField
    {
        public struct Box
        {
            public Vector2 Center;
            public Vector2 Size;
            public Box(Vector2 center, Vector2 size) { Center = center; Size = size; }
        }

        private readonly Crosshair _crosshair;
        private readonly AimHighlight _highlight;
        private readonly List<Box> _boxes = new List<Box>();
        private bool _armed;
        private bool _hasFire;
        private int _firedIndex = -1;

        public AimField(Crosshair crosshair, AimHighlight highlight)
        {
            _crosshair = crosshair;
            _highlight = highlight;
        }

        /// <summary>Replace the target boxes (call once, or each frame for moving targets). Box index is the
        /// target id the fire reports.</summary>
        public void SetTargets(IList<Box> boxes)
        {
            _boxes.Clear();
            if (boxes != null) _boxes.AddRange(boxes);
        }

        /// <summary>Arm or disarm aiming: shows the crosshair, subscribes the trigger, and clears the amber
        /// lock when disarmed. Always disarm when the choice window ends so no stray fire leaks to the next beat.</summary>
        public void Arm(bool on)
        {
            if (_armed == on) return;
            _armed = on;
            if (_crosshair != null)
            {
                if (on) _crosshair.Fired += OnFired;
                else _crosshair.Fired -= OnFired;
                _crosshair.Arm(on);
            }
            if (!on && _highlight != null) _highlight.Hide();
        }

        /// <summary>Per-frame while armed: snap the amber lock onto whichever target the reticle is over.</summary>
        public void Tick()
        {
            if (!_armed || _highlight == null || _crosshair == null) return;
            int t = IndexAt(_crosshair.AimPoint);
            if (t >= 0) _highlight.Show(_boxes[t].Center, _boxes[t].Size);
            else _highlight.Hide();
        }

        /// <summary>Consume a pending shot. Returns true once per fire; <paramref name="targetIndex"/> is the
        /// hit box, or -1 for a shot into the empty void (which hits nothing).</summary>
        public bool TryTakeFire(out int targetIndex)
        {
            if (_hasFire)
            {
                _hasFire = false;
                targetIndex = _firedIndex;
                return true;
            }
            targetIndex = -1;
            return false;
        }

        private void OnFired(Vector3 worldPoint)
        {
            if (!_armed || _hasFire) return;
            _hasFire = true;
            _firedIndex = IndexAt(worldPoint);
        }

        private int IndexAt(Vector2 p)
        {
            for (int i = 0; i < _boxes.Count; i++)
            {
                var b = _boxes[i];
                if (Mathf.Abs(p.x - b.Center.x) <= b.Size.x * 0.5f && Mathf.Abs(p.y - b.Center.y) <= b.Size.y * 0.5f)
                    return i;
            }
            return -1;
        }
    }
}
