using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Builds and configures LineRenderers so every ink stroke shares one look:
    /// one consistent weight, rounded caps and corners (rounded joints, no joint dots),
    /// and vertex-colour tint so a stroke can fade uniformly through its own alpha.
    /// This is the only place strokes are created; nothing else hard-codes line setup.
    /// </summary>
    public static class InkLine
    {
        public static LineRenderer Create(Transform parent, string name, Material material, float width, Color color, int sortingOrder, int capCorner = 8)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var lr = go.AddComponent<LineRenderer>();
            lr.useWorldSpace = false;
            lr.alignment = LineAlignment.View;
            lr.textureMode = LineTextureMode.Stretch;
            lr.numCapVertices = capCorner;
            lr.numCornerVertices = capCorner;
            lr.widthMultiplier = width;
            lr.sharedMaterial = material;
            lr.sortingOrder = sortingOrder;
            lr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            lr.receiveShadows = false;
            SetColor(lr, color);
            return lr;
        }

        public static void SetColor(LineRenderer lr, Color c)
        {
            lr.startColor = c;
            lr.endColor = c;
        }

        public static void SetAlpha(LineRenderer lr, Color baseColor, float alpha)
        {
            var c = baseColor; c.a = alpha;
            lr.startColor = c; lr.endColor = c;
        }

        public static void SetPoints(LineRenderer lr, IList<Vector3> pts)
        {
            lr.positionCount = pts.Count;
            for (int i = 0; i < pts.Count; i++) lr.SetPosition(i, pts[i]);
        }

        /// <summary>Append points along an arc (degrees). Use start=0,end=360 for a closed loop.</summary>
        public static void AddArc(List<Vector3> into, Vector2 center, float radius, float startDeg, float endDeg, int segments, float z = 0f)
        {
            for (int i = 0; i <= segments; i++)
            {
                float a = Mathf.Deg2Rad * Mathf.Lerp(startDeg, endDeg, (float)i / segments);
                into.Add(new Vector3(center.x + Mathf.Cos(a) * radius, center.y + Mathf.Sin(a) * radius, z));
            }
        }
    }
}
