using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A quick ink poof: a little burst of short strokes that radiate out from a point and fade,
    /// then destroy themselves. Used to punctuate the menu imp's teleport (it vanishes here and
    /// reappears elsewhere) so the jump reads as a deliberate poof rather than a glitch. Self
    /// contained and reusable; spawn it and forget it. One job: a fading scribble burst.
    /// </summary>
    public sealed class InkPoof : MonoBehaviour
    {
        /// <summary>Spawn a one-shot poof at a world position. Draws, fades over duration, self destroys.</summary>
        public static void Spawn(Vector3 position, Material material, Color color, float radius,
                                 float duration, int strokes, float width, int sortingOrder)
        {
            var go = new GameObject("InkPoof");
            go.transform.position = position;
            go.AddComponent<InkPoof>().Begin(material, color, radius, duration, strokes, width, sortingOrder);
        }

        private readonly List<LineRenderer> _lines = new List<LineRenderer>();
        private Color _color;

        private void Begin(Material material, Color color, float radius, float duration, int strokes, float width, int sortingOrder)
        {
            _color = color;
            int n = Mathf.Max(3, strokes);
            for (int i = 0; i < n; i++)
            {
                float a = (i / (float)n) * Mathf.PI * 2f + Random.Range(-0.2f, 0.2f);
                float inner = radius * Random.Range(0.25f, 0.45f);
                float outer = radius * Random.Range(0.8f, 1.1f);
                var dir = new Vector3(Mathf.Cos(a), Mathf.Sin(a), 0f);
                var lr = InkLine.Create(transform, "Ray", material, width, color, sortingOrder);
                InkLine.SetPoints(lr, new List<Vector3> { dir * inner, dir * outer });
                _lines.Add(lr);
            }
            StartCoroutine(Fade(Mathf.Max(0.05f, duration)));
        }

        private IEnumerator Fade(float duration)
        {
            float t = 0f;
            while (t < duration)
            {
                t += Time.deltaTime;
                float k = 1f - EaseUtil.Clamp01(t / duration);
                for (int i = 0; i < _lines.Count; i++)
                    if (_lines[i] != null) InkLine.SetAlpha(_lines[i], _color, k);
                // a little outward drift as it fades
                transform.localScale = Vector3.one * (1f + (1f - k) * 0.5f);
                yield return null;
            }
            Destroy(gameObject);
        }
    }
}
