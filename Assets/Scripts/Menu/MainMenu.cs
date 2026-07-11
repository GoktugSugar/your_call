using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// The main menu screen, composed: it draws the hand-lettered title, hands navigation to the
    /// <see cref="MainMenuController"/>, and turns a chosen line into an action, New Game starts a fresh
    /// run (confirming first if a save exists, since it overwrites), Continue resumes the single save at
    /// the exact beat, and Settings opens the in-style panel. While the settings panel or the New Game
    /// confirm is open it parks the menu's input so the two never fight.
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
        [Tooltip("Duration of the imp's pop-in entrance when the menu loads.")]
        [SerializeField] private float _impPopDuration = 0.6f;
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
        private NewGameConfirm _confirm;

        private void Start()
        {
            BuildTitle();
            BuildConfirm();

            if (_controller != null) _controller.Activated += OnActivated;
            if (_settings != null) _settings.Closed += OnSettingsClosed;
            Localization.LanguageChanged += RelocalizeTitle;

            // The imp plays its pop-in entrance on load, the same scale/bounce appearance it uses elsewhere.
            if (_imp != null) StartCoroutine(_imp.PopIn(_impPopDuration));
        }

        private void OnDestroy()
        {
            if (_controller != null) _controller.Activated -= OnActivated;
            if (_settings != null) _settings.Closed -= OnSettingsClosed;
            Localization.LanguageChanged -= RelocalizeTitle;
        }

        private void RelocalizeTitle()
        {
            if (_titleText != null) _titleText.text = Localization.Localize(_title);
            if (_confirm != null) _confirm.Relocalize();
        }

        // The New Game confirmation, built at runtime and kept hidden until New Game would erase a save.
        private void BuildConfirm()
        {
            var go = new GameObject("NewGameConfirm");
            go.transform.SetParent(transform, false);
            _confirm = go.AddComponent<NewGameConfirm>();
            _confirm.Setup(_inkMaterial, _font);
            _confirm.Confirmed += OnConfirmNewGame;
            _confirm.Cancelled += OnCancelNewGame;
        }

        private void BuildTitle()
        {
            _titleText = InkText.Create(transform, "Title", _titleSize, _titleColor, TextAlignmentOptions.Center, _titleSorting);
            if (_font != null) _titleText.font = _font;
            _titleText.text = Localization.Localize(_title);
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
                    TryNewGame();
                    break;
                case MenuAction.Settings:
                    OpenSettings();
                    break;
                case MenuAction.Continue:
                    StartContinue();
                    break;
            }
        }

        // New Game replaces the single save. If a run is already in progress, confirm first (it will be
        // erased); otherwise start fresh straight away.
        private void TryNewGame()
        {
            var s = SaveService.Instance;
            if (s != null && s.HasSave) OpenConfirm();
            else StartNewGame();
        }

        private void OpenConfirm()
        {
            if (_confirm == null) { StartNewGame(); return; }
            if (_controller != null) _controller.SetInteractable(false);
            SetMenuShown(false);
            _confirm.Open();
        }

        private void OnConfirmNewGame() => StartNewGame();

        private void OnCancelNewGame()
        {
            SetMenuShown(true);
            if (_controller != null) _controller.SetInteractable(true);
        }

        // Begin a fresh run: replace the save, clear any carried-over profile (the Profile is persistent, so a
        // previous run's tally would otherwise bleed in), mark the run real (so it auto-saves), and load the
        // opening. The fresh run's first auto-save (on entering beat 0) writes the new save.
        private void StartNewGame()
        {
            var s = SaveService.Instance != null ? SaveService.Instance : SaveService.Ensure();
            if (s != null) { s.Delete(); s.SetRealRun(true); }
            if (Profile.Instance != null) Profile.Instance.ResetState();
            SceneManager.LoadScene(_newGameScene);
        }

        // Resume the saved run at the exact beat: hand the loaded save to the chapter's SequencePlayer (which
        // restores the profile and money before playing) and the beat index it should enter at, then load the
        // saved chapter. The same partway-entry path the dev picker uses.
        private void StartContinue()
        {
            var s = SaveService.Instance != null ? SaveService.Instance : SaveService.Ensure();
            if (s == null || !s.TryLoad(out var data)) return;   // no valid save (Continue would be disabled)
            SaveService.PendingResume = data;
            SequencePlayer.PendingStartBeat = data.beatIndex;
            s.SetRealRun(true);
            SceneManager.LoadScene(data.chapterScene);
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
