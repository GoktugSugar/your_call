using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The settings panel: a rounded hand-drawn ink frame over a faint paper fill, holding music
    /// volume, SFX volume, and a fullscreen toggle, plus a way back. It is the deliberate in-style
    /// exception to the no-menus rule, kept spare and drawn, not chrome. It seeds each control from
    /// the saved <see cref="GameSettings"/> and writes changes straight back, so the volumes drive
    /// the real audio and everything persists. Navigable by mouse (hover selects, click sets) and
    /// keyboard (up/down between rows, left/right adjust, enter toggles, escape closes). It composes
    /// the small controls and drives navigation and open/close; it does not know how any one control
    /// draws itself. One job: run the settings screen.
    /// </summary>
    public sealed class SettingsPanel : MonoBehaviour
    {
        private sealed class Row
        {
            public Action<bool> SetSelected;
            public Action<int> Adjust;
            public Action Activate;
            public Action<bool> Arm;
            public Action<float> SetShown;
        }

        [Header("Shared ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private TMP_FontAsset _font;

        [Header("Frame")]
        [SerializeField] private Vector3 _center = new Vector3(0f, -0.1f, 0f);
        [SerializeField] private Vector2 _size = new Vector2(9f, 6.2f);
        [SerializeField] private Color _borderColor = Palette.Ink;
        [SerializeField] private Color _fillColor = new Color(0.980f, 0.968f, 0.936f, 1f);
        [SerializeField] private float _borderWidth = 0.05f;
        [SerializeField] private float _cornerRadius = 0.4f;
        [SerializeField, Range(3, 16)] private int _cornerSegments = 8;
        [Tooltip("Sorts the whole panel above the menu as one group (a Sorting Group), so its own " +
                 "back-to-front order is set by the pieces below, not fought against the menu.")]
        [SerializeField] private int _groupSorting = 60;

        [Header("Heading")]
        [SerializeField] private string _headingText = "Settings";
        [SerializeField] private float _headingSize = 3.2f;
        [SerializeField] private Color _headingColor = Palette.Ink;
        [SerializeField] private float _headingY = 2.15f;

        [Header("Rows")]
        [SerializeField] private float _rowStartY = 0.85f;
        [SerializeField] private float _rowSpacing = 1.0f;
        [SerializeField] private float _closeGap = 0.55f;
        [Tooltip("Nudge the labelled rows so their content reads centred in the frame.")]
        [SerializeField] private float _contentOffsetX = 0.3f;

        [Header("Fade")]
        [SerializeField] private float _fadeDuration = 0.22f;
        [Tooltip("Ignore enter/escape for a moment after opening, so the click or key that opened the " +
                 "panel cannot immediately act inside it.")]
        [SerializeField] private float _openLockout = 0.18f;

        [Header("SFX preview (optional)")]
        [Tooltip("Played once at the chosen level when the SFX slider is released or nudged, so the " +
                 "level is audible. Leave empty for no preview.")]
        [SerializeField] private AudioClip _sfxPreviewClip;
        [SerializeField, Range(0f, 1f)] private float _sfxPreviewVolume = 0.8f;

        public event Action Closed;

        private SpriteRenderer _fill;
        private LineRenderer _border;
        private TextMeshPro _heading;
        private VolumeSlider _music;
        private VolumeSlider _sfx;
        private ToggleControl _fullscreen;
        private MenuItem _close;
        private AudioSource _previewSource;

        private readonly List<Row> _rows = new List<Row>();
        private int _selected;
        private float _alpha;
        private float _sinceOpen;
        private bool _open;
        private bool _built;
        private Coroutine _fade;

        private void Awake()
        {
            Build();
            SetShownAll(0f);
        }

        public bool IsOpen => _open;

        public void Open()
        {
            if (!_built) Build();
            _open = true;
            _sinceOpen = 0f;
            SelectRow(0);
            ArmRows(true);
            StartFade(1f);
        }

        public void Close()
        {
            if (!_open) return;
            _open = false;
            ArmRows(false);
            if (GameSettings.Instance != null) GameSettings.Instance.Save();
            StartFade(0f);
            Closed?.Invoke();
        }

        private void Update()
        {
            if (!_open) return;
            _sinceOpen += Time.deltaTime;
            ReadKeyboard();
        }

        private void ReadKeyboard()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null || _rows.Count == 0) return;

            if (kb.downArrowKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame) StepSelection(1);
            else if (kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame) StepSelection(-1);

            if (kb.rightArrowKey.wasPressedThisFrame || kb.dKey.wasPressedThisFrame) _rows[_selected].Adjust(1);
            else if (kb.leftArrowKey.wasPressedThisFrame || kb.aKey.wasPressedThisFrame) _rows[_selected].Adjust(-1);

            if (_sinceOpen < _openLockout) return;
            if (kb.escapeKey.wasPressedThisFrame) { Close(); return; }
            if (kb.enterKey.wasPressedThisFrame || kb.numpadEnterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame)
                _rows[_selected].Activate();
#endif
        }

        private void StepSelection(int dir)
        {
            if (_rows.Count == 0) return;
            SelectRow((_selected + dir + _rows.Count) % _rows.Count);
        }

        private void SelectRow(int index)
        {
            _selected = Mathf.Clamp(index, 0, _rows.Count - 1);
            for (int i = 0; i < _rows.Count; i++) _rows[i].SetSelected(_open && i == _selected);
        }

        private void ArmRows(bool on)
        {
            for (int i = 0; i < _rows.Count; i++) _rows[i].Arm(on);
        }

        // ---------- Build ----------

        private void Build()
        {
            if (_built) return;
            transform.position = _center;

            var group = gameObject.GetComponent<SortingGroup>();
            if (group == null) group = gameObject.AddComponent<SortingGroup>();
            group.sortingOrder = _groupSorting;

            _fill = MakeFill();
            _border = InkLine.Create(transform, "Border", _inkMaterial, _borderWidth, _borderColor, 2);
            InkLine.SetPoints(_border, RoundedRect(_size * 0.995f, _cornerRadius, _cornerSegments));

            _heading = InkText.Create(transform, "Heading", _headingSize, _headingColor, TextAlignmentOptions.Center, 6);
            if (_font != null) _heading.font = _font;
            _heading.text = _headingText;
            _heading.rectTransform.sizeDelta = new Vector2(_size.x, _headingSize * 1.4f);
            _heading.rectTransform.localPosition = new Vector3(0f, _headingY, 0f);

            BuildRows();
            BuildPreviewSource();
            _built = true;
        }

        private void BuildRows()
        {
            float y = _rowStartY;

            _music = MakeSlider("MusicRow", "Music", GameSettings.Instance != null ? GameSettings.Instance.MusicVolume : 1f, y);
            _music.Changed += v => { if (GameSettings.Instance != null) GameSettings.Instance.SetMusicVolume(v); };
            AddRow(_music.SetSelected, _music.Adjust, () => { }, _music.Arm, _music.SetShown);
            int musicIndex = _rows.Count - 1;
            _music.Hovered += () => SelectRow(musicIndex);
            y -= _rowSpacing;

            _sfx = MakeSlider("SfxRow", "Sound", GameSettings.Instance != null ? GameSettings.Instance.SfxVolume : 1f, y);
            _sfx.Changed += v => { if (GameSettings.Instance != null) GameSettings.Instance.SetSfxVolume(v); };
            _sfx.Committed += _ => PlaySfxPreview();
            AddRow(_sfx.SetSelected, _sfx.Adjust, () => { }, _sfx.Arm, _sfx.SetShown);
            int sfxIndex = _rows.Count - 1;
            _sfx.Hovered += () => SelectRow(sfxIndex);
            y -= _rowSpacing;

            _fullscreen = MakeToggle("FullscreenRow", "Fullscreen", GameSettings.Instance == null || GameSettings.Instance.Fullscreen, y);
            _fullscreen.Changed += on => { if (GameSettings.Instance != null) GameSettings.Instance.SetFullscreen(on); };
            AddRow(_fullscreen.SetSelected, _fullscreen.Adjust, _fullscreen.Toggle, _fullscreen.Arm, _fullscreen.SetShown);
            int fsIndex = _rows.Count - 1;
            _fullscreen.Hovered += () => SelectRow(fsIndex);
            y -= _rowSpacing + _closeGap;

            _close = MakeClose("CloseRow", "Close", y);
            _close.Clicked += _ => Close();
            AddRow(_close.SetSelected, _ => { }, Close, _close.Arm, _close.SetShown);
            int closeIndex = _rows.Count - 1;
            _close.Hovered += _ => SelectRow(closeIndex);
        }

        private void AddRow(Action<bool> setSelected, Action<int> adjust, Action activate, Action<bool> arm, Action<float> setShown)
        {
            _rows.Add(new Row { SetSelected = setSelected, Adjust = adjust, Activate = activate, Arm = arm, SetShown = setShown });
        }

        private VolumeSlider MakeSlider(string name, string label, float value, float y)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(_contentOffsetX, y, 0f);
            var s = go.AddComponent<VolumeSlider>();
            s.Setup(_inkMaterial, _font, label, value);
            return s;
        }

        private ToggleControl MakeToggle(string name, string label, bool on, float y)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(_contentOffsetX, y, 0f);
            var t = go.AddComponent<ToggleControl>();
            t.Setup(_inkMaterial, _font, label, on);
            return t;
        }

        private MenuItem MakeClose(string name, string label, float y)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(0f, y, 0f);
            var m = go.AddComponent<MenuItem>();
            m.Setup(_inkMaterial, _font, label, true);
            return m;
        }

        private void BuildPreviewSource()
        {
            if (_sfxPreviewClip == null) return;
            _previewSource = gameObject.AddComponent<AudioSource>();
            _previewSource.playOnAwake = false;
            _previewSource.spatialBlend = 0f;
        }

        private void PlaySfxPreview()
        {
            if (_previewSource == null || _sfxPreviewClip == null) return;
            _previewSource.PlayOneShot(_sfxPreviewClip, _sfxPreviewVolume * GameSettings.SfxScalar);
        }

        private SpriteRenderer MakeFill()
        {
            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            var px = new Color32[4];
            for (int i = 0; i < px.Length; i++) px[i] = new Color32(255, 255, 255, 255);
            tex.SetPixels32(px); tex.Apply();
            var spr = Sprite.Create(tex, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 2f);

            var go = new GameObject("Fill");
            go.transform.SetParent(transform, false);
            go.transform.localScale = new Vector3(_size.x * 0.98f, _size.y * 0.97f, 1f);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = spr;
            sr.sortingOrder = 0;
            return sr;
        }

        // ---------- Fade ----------

        private void StartFade(float target)
        {
            if (_fade != null) StopCoroutine(_fade);
            if (isActiveAndEnabled) _fade = StartCoroutine(FadeTo(target));
            else SetShownAll(target);
        }

        private IEnumerator FadeTo(float target)
        {
            float from = _alpha, t = 0f, d = Mathf.Max(_fadeDuration, 0.0001f);
            while (t < d)
            {
                t += Time.deltaTime;
                SetShownAll(Mathf.Lerp(from, target, EaseUtil.OutCubic(t / d)));
                yield return null;
            }
            SetShownAll(target);
            _fade = null;
        }

        private void SetShownAll(float a)
        {
            _alpha = Mathf.Clamp01(a);

            if (_fill != null)
            {
                var c = _fillColor; c.a = _fillColor.a * _alpha; _fill.color = c;
                _fill.enabled = _alpha > 0.001f;
            }
            if (_border != null)
            {
                InkLine.SetAlpha(_border, _borderColor, _alpha);
                _border.enabled = _alpha > 0.001f;
            }
            if (_heading != null) InkText.SetAlpha(_heading, _alpha);
            for (int i = 0; i < _rows.Count; i++) _rows[i].SetShown(_alpha);
        }

        private static List<Vector3> RoundedRect(Vector2 size, float r, int seg)
        {
            float hw = size.x * 0.5f, hh = size.y * 0.5f;
            r = Mathf.Max(0.01f, Mathf.Min(r, Mathf.Min(hw, hh)));
            var p = new List<Vector3>();
            Vector2 bl = new Vector2(-hw + r, -hh + r);
            Vector2 br = new Vector2(hw - r, -hh + r);
            Vector2 tr = new Vector2(hw - r, hh - r);
            Vector2 tl = new Vector2(-hw + r, hh - r);
            p.Add(new Vector3(-hw + r, -hh, 0f));
            p.Add(new Vector3(hw - r, -hh, 0f));
            InkLine.AddArc(p, br, r, -90f, 0f, seg);
            p.Add(new Vector3(hw, hh - r, 0f));
            InkLine.AddArc(p, tr, r, 0f, 90f, seg);
            p.Add(new Vector3(-hw + r, hh, 0f));
            InkLine.AddArc(p, tl, r, 90f, 180f, seg);
            p.Add(new Vector3(-hw, -hh + r, 0f));
            InkLine.AddArc(p, bl, r, 180f, 270f, seg);
            p.Add(new Vector3(-hw + r, -hh, 0f));
            return p;
        }
    }
}
