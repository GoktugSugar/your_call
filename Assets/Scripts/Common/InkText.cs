using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Creates world-space TMP labels that sit in the scene (no canvas, no panel) and
    /// sort predictably above the ink. A characterful typeface is a fast follow; this
    /// keeps every label consistent in the meantime.
    /// </summary>
    public static class InkText
    {
        public static TextMeshPro Create(Transform parent, string name, float fontSize, Color color, TextAlignmentOptions align, int sortingOrder)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(parent, false);
            var t = go.AddComponent<TextMeshPro>();
            t.text = string.Empty;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = align;
            t.rectTransform.sizeDelta = new Vector2(10f, 2f);

            var mr = go.GetComponent<MeshRenderer>();
            if (mr != null) mr.sortingOrder = sortingOrder;
            return t;
        }

        public static void SetAlpha(TMP_Text t, float a)
        {
            var c = t.color; c.a = a; t.color = c;
        }
    }
}
