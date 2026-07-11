using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The in-chapter pause screen (Esc): Resume, Save, and Quit to Menu, in the game's ink-on-paper style
    /// (a paper scrim over the frozen scene, ink lines with an amber current selection, like the main menu).
    /// It is the home for the manual save and the only in-game route back to the menu; auto-save and Continue
    /// work without it. Built at runtime by <see cref="SequencePlayer"/> (no per-scene wiring), one per
    /// chapter.
    ///
    /// While open it FREEZES the beat two ways so nothing advances underneath: <c>Time.timeScale = 0</c> stops
    /// every coroutine wait and time-based motion, and <see cref="PointerInput.Suppressed"/> blanks the game's
    /// shared input. It therefore reads its OWN input straight off the devices (bypassing that suppression),
    /// and always restores the time scale and the suppression flag when it closes (and defensively on disable),
    /// so the game can never be left frozen. One job: the pause screen.
    /// </summary>
    public sealed class PauseOverlay : MonoBehaviour
    {
        private enum PauseAction { Resume, Save, Quit }

        [Tooltip("The scene Quit to Menu returns to.")]
        [SerializeField] private string _menuScene = "MainMenu";

        [Header("Look (built at runtime; ink on paper, like the menu)")]
        [SerializeField] private Color _scrim = new Color(Palette.Paper.r, Palette.Paper.g, Palette.Paper.b, 0.92f);
        [SerializeField] private float _titleSize = 3.8f;
        [SerializeField] private float _lineSize = 2.9f;
        [SerializeField] private float _titleY = 2.2f;
        [SerializeField] private float _firstLineY = 0.5f;
        [SerializeField] private float _lineSpacing = 1.2f;
        [SerializeField] private float _pickWidth = 6f;
        [SerializeField] private int _sorting = 90;

        [Header("Feel")]
        [Tooltip("Ignore enter/click for this long after opening, so the click/key that opened the pause never activates a line.")]
        [SerializeField] private float _openLockout = 0.18f;
        [Tooltip("How long the small 'Saved' confirmation lingers after a manual save.")]
        [SerializeField] private float _savedHold = 1.3f;

        [Header("Copy (localized; no dashes)")]
        [SerializeField] private string _titleText = "Paused";
        [SerializeField] private string _resumeText = "Resume";
        [SerializeField] private string _saveText = "Save";
        [SerializeField] private string _quitText = "Quit to Menu";
        [SerializeField] private string _savedText = "Saved";

        private sealed class Line
        {
            public TextMeshPro Text;
            public PauseAction Action;
            public Vector3 Local;
            public bool Enabled = true;
        }

        private SequencePlayer _player;
        private Camera _cam;
        private TMP_FontAsset _font;

        private GameObject _root;
        private SpriteRenderer _scrimRenderer;
        private TextMeshPro _title;
        private TextMeshPro _saved;
        private readonly List<Line> _lines = new List<Line>();
        private bool _built;
        private bool _open;
        private bool _frozeByUs;
        private int _selected;
        private int _hover = -1;
        private float _openFor;
        private float _savedFor = -1f;

        /// <summary>Wire the overlay to its chapter. Called once by <see cref="SequencePlayer"/>.</summary>
        public void Init(SequencePlayer player, Camera cam, TMP_FontAsset font)
        {
            _player = player;
            _cam = cam != null ? cam : Camera.main;
            _font = font;
        }

        private void Update()
        {
#if ENABLE_INPUT_SYSTEM
            if (!_open)
            {
                if (_player != null && KeyDown(Key.Escape)) Open();
                return;
            }

            _openFor += Time.unscaledDeltaTime;
            TickSavedFlash();

            if (KeyDown(Key.Escape)) { Resume(); return; }
            if (KeyDown(Key.DownArrow) || KeyDown(Key.S)) Step(1);
            else if (KeyDown(Key.UpArrow) || KeyDown(Key.W)) Step(-1);

            UpdateHover();

            bool armed = _openFor >= _openLockout;
            if (armed && (KeyDown(Key.Enter) || KeyDown(Key.NumpadEnter) || KeyDown(Key.Space)))
                Activate(_selected);
            else if (armed && MouseClicked() && _hover >= 0 && _lines[_hover].Enabled)
                Activate(_hover);
#endif
        }

        // ---------- open / close ----------

        private void Open()
        {
            BuildVisuals();
            PositionAtCamera();
            RefreshLines();
            SelectFirstEnabled();
            _open = true;
            _openFor = 0f;
            _root.SetActive(true);
            Freeze();
        }

        private void Resume()
        {
            _open = false;
            if (_root != null) _root.SetActive(false);
            Unfreeze();
        }

        private void Activate(int index)
        {
            if (index < 0 || index >= _lines.Count || !_lines[index].Enabled) return;
            switch (_lines[index].Action)
            {
                case PauseAction.Resume: Resume(); break;
                case PauseAction.Save: DoSave(); break;
                case PauseAction.Quit: QuitToMenu(); break;
            }
        }

        private void DoSave()
        {
            bool ok = _player != null && _player.SaveNow();
            if (ok) ShowSaved();
        }

        private void QuitToMenu()
        {
            if (_player != null) _player.SaveNow();                 // best-effort: keep the latest progress
            if (SaveService.Instance != null) SaveService.Instance.SetRealRun(false);
            Unfreeze();
            _open = false;
            SceneManager.LoadScene(_menuScene);
        }

        // ---------- freeze ----------

        private void Freeze()
        {
            Time.timeScale = 0f;
            PointerInput.Suppressed = true;
            _frozeByUs = true;
        }

        private void Unfreeze()
        {
            if (!_frozeByUs) return;
            Time.timeScale = 1f;
            PointerInput.Suppressed = false;
            _frozeByUs = false;
        }

        // Never leave the game frozen or input-suppressed if this object is disabled/destroyed while open.
        private void OnDisable() { Unfreeze(); }

        // ---------- navigation ----------

        private void Step(int dir)
        {
            if (_lines.Count == 0) return;
            int i = _selected;
            for (int n = 0; n < _lines.Count; n++)
            {
                i = (i + dir + _lines.Count) % _lines.Count;
                if (_lines[i].Enabled) { _selected = i; ApplyColors(); return; }
            }
        }

        private void SelectFirstEnabled()
        {
            for (int i = 0; i < _lines.Count; i++)
                if (_lines[i].Enabled) { _selected = i; break; }
            ApplyColors();
        }

        private void UpdateHover()
        {
            _hover = -1;
#if ENABLE_INPUT_SYSTEM
            Vector3 w = MouseWorld();
            float h = _lineSpacing * 0.85f;
            for (int i = 0; i < _lines.Count; i++)
            {
                if (!_lines[i].Enabled) continue;
                Vector3 c = _root.transform.position + _lines[i].Local;
                if (Mathf.Abs(w.x - c.x) <= _pickWidth * 0.5f && Mathf.Abs(w.y - c.y) <= h * 0.5f)
                {
                    _hover = i;
                    if (_selected != i) { _selected = i; ApplyColors(); }
                    break;
                }
            }
#endif
        }

        // ---------- visuals ----------

        private void BuildVisuals()
        {
            if (_built) return;

            _root = new GameObject("PauseVisuals");
            _root.transform.SetParent(transform, false);

            _scrimRenderer = BuildScrim(_root.transform);
            _title = MakeText(_titleText, _titleSize, Palette.Ink, new Vector3(0f, _titleY, 0f));

            AddLine(_resumeText, PauseAction.Resume, 0);
            AddLine(_saveText, PauseAction.Save, 1);
            AddLine(_quitText, PauseAction.Quit, 2);

            float savedY = _firstLineY - _lineSpacing * _lines.Count - 0.35f;
            _saved = MakeText(_savedText, _lineSize * 0.85f, Palette.Amber, new Vector3(0f, savedY, 0f));
            _saved.gameObject.SetActive(false);

            _built = true;
        }

        private void AddLine(string label, PauseAction action, int row)
        {
            var local = new Vector3(0f, _firstLineY - _lineSpacing * row, 0f);
            var t = MakeText(label, _lineSize, Palette.Ink, local);
            _lines.Add(new Line { Text = t, Action = action, Local = local });
        }

        private TextMeshPro MakeText(string source, float size, Color color, Vector3 local)
        {
            var t = InkText.Create(_root.transform, "Pause_" + source, size, color, TextAlignmentOptions.Center, _sorting + 1);
            if (_font != null) t.font = _font;
            t.rectTransform.sizeDelta = new Vector2(16f, size * 1.4f);
            t.transform.localPosition = local;
            t.text = Localization.Localize(source);
            return t;
        }

        private SpriteRenderer BuildScrim(Transform parent)
        {
            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            var px = new Color32[4];
            for (int i = 0; i < px.Length; i++) px[i] = new Color32(255, 255, 255, 255);
            tex.SetPixels32(px); tex.Apply();
            var spr = Sprite.Create(tex, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 2f);

            var go = new GameObject("Scrim");
            go.transform.SetParent(parent, false);
            go.transform.localScale = new Vector3(80f, 50f, 1f);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = spr;
            sr.color = _scrim;
            sr.sortingOrder = _sorting;
            return sr;
        }

        // Re-localize the labels, decide which lines are enabled (Save only during a real run), and colour them.
        private void RefreshLines()
        {
            if (_title != null) _title.text = Localization.Localize(_titleText);
            for (int i = 0; i < _lines.Count; i++)
            {
                _lines[i].Text.text = Localization.Localize(LabelFor(_lines[i].Action));
                _lines[i].Enabled = _lines[i].Action != PauseAction.Save || SaveAllowed();
            }
            if (_saved != null) _saved.text = Localization.Localize(_savedText);
            ApplyColors();
        }

        private string LabelFor(PauseAction a)
        {
            switch (a)
            {
                case PauseAction.Resume: return _resumeText;
                case PauseAction.Save: return _saveText;
                default: return _quitText;
            }
        }

        private void ApplyColors()
        {
            for (int i = 0; i < _lines.Count; i++)
            {
                Color c = !_lines[i].Enabled ? Palette.Muted : (i == _selected ? Palette.Amber : Palette.Ink);
                _lines[i].Text.color = c;
            }
        }

        private bool SaveAllowed() => _player != null && _player.CanSave;

        private void PositionAtCamera()
        {
            if (_cam == null) _cam = Camera.main;
            Vector3 p = _cam != null ? _cam.transform.position : Vector3.zero;
            _root.transform.position = new Vector3(p.x, p.y, 0f);
        }

        private void ShowSaved()
        {
            if (_saved == null) return;
            _saved.gameObject.SetActive(true);
            InkText.SetAlpha(_saved, 1f);
            _savedFor = 0f;
        }

        private void TickSavedFlash()
        {
            if (_savedFor < 0f || _saved == null) return;
            _savedFor += Time.unscaledDeltaTime;
            float a = Mathf.Clamp01(1f - _savedFor / Mathf.Max(0.01f, _savedHold));
            InkText.SetAlpha(_saved, a);
            if (a <= 0f) { _saved.gameObject.SetActive(false); _savedFor = -1f; }
        }

        // ---------- direct device reads (bypass PointerInput.Suppressed, which is on while paused) ----------

#if ENABLE_INPUT_SYSTEM
        private static bool KeyDown(Key k)
        {
            var kb = Keyboard.current;
            return kb != null && kb[k].wasPressedThisFrame;
        }

        private static bool MouseClicked()
        {
            var m = Mouse.current;
            return m != null && m.leftButton.wasPressedThisFrame;
        }

        private Vector3 MouseWorld()
        {
            var m = Mouse.current;
            if (m == null || _cam == null) return new Vector3(99999f, 99999f, 0f);
            Vector2 s = m.position.ReadValue();
            float dist = Mathf.Abs(_cam.transform.position.z);
            return _cam.ScreenToWorldPoint(new Vector3(s.x, s.y, dist));
        }
#endif
    }
}
