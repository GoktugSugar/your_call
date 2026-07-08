using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Floats the imp's bark as plain ink text directly over it, no bubble, box, tail, or background,
    /// just the words on the paper. The reused NarratorView types them (with the blip voice); this
    /// only positions that text above the figure and shows or clears it. It keeps the text clear of
    /// the screen edges and the menu's central content (the title and options), flipping below the imp
    /// if there is no room above, reusing the same placement the retired speech bubble used, without
    /// any frame. One job: put the bark text over the imp.
    /// </summary>
    public sealed class FloatingBarkText : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private NarratorView _narrator;
        [Tooltip("The figure the text floats over (the imp).")]
        [SerializeField] private Transform _target;
        [SerializeField] private Camera _camera;

        [Header("Placement")]
        [Tooltip("The text wraps at this width; a longer bark takes more lines.")]
        [SerializeField] private float _maxTextWidth = 3.6f;
        [Tooltip("When above the imp, the text bottom sits this far above its origin (clears the horns).")]
        [SerializeField] private float _gapAbove = 1.8f;
        [Tooltip("When below the imp, the text top sits this far below its origin (clears the feet).")]
        [SerializeField] private float _gapBelow = 0.5f;
        [Tooltip("Keep the text this far inside the screen edges.")]
        [SerializeField] private float _screenMargin = 0.35f;
        [Tooltip("Half-width of the central zone (title + menu items) the text must not cross.")]
        [SerializeField] private float _centerClearHalfWidth = 3.6f;

        /// <summary>True while the line is still typing on.</summary>
        public bool IsSpeaking => _narrator != null && _narrator.IsShowing;

        /// <summary>True while a line is up (from Speak until Hide).</summary>
        public bool IsVisible => _narrator != null && _narrator.HasLine;

        /// <summary>Show a line floating over the target, typed on (with the blip voice).</summary>
        public void Speak(string text)
        {
            if (_narrator == null) return;
            if (_camera == null) _camera = Camera.main;

            // Measure the wrapped text, set the wrap area, and place it above (or below) the imp.
            Vector2 size = _narrator.MeasureWrapped(text, _maxTextWidth);
            _narrator.SetTextArea(new Vector2(_maxTextWidth, size.y + 1f));

            Vector3 anchor = _target != null ? _target.position : transform.position;
            Vector3 pos = ComputePosition(anchor, size);
            _narrator.transform.position = new Vector3(pos.x, pos.y, _narrator.transform.position.z);

            _narrator.Show(text);
        }

        /// <summary>Clear the line.</summary>
        public void Hide()
        {
            if (_narrator != null) _narrator.Clear();
        }

        private Vector3 ComputePosition(Vector3 anchor, Vector2 size)
        {
            float halfW = size.x * 0.5f, halfH = size.y * 0.5f;
            float camX = _camera != null ? _camera.transform.position.x : 0f;
            float camY = _camera != null ? _camera.transform.position.y : 0f;
            float sHalfH = _camera != null && _camera.orthographic ? _camera.orthographicSize : 5f;
            float sHalfW = sHalfH * (_camera != null ? _camera.aspect : 1.7f);
            float top = camY + sHalfH, bottom = camY - sHalfH;
            float left = camX - sHalfW, right = camX + sHalfW;

            // Vertical: prefer above the imp; flip below if that would run off the top.
            float posY = anchor.y + _gapAbove + halfH;
            if (posY + halfH > top - _screenMargin)
                posY = anchor.y - _gapBelow - halfH;
            posY = Mathf.Clamp(posY, bottom + halfH + _screenMargin, top - halfH - _screenMargin);

            // Horizontal: near the imp's x, but clear of the central content and on screen.
            float posX;
            if (anchor.x <= camX)
            {
                float minX = left + halfW + _screenMargin;
                float maxX = -_centerClearHalfWidth - halfW;
                posX = maxX >= minX ? Mathf.Clamp(anchor.x, minX, maxX) : (minX + maxX) * 0.5f;
            }
            else
            {
                float minX = _centerClearHalfWidth + halfW;
                float maxX = right - halfW - _screenMargin;
                posX = maxX >= minX ? Mathf.Clamp(anchor.x, minX, maxX) : (minX + maxX) * 0.5f;
            }
            return new Vector3(posX, posY, 0f);
        }
    }
}
