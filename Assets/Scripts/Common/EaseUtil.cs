using UnityEngine;

namespace YourCall
{
    /// <summary>Small, allocation-free easing helpers for code-driven, ink-like motion.</summary>
    public static class EaseUtil
    {
        public static float Clamp01(float t) => t < 0f ? 0f : (t > 1f ? 1f : t);

        public static float SmoothStep(float t) { t = Clamp01(t); return t * t * (3f - 2f * t); }

        public static float InCubic(float t) { t = Clamp01(t); return t * t * t; }

        public static float OutCubic(float t) { t = Clamp01(t); float u = 1f - t; return 1f - u * u * u; }

        public static float InOutCubic(float t)
        {
            t = Clamp01(t);
            return t < 0.5f ? 4f * t * t * t : 1f - Mathf.Pow(-2f * t + 2f, 3f) / 2f;
        }

        /// <summary>Overshoot past 1 then settle back to 1. For the impact settle.</summary>
        public static float OutBack(float t, float s = 1.70158f)
        {
            t = Clamp01(t) - 1f;
            return 1f + (s + 1f) * t * t * t + s * t * t;
        }

        /// <summary>Dip below 0 first (pull back) then release. For anticipation.</summary>
        public static float InBack(float t, float s = 1.70158f)
        {
            t = Clamp01(t);
            return (s + 1f) * t * t * t - s * t * t;
        }
    }
}
