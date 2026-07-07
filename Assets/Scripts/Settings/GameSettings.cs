using System;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The player's saved settings, in one persistent place: music volume, SFX volume, and
    /// fullscreen. A guarded singleton (DontDestroyOnLoad) loaded from PlayerPrefs on boot and
    /// saved when changed, so choices stick between runs. It never touches audio sources
    /// directly; instead it exposes the values plus change events, and the audio components
    /// (MusicPlayer for music, ImpVoice and GunSfx for SFX) read them. Fullscreen it applies
    /// itself, since that is a window-level setting with no component to own it. One job: hold,
    /// persist, and broadcast the settings. Built to grow (add text speed and the like later).
    /// </summary>
    [DefaultExecutionOrder(-100)]
    public sealed class GameSettings : MonoBehaviour
    {
        public static GameSettings Instance { get; private set; }

        private const string MusicKey = "settings.musicVolume";
        private const string SfxKey = "settings.sfxVolume";
        private const string FullscreenKey = "settings.fullscreen";

        [Header("Defaults (used the first run, before anything is saved)")]
        [Tooltip("A scalar over the game's own mix level, not the raw source volume: 1 is the " +
                 "designed level, lower attenuates from there.")]
        [SerializeField, Range(0f, 1f)] private float _defaultMusicVolume = 1f;
        [SerializeField, Range(0f, 1f)] private float _defaultSfxVolume = 1f;
        [SerializeField] private bool _defaultFullscreen = true;

        [Header("Behaviour")]
        [Tooltip("Apply the saved fullscreen state to the window on boot. Handy to leave off while " +
                 "working in the editor.")]
        [SerializeField] private bool _applyFullscreenOnBoot = true;
        [SerializeField] private bool _persistAcrossScenes = true;

        public float MusicVolume { get; private set; }
        public float SfxVolume { get; private set; }
        public bool Fullscreen { get; private set; }

        public event Action<float> MusicVolumeChanged;
        public event Action<float> SfxVolumeChanged;
        public event Action<bool> FullscreenChanged;

        /// <summary>SFX scale to apply right now; full when there is no settings object in the scene.</summary>
        public static float SfxScalar => Instance != null ? Instance.SfxVolume : 1f;

        /// <summary>Music scale to apply right now; full when there is no settings object in the scene.</summary>
        public static float MusicScalar => Instance != null ? Instance.MusicVolume : 1f;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            if (_persistAcrossScenes) DontDestroyOnLoad(gameObject);

            Load();
            if (_applyFullscreenOnBoot) ApplyFullscreen();
        }

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        private void Load()
        {
            MusicVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(MusicKey, _defaultMusicVolume));
            SfxVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(SfxKey, _defaultSfxVolume));
            Fullscreen = PlayerPrefs.GetInt(FullscreenKey, _defaultFullscreen ? 1 : 0) != 0;
        }

        public void SetMusicVolume(float v)
        {
            v = Mathf.Clamp01(v);
            if (v == MusicVolume) return;
            MusicVolume = v;
            PlayerPrefs.SetFloat(MusicKey, v);
            MusicVolumeChanged?.Invoke(v);
        }

        public void SetSfxVolume(float v)
        {
            v = Mathf.Clamp01(v);
            if (v == SfxVolume) return;
            SfxVolume = v;
            PlayerPrefs.SetFloat(SfxKey, v);
            SfxVolumeChanged?.Invoke(v);
        }

        public void SetFullscreen(bool on)
        {
            if (on == Fullscreen) return;
            Fullscreen = on;
            PlayerPrefs.SetInt(FullscreenKey, on ? 1 : 0);
            ApplyFullscreen();
            FullscreenChanged?.Invoke(on);
        }

        /// <summary>Flush prefs to disk. Called when the settings panel closes, and on quit, so a
        /// continuous drag does not write to disk every frame.</summary>
        public void Save() => PlayerPrefs.Save();

        private void OnApplicationQuit() => PlayerPrefs.Save();

        private void ApplyFullscreen()
        {
            Screen.fullScreen = Fullscreen;
        }
    }
}
