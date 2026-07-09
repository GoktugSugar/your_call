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
    /// The main menu's navigation: it builds the stacked lines from a small authored list, tracks
    /// the current selection, and drives it by both mouse (hover selects, click activates) and
    /// keyboard (up/down move, enter activates), consistent with the game's input. Disabled lines
    /// (Continue, until a save exists) are skipped by the keyboard and cannot be hovered. It owns
    /// only selection and dispatch; it raises <see cref="Activated"/> and lets the composition root
    /// decide what each action does, so it never reaches into scene loading or the settings panel.
    /// One job: choose a line.
    /// </summary>
    public sealed class MainMenuController : MonoBehaviour
    {
        [Serializable]
        private struct ItemSpec
        {
            public string label;
            public MenuAction action;
            [Tooltip("Whether this line is selectable at all. Continue is additionally gated on a save existing.")]
            public bool interactable;
        }

        [Header("Shared ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private TMP_FontAsset _font;

        [Header("Lines (top to bottom)")]
        [SerializeField]
        private ItemSpec[] _items =
        {
            new ItemSpec { label = "Continue", action = MenuAction.Continue, interactable = true },
            new ItemSpec { label = "New Game", action = MenuAction.NewGame, interactable = true },
            new ItemSpec { label = "Settings", action = MenuAction.Settings, interactable = true },
        };

        [Header("Layout")]
        [SerializeField] private Vector3 _origin = new Vector3(0f, 0.4f, 0f);
        [SerializeField] private float _spacing = 1.25f;

        [Header("Input")]
        [Tooltip("Ignore enter/click for this long after arming, so a click carried in from a prior " +
                 "screen can never activate a line instantly.")]
        [SerializeField] private float _inputLockout = 0.25f;

        public event Action<MenuAction> Activated;

        private readonly List<MenuItem> _built = new List<MenuItem>();
        private int _selected = -1;
        private bool _armed;
        private float _armedFor;

        private void Start()
        {
            BuildItems();
            SelectFirstInteractable();
            SetInteractable(true);
            Localization.LanguageChanged += Relocalize;
        }

        private void OnDestroy()
        {
            Localization.LanguageChanged -= Relocalize;
        }

        // Re-apply the line labels in the active language (fires when the language setting changes live).
        private void Relocalize()
        {
            for (int i = 0; i < _built.Count; i++) _built[i].Relocalize();
        }

        private void BuildItems()
        {
            for (int i = 0; i < _items.Length; i++)
            {
                var go = new GameObject("Item_" + _items[i].label);
                go.transform.SetParent(transform, false);
                go.transform.localPosition = _origin + new Vector3(0f, -_spacing * i, 0f);

                var item = go.AddComponent<MenuItem>();
                bool interactable = _items[i].interactable
                                    && (_items[i].action != MenuAction.Continue || SavePresent());
                item.Setup(_inkMaterial, _font, _items[i].label, interactable);

                int index = i;
                item.Hovered += _ => Select(index);
                item.Clicked += _ => Activate(index);
                _built.Add(item);
            }
        }

        // No save system yet, so Continue is disabled. When a save/resume system lands, this returns
        // whether a save exists and Continue enables itself with no other change here.
        private bool SavePresent() => false;

        public void SetInteractable(bool on)
        {
            _armed = on;
            _armedFor = 0f;
            for (int i = 0; i < _built.Count; i++) _built[i].Arm(on);
            RefreshSelection();
        }

        /// <summary>Show or hide the whole stack, so the settings screen can stand alone over it.</summary>
        public void SetShown(bool shown)
        {
            for (int i = 0; i < _built.Count; i++) _built[i].SetShown(shown ? 1f : 0f);
        }

        private void SelectFirstInteractable()
        {
            for (int i = 0; i < _built.Count; i++)
                if (_built[i].Interactable) { _selected = i; break; }
            RefreshSelection();
        }

        private void Update()
        {
            if (!_armed) return;
            _armedFor += Time.deltaTime;
            ReadKeyboard();
        }

        private void ReadKeyboard()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null) return;

            if (kb.downArrowKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame) Step(1);
            else if (kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame) Step(-1);

            if (_armedFor >= _inputLockout &&
                (kb.enterKey.wasPressedThisFrame || kb.numpadEnterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame))
                Activate(_selected);
#endif
        }

        // Move the selection by one, skipping disabled lines and wrapping around.
        private void Step(int dir)
        {
            if (_built.Count == 0) return;
            int i = _selected;
            for (int n = 0; n < _built.Count; n++)
            {
                i = (i + dir + _built.Count) % _built.Count;
                if (_built[i].Interactable) { Select(i); return; }
            }
        }

        private void Select(int index)
        {
            if (index < 0 || index >= _built.Count || !_built[index].Interactable) return;
            _selected = index;
            RefreshSelection();
        }

        private void RefreshSelection()
        {
            for (int i = 0; i < _built.Count; i++)
                _built[i].SetSelected(_armed && i == _selected);
        }

        private void Activate(int index)
        {
            if (!_armed || _armedFor < _inputLockout) return;
            if (index < 0 || index >= _built.Count || !_built[index].Interactable) return;
            Activated?.Invoke(_items[index].action);
        }
    }
}
