using System;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One axis-and-value pair. Unity does not serialise dictionaries, so a choice's
    /// profile impact is a small serializable list of these, recorded silently.
    /// </summary>
    [Serializable]
    public struct AxisImpact
    {
        [SerializeField] private MoralAxis _axis;
        [SerializeField] private float _value;

        public AxisImpact(MoralAxis axis, float value) { _axis = axis; _value = value; }

        public MoralAxis Axis => _axis;
        public float Value => _value;
    }
}
