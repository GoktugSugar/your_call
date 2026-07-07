using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// The main menu screen, composed: it draws the hand-lettered title, hands navigation to the
    /// <see cref="MainMenuController"/>, and turns a chosen line into an action, New Game loads the
    /// opening sequence and Settings opens the in-style panel (Continue is disabled and never
    /// fires). While the settings panel is open it parks the menu's input so the two never fight.
    /// The imp idles here too, since it is the face of the game, revealed on entry and left to its
    /// own life. It reaches into scene loading and the panel; the small parts stay decoupled and
    /// event-driven. One job: run the menu screen.
    /// </summary>
    public sealed class MainMenu : MonoBehaviour
    {
        [Header("Wiring")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private TMP_FontAsset _font;
        [SerializeField] private MainMenuController _controller;
        [SerializeField] private SettingsPanel _settings;
        [Tooltip("Optional: the imp on the menu. Left empty simply omits it.")]
        [SerializeField] private ImpFigure _imp;
        [Tooltip("Optional: a keep-out region over the settings panel, switched on only while the " +
                 "panel is open so the roaming imp gives it room. Left empty simply skips it.")]
        [SerializeField] private GameObject _settingsKeepout;

        [Header("New Game")]
        [Tooltip("The scene New Game loads: the authored opening sequence.")]
        [SerializeField] private string _newGameScene = "Opening";

        [Header("Title")]
        [SerializeField] private string _title = "Your Call";
        [SerializeField] private float _titleSize = 6.2f;
        [SerializeField] private Color _titleColor = Palette.Ink;
        [SerializeField] private Vector3 _titlePosition = new Vector3(0f, 2.75f, 0f);
        [SerializeField] private int _titleSorting = 30;
        [Tooltip("A hand-drawn ink flourish under the title. Ink, not amber, so it reads as line, not accent.")]
        [SerializeField] private bool _titleUnderline = true;
        [SerializeField] private float _titleUnderlineWidth = 0.07f;
        [SerializeField] private float _titleUnderlineSpan = 4.6f;
        [SerializeField] private float _titleUnderlineDrop = 1.15f;
        [SerializeField] private float _titleUnderlineWobble = 0.06f;

        private TextMeshPro _titleText;
        private LineRenderer _titleLine;

        private void Start()
        {
            BuildTitle();

            if (_controller != null) _controller.Activated += OnActivated;
            if (_settings != null) _settings.Closed += OnSettingsClosed;

            // No pop-in entrance on the menu: the imp is simply present with its idle life.
            if (_imp != null) _imp.SetAlpha(1f);
        }

        private void OnDestroy()
        {
            if (_controller != null) _controller.Activated -= OnActivated;
            if (_settings != null) _settings.Closed -= OnSettingsClosed;
        }

        private void BuildTitle()
        {
            _titleText = InkText.Create(transform, "Title", _titleSize, _titleColor, TextAlignmentOptions.Center, _titleSorting);
            if (_font != null) _titleText.font = _font;
            _titleText.text = _title;
            _titleText.rectTransform.sizeDelta = new Vector2(20f, _titleSize * 1.5f);
            _titleText.rectTransform.position = _titlePosition;

            if (_titleUnderline && _inkMaterial != null)
            {
                _titleLine = InkLine.Create(transform, "TitleUnderline", _inkMaterial, _titleUnderlineWidth, _titleColor, _titleSorting - 1);
                var pts = new List<Vector3>();
                const int seg = 14;
                float half = _titleUnderlineSpan * 0.5f;
                float baseY = _titlePosition.y - _titleUnderlineDrop;
                for (int i = 0; i <= seg; i++)
                {
                    float f = (float)i / seg;
                    float x = _titlePosition.x + Mathf.Lerp(-half, half, f);
                    // A gentle rise into the middle plus a small wobble, so it reads as a drawn flourish.
                    float y = baseY + Mathf.Sin(f * Mathf.PI) * 0.06f + Mathf.Sin(f * Mathf.PI * 3f + 0.5f) * _titleUnderlineWobble;
                    pts.Add(new Vector3(x, y, 0f));
                }
                InkLine.SetPoints(_titleLine, pts);
            }
        }

        // Hide the title (and the controller hides its lines) so the settings screen stands alone.
        private void SetMenuShown(bool shown)
        {
            if (_titleText != null) InkText.SetAlpha(_titleText, shown ? 1f : 0f);
            if (_titleLine != null) InkLine.SetAlpha(_titleLine, _titleColor, shown ? 1f : 0f);
            if (_controller != null) _controller.SetShown(shown);
        }

        private void OnActivated(MenuAction action)
        {
            switch (action)
            {
                case MenuAction.NewGame:
                    SceneManager.LoadScene(_newGameScene);
                    break;
                case MenuAction.Settings:
                    OpenSettings();
                    break;
                case MenuAction.Continue:
                    // Disabled until a save/resume system exists; never reaches here for now.
                    break;
            }
        }

        private void OpenSettings()
        {
            if (_settings == null) return;
            if (_controller != null) _controller.SetInteractable(false);
            SetMenuShown(false);
            if (_settingsKeepout != null) _settingsKeepout.SetActive(true);
            _settings.Open();
        }

        private void OnSettingsClosed()
        {
            SetMenuShown(true);
            if (_settingsKeepout != null) _settingsKeepout.SetActive(false);
            if (_controller != null) _controller.SetInteractable(true);
        }
    }
}
