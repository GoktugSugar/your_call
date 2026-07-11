using System;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// Two plain text choices offered as a quiet fallback to the diegetic lever.
    /// World-space and minimal: resting ink lifts to full ink on hover (no amber, so the
    /// lever stays the accent). Picked by click or number/arrow key, new Input System
    /// only. Player-facing labels carry no dashes. Raises <see cref="Chosen"/>.
    /// </summary>
    public class ChoiceButtons : MonoBehaviour
    {
        [SerializeField] private float _fontSize = 3.3f;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField, Range(0f, 1f)] private float _restAlpha = 0.7f;
        [SerializeField] private int _sortingOrder = 20;
        [SerializeField] private Vector3 _leftPosition = new Vector3(-3.3f, -3.5f, 0f);
        [SerializeField] private Vector3 _rightPosition = new Vector3(3.3f, -3.5f, 0f);
        [SerializeField] private float _hoverScale = 1.07f;
        [SerializeField] private Vector2 _colliderPadding = new Vector2(0.5f, 0.35f);
        [SerializeField] private Camera _camera;

        public event Action<int> Chosen;

        private readonly TextMeshPro[] _labels = new TextMeshPro[2];
        private readonly BoxCollider2D[] _cols = new BoxCollider2D[2];
        private readonly float[] _hoverT = new float[2];
        private bool _armed;
        private float _visT;
        private float _targetVis;
        private bool _built;

        private void Awake()
        {
            Build();
        }

        private void Build()
        {
            if (_built) return;
            _labels[0] = MakeLabel("ChoiceLeft", _leftPosition);
            _labels[1] = MakeLabel("ChoiceRight", _rightPosition);
            _built = true;
            Apply();
        }

        private TextMeshPro MakeLabel(string name, Vector3 localPos)
        {
            var t = InkText.Create(transform, name, _fontSize, _color, TextAlignmentOptions.Center, _sortingOrder);
            t.rectTransform.sizeDelta = new Vector2(5f, 1.2f);
            t.transform.localPosition = localPos;
            var col = t.gameObject.AddComponent<BoxCollider2D>();
            col.isTrigger = true;
            _cols[t.name == "ChoiceLeft" ? 0 : 1] = col;
            return t;
        }

        public void Present(string leftLabel, string rightLabel)
        {
            _labels[0].text = Localization.Localize(leftLabel);
            _labels[1].text = Localization.Localize(rightLabel);
            for (int i = 0; i < 2; i++) { _hoverT[i] = 0f; SizeCollider(i); }
            _targetVis = 1f;
            _armed = true;
        }

        public void Dismiss()
        {
            _armed = false;
            _targetVis = 0f;
        }

        /// <summary>Instantly hide the choices with no fade and clear their state, so nothing lingers.
        /// Called on beat enter by the sequence (see SequencePlayer) so choice options from one beat are
        /// never visible during the next.</summary>
        public void HideNow()
        {
            _armed = false;
            _targetVis = 0f;
            _visT = 0f;
            for (int i = 0; i < _hoverT.Length; i++) _hoverT[i] = 0f;
            if (_built) Apply();
        }

        private void SizeCollider(int i)
        {
            _labels[i].ForceMeshUpdate();
            Bounds b = _labels[i].textBounds;
            _cols[i].offset = new Vector2(b.center.x, b.center.y);
            _cols[i].size = new Vector2(Mathf.Max(b.size.x, 0.5f) + _colliderPadding.x, Mathf.Max(b.size.y, 0.5f) + _colliderPadding.y);
        }

        private void Update()
        {
            if (!_built) return;
            if (_camera == null) _camera = Camera.main;

            _visT = Mathf.MoveTowards(_visT, _targetVis, Time.deltaTime / 0.2f);

            bool interactive = _armed && _visT > 0.5f && _camera != null;
            Vector3 wp = interactive ? PointerInput.WorldPosition(_camera, transform.position.z) : Vector3.zero;

            for (int i = 0; i < 2; i++)
            {
                bool hovered = interactive && _cols[i] != null && _cols[i].OverlapPoint(wp);
                _hoverT[i] = Mathf.MoveTowards(_hoverT[i], hovered ? 1f : 0f, Time.deltaTime / 0.1f);
                if (hovered && PointerInput.Clicked) { Choose(i); return; }
            }

            if (interactive) ReadKeyboard();
            Apply();
        }

        private void ReadKeyboard()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null || PointerInput.Suppressed) return;
            if (kb.digit1Key.wasPressedThisFrame || kb.leftArrowKey.wasPressedThisFrame) { Choose(0); return; }
            if (kb.digit2Key.wasPressedThisFrame || kb.rightArrowKey.wasPressedThisFrame) { Choose(1); return; }
#endif
        }

        private void Choose(int index)
        {
            if (!_armed) return;
            _armed = false;
            _targetVis = 0f;
            Chosen?.Invoke(index);
        }

        private void Apply()
        {
            for (int i = 0; i < 2; i++)
            {
                if (_labels[i] == null) continue;
                float a = Mathf.Lerp(_restAlpha, 1f, _hoverT[i]) * _visT;
                InkText.SetAlpha(_labels[i], a);
                float s = Mathf.Lerp(1f, _hoverScale, _hoverT[i]);
                _labels[i].transform.localScale = new Vector3(s, s, 1f);
            }
        }
    }
}
