using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The confirmation shown when the player picks New Game while a save already exists, since New Game will
    /// erase the run in progress. In the menu's ink style: a short prompt with two picks (start over, or go
    /// back), navigable by mouse (reusing <see cref="MenuItem"/>) and keyboard, mirroring the main menu.
    /// Built once by <see cref="MainMenu"/> and shown on demand; it raises <see cref="Confirmed"/> or
    /// <see cref="Cancelled"/> and lets the menu decide what happens. One job: ask "are you sure".
    /// </summary>
    public sealed class NewGameConfirm : MonoBehaviour
    {
        [Header("Copy (localized; no dashes)")]
        [SerializeField, TextArea(1, 3)] private string _prompt = "This erases your run in progress. Start a new game?";
        [SerializeField] private string _confirmLabel = "Yes, start over";
        [SerializeField] private string _cancelLabel = "No, keep playing";

        [Header("Layout")]
        [SerializeField] private float _promptSize = 2.7f;
        [SerializeField] private Vector3 _promptPosition = new Vector3(0f, 1.2f, 0f);
        [SerializeField] private Vector3 _confirmPosition = new Vector3(-3.0f, -0.6f, 0f);
        [SerializeField] private Vector3 _cancelPosition = new Vector3(3.0f, -0.6f, 0f);

        [Header("Input")]
        [Tooltip("Ignore enter/click for this long after opening, so the click that opened this never activates a pick.")]
        [SerializeField] private float _inputLockout = 0.25f;

        public event Action Confirmed;
        public event Action Cancelled;

        private Material _ink;
        private TMP_FontAsset _font;
        private TextMeshPro _promptText;
        private readonly List<MenuItem> _items = new List<MenuItem>();
        private int _selected;
        private bool _open;
        private float _openFor;
        private bool _built;

        /// <summary>Build the prompt and the two picks. Hidden until <see cref="Open"/>.</summary>
        public void Setup(Material inkMaterial, TMP_FontAsset font)
        {
            _ink = inkMaterial;
            _font = font;
            Build();
            SetShown(false);
        }

        private void Build()
        {
            if (_built) return;

            _promptText = InkText.Create(transform, "ConfirmPrompt", _promptSize, Palette.Ink, TextAlignmentOptions.Center, 32);
            if (_font != null) _promptText.font = _font;
            _promptText.rectTransform.sizeDelta = new Vector2(16f, _promptSize * 3f);
            _promptText.transform.localPosition = _promptPosition;
            _promptText.text = Localization.Localize(_prompt);

            _items.Add(MakeItem(_confirmLabel, _confirmPosition));
            _items.Add(MakeItem(_cancelLabel, _cancelPosition));

            for (int i = 0; i < _items.Count; i++)
            {
                int index = i;
                _items[i].Hovered += _ => Select(index);
                _items[i].Clicked += _ => Choose(index);
            }

            _built = true;
        }

        private MenuItem MakeItem(string label, Vector3 pos)
        {
            var go = new GameObject("Confirm_" + label);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = pos;
            var item = go.AddComponent<MenuItem>();
            item.Setup(_ink, _font, label, true);
            return item;
        }

        /// <summary>Show the confirmation and take input.</summary>
        public void Open()
        {
            SetShown(true);
            _open = true;
            _openFor = 0f;
            _selected = 1;   // default to the safe choice (keep playing)
            for (int i = 0; i < _items.Count; i++) _items[i].Arm(true);
            RefreshSelection();
        }

        /// <summary>Hide the confirmation and stop taking input.</summary>
        public void Close()
        {
            _open = false;
            for (int i = 0; i < _items.Count; i++) _items[i].Arm(false);
            SetShown(false);
        }

        private void SetShown(bool shown)
        {
            gameObject.SetActive(true);   // the component stays enabled; we fade its pieces
            if (_promptText != null) InkText.SetAlpha(_promptText, shown ? 1f : 0f);
            for (int i = 0; i < _items.Count; i++) _items[i].SetShown(shown ? 1f : 0f);
        }

        // Re-apply localized copy (called when the language changes live, like the rest of the menu).
        public void Relocalize()
        {
            if (_promptText != null) _promptText.text = Localization.Localize(_prompt);
            for (int i = 0; i < _items.Count; i++) _items[i].Relocalize();
        }

        private void Update()
        {
            if (!_open) return;
            _openFor += Time.deltaTime;
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null) return;

            if (kb.leftArrowKey.wasPressedThisFrame || kb.aKey.wasPressedThisFrame) Select(0);
            else if (kb.rightArrowKey.wasPressedThisFrame || kb.dKey.wasPressedThisFrame) Select(1);

            if (kb.escapeKey.wasPressedThisFrame) { Choose(1); return; }   // Esc = the safe choice
            if (_openFor >= _inputLockout &&
                (kb.enterKey.wasPressedThisFrame || kb.numpadEnterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame))
                Choose(_selected);
#endif
        }

        private void Select(int index)
        {
            if (index < 0 || index >= _items.Count) return;
            _selected = index;
            RefreshSelection();
        }

        private void RefreshSelection()
        {
            for (int i = 0; i < _items.Count; i++) _items[i].SetSelected(i == _selected);
        }

        private void Choose(int index)
        {
            if (!_open || _openFor < _inputLockout) return;
            Close();
            if (index == 0) Confirmed?.Invoke();
            else Cancelled?.Invoke();
        }
    }
}
